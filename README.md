# Basilisk

**An open-source, AI-enabled engineering workstation, defined entirely
in code and able to run on any physical hardware minimally sufficient to
carry it.** (The docker compose stack formerly known as the
"skewed-emacs stack.")

Basilisk is a container composition framework — infrastructure as code
aimed at a target most IaC tooling never had in mind: a live symbolic
computing environment a human and an AI agent can both work in. It turns
a bare box into a crewed vessel — an Emacs console, one or more Common
Lisp engines, a reverse proxy at the conn, a watchdog — wired together
with immediate connectivity for HTTP, SLIME/Swank and MCP.

It is also a class of starship, and this repository is the yard that
lays them down: the roster is a file, so any yard with that file builds
the same ship, anywhere you care to put one.

It is the open-source foundation under the Gornskew Enterprises product
line, whose paid binaries ride in it: **Cyclops** (the reverse proxy at
the conn, $99) and **Eyes Only** (the status board, $69).

## Why this repo exists

`skewed-emacs` was one name doing three jobs — an Emacs configuration, a
container image carrying that configuration, and the compose framework
that runs a fleet of containers around it. "Restart skewed-emacs" was
genuinely ambiguous between *the editor* and *the whole fleet on this
box*, and those are very different requests.

The skewed-emacs README has named that problem for a while. This repo is
the structural answer to it:

| repo | what it is | ship metaphor |
|---|---|---|
| `basilisk` | the compose framework, the fitting catalogue, the base stack definition | **the shipyard** |
| `skewed-emacs` | an Emacs configuration and the image carrying it | **the Captain** — one fitting among several |
| `cyclops` | reverse proxy, paid binary | **the Pilot** |
| `eyes-only` | status board, paid binary | **the Communications Officer** (Comm) — duties include running the board that any ship can project on its bridge viewscreen or other display |

A Basilisk-class ship carries a Captain by default. The generator can
warn, but does not refuse, a roster without one. `skewed-emacs` is that
post's **default fitting**; the catalogue references fittings by image
name, not repo name.

A deployment with only a Pilot is a standalone Cyclops deployment; a
deployment with only a ship's engineer (gendl-ccl) is a standalone
monolithic KBE server deployment. All combos are possible, but having a
Captain, and having that Captain be of the skewed-emacs or a derived
species, is recommended.

Pilot and Comm ship as **runtimes**, not development seats: they run the
system they were built for and carry no compiler, which is what puts them
a few yards short of an Engineer.

Every binary product builds and tests on **Allegro CL** — the supported
platform, and where the support relationship actually is. Shipping on
another Common Lisp is not ruled out, but an additional delivery target
does not displace the reference one.

## Status

**Migrated and running** (2026-08-15). The yard moved here from
`skewed-emacs/` and was ripped out there: that repo is the Captain only —
no compose file, no `compose-dev`, no generator, and deliberately no
supported way to start a stack from it. `narad` runs from this clone,
verified across adopt, restart and full stop/start cycles.

Still open: the `mcp/` per-file split; `sally`, `shelly` and `balaram`
not yet cut over (pull + `./install` + restart at deploy time); a
cold-boot test of `basilisk.service`.

See [MIGRATION.md](MIGRATION.md) for the file-by-file manifest of what
moved, what stayed, what broke on the way, and the one genuinely hard
problem (`bootstrap_from_image`).

## Origin of record

This repo lives at **`gitlab.genworks.com:gornskew/basilisk`**. A mirror
to `github.com/gornskew/basilisk` will follow once the dust settles;
until then, clone from gitlab — the github URL does not resolve yet.
