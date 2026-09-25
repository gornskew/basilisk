# The cloud stack: a ship raised in a cloud session's vat

A Claude Code **cloud session** is given a virtual machine of its own
with a dock-style vat already fitted -- docker, dockerd and compose --
and a blueprint receiver that reaches Docker Hub and GitHub out of the
box.  That is enough to raise a Basilisk-class ship in it, with the
session's cyborg as the passenger: every room aboard answers as an MCP
server to the cyborg in the seat, and nothing aboard is served to
anyone else.  What this buys is a ship that is nobody's laptop:
evals, churn tests and cold-load proofs run here without touching a
working galaxy.

## Fitting out the environment

On the cloud environment (claude.ai/code, the environment settings):

| setting | value |
|---|---|
| repository | `gornskew/basilisk`, branch `devo` |
| network access | **Trusted** (the default): Docker Hub and GitHub are on it |
| setup script | the body below: it finds the checkout, since the script does not run inside it |
| environment variables | see below |

```bash
#!/bin/bash
echo "setup cwd: $(pwd)"
repo="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$repo" ] || [ ! -f "$repo/cloud-stack/setup.sh" ]; then
  hit="$(find / -xdev -path '*/cloud-stack/setup.sh' -not -path '/proc/*' 2>/dev/null | head -1)"
  repo="$(cd "$(dirname "$hit")/.." 2>/dev/null && pwd -P)"
fi
if [ ! -f "$repo/cloud-stack/setup.sh" ]; then
  echo "no basilisk checkout with cloud-stack/setup.sh found"; exit 1
fi
echo "repo: $repo"
cd "$repo" && bash cloud-stack/setup.sh
```

| variable | purpose |
|---|---|
| `DOCKERHUB_USER`, `DOCKERHUB_TOKEN` | the Guild's papers.  With both set, the Guild's cyborg (SMP) unit comes aboard from its private catalog; without them the base rig flies alone |
| `EMACS_IMAGE_VARIANT` | the ready room's strain; `lite` unless told otherwise (the `full` strain is 3.5 GB of residence for nothing a cloud seat uses) |
| `CURRENT_BRANCH` | the catalog branch the residences are tagged with; `devo` unless told otherwise (the scripts pin it; the variable is the belt to those braces) |
| `PROJECTS_DIR` | the scroll chest requisitioned as `/projects` aboard; `~/projects` (created) unless told otherwise |
| `TZ` | ship's time |

The setup script runs as root before the cyborg is seated, and the
vat keeps the filesystem it leaves behind for about a week (the
environment cache) -- but only when the script exits zero within
about five minutes, which is the rule that shapes it.  It never
raises the ship.  It starts the vat if the machine has not, logs in
to Docker Hub when the papers are present and installs this overlay
only then, pulls what residences it can in the time it has (four
minutes by default; whatever arrived is cached, the first raise
fetches the rest), and writes the cyborg scrolls -- `.mcp.json`
beside the repo root and a splice into the user scroll -- every room
through the yard's launcher `mcp/mcp-exec`, which execs into the
ready room and raises the ship on demand.  The vat does not keep
running processes, so `cloud-stack/session-start.sh` -- a
SessionStart hook in `.claude/settings.json` -- raises the ship in
the background at every seating.  Ashore the hook finds no
`cloud-stack/.cloud-vat` mark and does nothing.  Until the raise has
finished, a hail to a room may time out; hail again a minute later.
The setup's own account of itself is in `/tmp/basilisk-init.log` and
`/tmp/basilisk-pull.log`, the raise's in
`/tmp/basilisk-session-start.log`.

## What the cyborg finds

| room | MCP server | what it is |
|---|---|---|
| ready room | `ready-room` | the Captain's Emacs (readymax, lite strain), lisply over Emacs Lisp |
| bridge | `bridge` | gendl-ccl: open Gendl on CCL |
| engine room | `engine-room` | gendl-sbcl: open Gendl on SBCL |
| guild workshop | `guild-workshop` | the Guild's SMP engine with the solid-modelling kernel (with papers only) |

