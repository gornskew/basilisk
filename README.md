# Basilisk

**The docker compose stack formerly known as the "skewed-emacs stack."**

Basilisk is a container composition framework: it turns a bare box into a
crewed vessel — an Emacs console, one or more Common Lisp engines, a
reverse proxy at the conn, a watchdog — wired together with immediate
connectivity for HTTP, SLIME/Swank and MCP.

It is also the open-source foundation under the Gornskew Enterprises
product line, whose paid binaries ride in it: **Cyclops** (the reverse
proxy at the conn) and **Eyes Only** (the status board).

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
a few yards short of an Engineer. Both are planned for delivery on
Allegro CL at this juncture; other Common Lisps are not ruled out.

## Status

**Scaffold.** The framework still lives in `skewed-emacs/` and is fully
working there. Nothing has moved yet.

See [MIGRATION.md](MIGRATION.md) for the file-by-file manifest of what
moves here, what stays, what breaks in the process, and the one genuinely
hard problem (`bootstrap_from_image`).

## Origin of record

This repo lives at **`gitlab.genworks.com:gornskew/basilisk`**. A mirror
to `github.com/gornskew/basilisk` will follow once the dust settles;
until then, clone from gitlab — the github URL does not resolve yet.
