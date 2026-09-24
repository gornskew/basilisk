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
| setup script | `bash cloud-stack/setup.sh` |
| environment variables | see below |

| variable | purpose |
|---|---|
| `DOCKERHUB_USER`, `DOCKERHUB_TOKEN` | the Guild's papers.  With both set, the Guild's cyborg (SMP) unit comes aboard from its private catalog; without them the base rig flies alone |
| `EMACS_IMAGE_VARIANT` | the ready room's strain; `lite` unless told otherwise (the `full` strain is 3.5 GB of residence for nothing a cloud seat uses) |
| `PROJECTS_DIR` | the scroll chest requisitioned as `/projects` aboard; `~/projects` (created) unless told otherwise |
| `TZ` | ship's time |

The setup script runs once, as root, before the cyborg is seated:
it starts the vat if the machine has not, logs in to Docker Hub when
the papers are present, installs this overlay, raises the ship, and
writes the cyborg scrolls -- `.mcp.json` beside the repo root and a
splice into the user scroll.  The vat keeps its filesystem between
seatings for about a week (the environment cache), so the residences
are pulled once; it does not keep running processes, so
`cloud-stack/session-start.sh` -- a SessionStart hook in
`.claude/settings.json` -- raises the ship again at every seating,
in the background.  Ashore the hook finds no `cloud-stack/.cloud-vat`
mark and does nothing.

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

## Open questions, until the first raise says

- Whether the session's cyborg runs as the root that ran the setup
  script.  If not, the splice into `~/.claude.json` lands in the
  wrong home and `.mcp.json` beside the repo is what carries the
  rooms -- and that user needs the docker socket, since the launcher
  execs into the ready room through compose.
- Whether project-scoped `.mcp.json` servers need approving in a
  cloud seat the way they do ashore.
- How long a raise takes on a cold cache against the session's own
  patience: the first seating pays for the pulls.