plus the sick bay and the museum chamber, which take no passengers.
`mcp/opening-prompt.md` is a suitable first hail.

## Sizing

Measured on a nine-room dev ship: under 2 GB of memory in all, and
about 8 GB of residences for the base rig plus the Guild unit.  The
cloud vat offers roughly 4 vCPU, 16 GB and 30 GB, so the complement
here fits with room to spare; what does not fit is a galaxy's worth
of overlays with a full-strain ready room, which is why this one is
lite and signs on one hand.

## What the vat lacks, and how the pouch makes do

- **No IPv6 in the kernel** (no `/proc/sys/net/ipv6`).  The base
  articles ask for a dual-stack ship network, which the vat cannot
  create.  `cloud-ipv4-overlay.yml`, copied beside
  `docker-compose.yml` by the setup script, makes the network
  IPv4-only.
- **The checkout's branch is the session's** (`claude/<something>`),
  and the yard tags residences with the checkout's branch.  Both
  scripts pin `CURRENT_BRANCH=devo`; setting the same in the
  environment's variables is the belt to those braces.
- **The setup script does not run inside the checkout.**  The
  environment's script body must find it (the README's body above
  does), and its output is shown in the session's failure dialog.
  Seen 2026-09-25: the checkout at `/home/user/basilisk`, the seat
  running as root.
- **A cached setup does not run again.**  Papers or variables added
  to the environment after its cache was built are not seen until
  the cache is rebuilt, which an edit to the setup script body
  forces (a comment line will do).  Check with
  `/tmp/basilisk-setup.log`, whose first line says whether the
  papers were present.

## The first raise (2026-09-25)

R.V. Basonn: five rooms, all healthy, every room answering `pong`
through `mcp/mcp-exec`, the launcher the connectors use; the gangway
check passed in twelve seconds once the residences were aboard.  So
the seat can reach docker and exec into the ready room, and the
launcher form of the scrolls is right.  What it also taught: **the
session's connectors give up while the ship is still empty and do
not reconnect** -- a raise that finishes after they have timed out
leaves the room tools missing for the rest of that session, and a
fresh session is the remedy.  The setup script's pulls exist so
that the seating's raise fits inside the launcher's patience (90 s
in `mcp/mcp-exec`); a cold cache does not, and its first session is
for fitting out.  The raise warns "no Transporter Chief aboard:
nothing fronts HTTP", which is right: the cloud ship carries no
transporter room, and the rooms answer on their published ports.

**The third and fourth seatings settled the timing, the hard way.**
With the residences cached the ship stands healthy within a minute,
and the connectors still died twice: first because the hook raised
in the background while they launched; then, with the hook raising
in the foreground on the docs' word that SessionStart hooks run
before the MCP servers, because the launchers in fact start
CONCURRENTLY with the hook -- they found no ship and raised one
themselves (the launcher raises on demand, under a per-yard lock),
and the hook, having checked a moment earlier, buried that ship with
a bare raise of its own and took the connectors' sessions down with
it.  So the hook no longer raises at all.  Its whole duty is to have
dockerd up by the time the launchers ask; the launchers raise the
ship between them, and a bare raise from anyone else while a ship
stands is the thing to avoid.  The same seatings answered a
question: project-scoped `.mcp.json` servers are connected without
asking in a cloud seat.

## Still open

- The Guild's cyborg unit has not yet been raised in a vat: the
  first raises flew without the papers, and papers added to the
  environment AFTER its cache was built are not seen until the cache
  is rebuilt -- editing the setup script body (a comment line will
  do) forces that.
- Whether `MCP_TIMEOUT` set in the environment's variables reaches
  Claude Code in a cloud seat (undocumented); harmless to set.  The
  launcher's own patience is 90 s (`mcp/mcp-exec`), which a warm
  raise fits.
- The hook's raise once ended `exit 127` after the welcome line:
  something the yard calls after "Services are Up" is missing in the
  vat.  Moot now that the hook does not raise; worth a look when the
  launchers' raise log shows the same.
