#!/bin/sh
# Copyright © 2026 Gornskew Enterprises
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.  Distributed WITHOUT
# ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.
#
# cloud-stack/session-start.sh -- every seating in a cloud vat raises
# the ship again.
#
# Wired as a SessionStart hook in .claude/settings.json.  A cloud
# session keeps the vat's filesystem between seatings but not its
# running processes, so the residences are already pulled and the
# ship must simply be raised again.  Ashore -- any clone that
# cloud-stack/setup.sh never ran in -- there is no mark, and this is
# a no-op.  The raise runs in the background: the yard's MCP launcher
# (mcp/mcp-exec) waits for the rooms on its own.

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
[ -f "$REPO_DIR/cloud-stack/.cloud-vat" ] || exit 0

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"
EMACS_IMAGE_VARIANT="${EMACS_IMAGE_VARIANT:-lite}"
# The catalog branch, pinned as in setup.sh: the session's own branch
# names no image.
CURRENT_BRANCH="${CURRENT_BRANCH:-devo}"
export PROJECTS_DIR EMACS_IMAGE_VARIANT CURRENT_BRANCH

if ! docker info >/dev/null 2>&1; then
    nohup dockerd >/var/log/dockerd.log 2>&1 &
fi

(
    cd "$REPO_DIR" || exit 0
    for _ in $(seq 1 60); do
        docker info >/dev/null 2>&1 && break
        sleep 1
    done
    nohup ./basilisk up "--$EMACS_IMAGE_VARIANT" >/tmp/basilisk-session-start.log 2>&1 &
)
exit 0
