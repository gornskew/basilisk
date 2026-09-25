#!/bin/sh
# Copyright © 2026 Gornskew Enterprises
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.  Distributed WITHOUT
# ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.
#
# cloud-stack/session-start.sh -- every seating in a cloud vat wakes
# the vat; the launchers raise the ship.
#
# Wired as a SessionStart hook in .claude/settings.json.  A cloud
# session keeps the vat's filesystem between seatings but not its
# running processes: the residences are already pulled, dockerd is
# not running, and no ship stands.  Ashore -- any clone that
# cloud-stack/setup.sh never ran in -- there is no mark, and this is
# a no-op.
#
# THIS HOOK DOES NOT RAISE.  The yard's MCP launcher (mcp/mcp-exec)
# raises the ship on demand when it finds none, under a per-yard lock
# so several launchers raise one ship between them; and the launchers
# start CONCURRENTLY with this hook, whatever the docs say about
# ordering (observed 2026-09-25: a hook that raised, having checked
# for a standing ship a moment before the launchers raised theirs,
# buried the launchers' ship and took their sessions down with it).
# So the hook's whole duty is to have the vat awake -- dockerd up --
# by the time the launchers ask, and to get out of the way.

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
[ -f "$REPO_DIR/cloud-stack/.cloud-vat" ] || exit 0

if ! docker info >/dev/null 2>&1; then
    nohup dockerd >/var/log/dockerd.log 2>&1 &
    for _ in $(seq 1 60); do
        docker info >/dev/null 2>&1 && break
        sleep 1
    done
fi
docker info >/dev/null 2>&1 \
    && echo "vat awake; the launchers raise" >>/tmp/basilisk-session-start.log \
    || echo "no docker daemon after 60 s" >>/tmp/basilisk-session-start.log
exit 0
