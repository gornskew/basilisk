#!/bin/bash
# Copyright © 2026 Gornskew Enterprises
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.  Distributed WITHOUT
# ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.
#
# cloud-stack/setup.sh -- fitting out a cloud session's vat.
#
# The setup script of a Claude Code cloud environment whose repository
# is this yard (github.com/gornskew/basilisk).  The session's virtual
# machine runs it as root, before the cyborg is seated, and keeps the
# filesystem it leaves behind for the sessions that follow (about a
# week: the environment cache) -- but only if the script EXITS ZERO
# WITHIN ABOUT FIVE MINUTES.  So this script never raises the ship: it
# starts the vat, presents the Guild's papers, installs the overlay,
# pulls what residences it can in the time it has (whatever arrived is
# cached; the rest arrives at the first raise), and writes the cyborg
# scrolls.  The raise itself is cloud-stack/session-start.sh's, wired
# as a SessionStart hook in .claude/settings.json, in the background
# at every seating; the yard's launcher (mcp/mcp-exec) waits for the
# rooms on its own.
#
# Environment (set on the cloud environment, all optional):
#   DOCKERHUB_USER, DOCKERHUB_TOKEN  the Guild's papers: with both, the
#                                    Guild's cyborg unit comes aboard
#                                    (its residence is a private catalog)
#   EMACS_IMAGE_VARIANT              the ready room's strain (default lite)
#   PROJECTS_DIR                     the scroll chest to requisition
#                                    (default ~/projects, created)
#   TZ                               ship's time

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"
EMACS_IMAGE_VARIANT="${EMACS_IMAGE_VARIANT:-lite}"
PULL_SECONDS="${PULL_SECONDS:-240}"
# The catalog branch the residences are tagged with.  generate-env.sh
# takes it from the checkout's git branch, which ashore is the yard's
# own; in a cloud vat the session works on a branch named for the
# session (claude/<something>), which names no image and is not even
# a legal tag.  Pinned to the yard's line unless the environment says.
CURRENT_BRANCH="${CURRENT_BRANCH:-devo}"
export PROJECTS_DIR EMACS_IMAGE_VARIANT CURRENT_BRANCH

log() { printf '[cloud-stack] %s\n' "$*"; }

# The scroll chest, with the state shelf writable by every uid the
# rooms run as (the same 1777 convention as /tmp).
mkdir -p "$PROJECTS_DIR/.state"
chmod 1777 "$PROJECTS_DIR/.state"
# Every overlay expects the yard at /projects/basilisk aboard.
if [ ! -e "$PROJECTS_DIR/basilisk" ]; then
    ln -s "$REPO_DIR" "$PROJECTS_DIR/basilisk"
fi

# The vat: a docker daemon, started here when the machine has not.
if ! docker info >/dev/null 2>&1; then
    log "starting dockerd"
    nohup dockerd >/var/log/dockerd.log 2>&1 &
    for _ in $(seq 1 60); do
        docker info >/dev/null 2>&1 && break
        sleep 1
    done
fi
if ! docker info >/dev/null 2>&1; then
    log "no docker daemon; the session opens with nothing to raise" >&2
    exit 0
fi

# The Guild's papers: with them, the overlay is installed and the
# cyborg unit's residence pulled; without them the base rig flies alone.
GUILD=""
if [ -n "${DOCKERHUB_USER:-}" ] && [ -n "${DOCKERHUB_TOKEN:-}" ]; then
    log "Guild papers found: logging in to Docker Hub as $DOCKERHUB_USER"
    if printf '%s' "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USER" --password-stdin; then
        BASILISK_DIR="$REPO_DIR" "$REPO_DIR/cloud-stack/install" && GUILD=1
    else
        log "Docker Hub refused the papers; the base rig only"
    fi
else
    log "no DOCKERHUB_USER/DOCKERHUB_TOKEN: the base rig only, no Guild unit"
fi
[ -n "$GUILD" ] || rm -f "$REPO_DIR/cloud-stack-compose.yml"

# The vat's kernel has no IPv6: the ship's network goes IPv4-only
# (see the file's own header).  Papers or no papers.
cp "$REPO_DIR/cloud-stack/cloud-ipv4-overlay.yml" "$REPO_DIR/cloud-ipv4-overlay.yml"

cd "$REPO_DIR" || exit 0

# The yard's own papers (.env), then the residences, for as long as
# the five minutes allow.  A pull cut short is not a failure: what
# arrived is cached, the first raise fetches the rest.
./basilisk init "--$EMACS_IMAGE_VARIANT" >/tmp/basilisk-init.log 2>&1 \
    || log "init did not finish cleanly (see /tmp/basilisk-init.log); the raise will retry"
log "pulling residences for up to ${PULL_SECONDS}s"
timeout "$PULL_SECONDS" ./basilisk pull "--$EMACS_IMAGE_VARIANT" >/tmp/basilisk-pull.log 2>&1 \
    || log "pull stopped early (see /tmp/basilisk-pull.log); the raise fetches the rest"
docker image ls --format '  {{.Repository}}:{{.Tag}} {{.Size}}' 2>/dev/null | sed 's/^/[cloud-stack] aboard:/'

# The cyborg scrolls, written here rather than by a raise: every room
# through the yard's launcher, which execs into the ready room and
# raises the ship on demand.  Project-scoped beside the repo root
# (.mcp.json) for the session's Claude Code, and spliced into the
# user scroll as well.
room() {
    printf '    "%s": {"command": "%s/mcp/mcp-exec", "args": ["--server-name", "%s", "--backend-host", "%s", "--http-port", "%s", "--request-timeout-ms", "30000"]}' \
        "$1" "$REPO_DIR" "$1" "$1" "$2"
}
{
    printf '{\n  "mcpServers": {\n'
    room ready-room 7080; printf ',\n'
    room bridge 9080; printf ',\n'
    room engine-room 9090
    [ -n "$GUILD" ] && { printf ',\n'; room guild-workshop 9098; }
    printf '\n  }\n}\n'
} > mcp/claude-code-mcp.json
cp mcp/claude-code-mcp.json .mcp.json
mcp/install-claude-code-config >/dev/null 2>&1 \
    || log "user scroll not spliced (the .mcp.json beside the repo carries the rooms)"

# The mark session-start.sh looks for: this clone lives in a cloud vat.
touch "$REPO_DIR/cloud-stack/.cloud-vat"

log "fitted out: the rooms answer as MCP servers ready-room, bridge, engine-room${GUILD:+, guild-workshop}; the raise runs at the seating"
exit 0
