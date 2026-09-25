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
# a no-op.
#
# The raise runs IN THE FOREGROUND, on purpose: Claude Code fires
# SessionStart hooks before it launches the MCP servers, so a raise
# that finishes inside the hook leaves a standing ship for the
# connectors to find.  A raise left to the background lost the race
# every time (the connectors give up and never reconnect; 2026-09-25,
# twice).  The hook's own limit is set beside it in settings.json;
# the raise is bounded below that, and the hook always exits zero.

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
    # A standing ship is left standing: a bare `up' buries the ship
    # that is up and raises a new one, crew and all, and a seating that
    # resumes a session must not do that to a healthy ship (the first
    # cloud raise's R.V. Basonn died exactly so).  Every room the yard
    # raises wears the basilisk.module label; one running is a ship.
    if docker ps -q --filter "label=basilisk.module" 2>/dev/null | grep -q .; then
        echo "a ship stands; not raising" >>/tmp/basilisk-session-start.log
        exit 0
    fi
    timeout "${RAISE_SECONDS:-240}" ./basilisk up "--$EMACS_IMAGE_VARIANT" >/tmp/basilisk-session-start.log 2>&1 \
        || echo "raise stopped early or failed (exit $?)" >>/tmp/basilisk-session-start.log
)
exit 0
