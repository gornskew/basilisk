#!/bin/bash
# Copyright © 2026 Gornskew Enterprises
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.  Distributed WITHOUT
# ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.
#
# cloud-stack/setup.sh -- raising a ship in a cloud session's vat.
#
# The setup script of a Claude Code cloud environment whose repository
# is this yard (github.com/gornskew/basilisk).  The session's virtual
# machine runs it as root, before the cyborg is seated, and keeps the
# filesystem it leaves behind (residences pulled, papers written) for
# the sessions that follow -- about a week -- so the pulls happen once.
# Running processes are not kept: cloud-stack/session-start.sh, wired
# through .claude/settings.json, raises the ship again at every seating.
#
# Environment (set on the cloud environment, all optional):
#   DOCKERHUB_USER, DOCKERHUB_TOKEN  the Guild's papers: with both, the
#                                    Guild's cyborg unit comes aboard
#                                    (its residence is a private catalog)
#   EMACS_IMAGE_VARIANT              the ready room's strain (default lite)
#   PROJECTS_DIR                     the scroll chest to requisition
#                                    (default ~/projects, created)
#   TZ                               ship's time

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"
EMACS_IMAGE_VARIANT="${EMACS_IMAGE_VARIANT:-lite}"
export PROJECTS_DIR EMACS_IMAGE_VARIANT

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
docker info >/dev/null 2>&1 || { log "no docker daemon; nothing can be raised" >&2; exit 1; }

# The Guild's papers: with them, the overlay is installed and the
# cyborg unit pulled; without them the base rig flies alone.
if [ -n "${DOCKERHUB_USER:-}" ] && [ -n "${DOCKERHUB_TOKEN:-}" ]; then
    log "Guild papers found: logging in to Docker Hub as $DOCKERHUB_USER"
    printf '%s' "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USER" --password-stdin
    BASILISK_DIR="$REPO_DIR" "$REPO_DIR/cloud-stack/install"
else
    log "no DOCKERHUB_USER/DOCKERHUB_TOKEN: the base rig only, no Guild unit"
    rm -f "$REPO_DIR/cloud-stack-compose.yml"
fi

# The mark session-start.sh looks for: this clone lives in a cloud vat.
touch "$REPO_DIR/cloud-stack/.cloud-vat"

cd "$REPO_DIR"
log "raising the ship (ready room strain: $EMACS_IMAGE_VARIANT)"
./basilisk up "--$EMACS_IMAGE_VARIANT"

# The cyborg scrolls: the yard's launchers, project-scoped for the
# session's Claude Code (.mcp.json beside the repo root) and spliced
# into the user scroll as well.
cp mcp/claude-code-mcp.json .mcp.json
mcp/install-claude-code-config || log "user scroll not spliced (the .mcp.json beside the repo carries the rooms)"

./basilisk status || true
log "done: the rooms answer as MCP servers ready-room, bridge, engine-room and, with the Guild aboard, guild-workshop"
