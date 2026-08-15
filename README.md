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
| `skewed-emacs` | an Emacs configuration and the image carrying it | **the Cap'n** — one fitting among several |
| `cyclops` | reverse proxy, paid binary | **the Pilot** |
| `eyes-only` | status board, paid binary | **the board** |

A Basilisk-class ship carries a Cap'n *by definition of the class* — the
generator refuses a roster without one. But `skewed-emacs` is that post's
**default fitting, not its definition**. The catalogue already references
`cyclops` and the `genworks-gdl` units purely by image name, with no repo
coupling; `:captain` was simply the one post whose fitting happened to
live in the same repo as the catalogue naming it.

A deployment with a Pilot and no crew of ours aboard is therefore not a
Basilisk at all. It is a Cyclops appliance — a different vessel, which is
a better story for a product than "a Basilisk with bits missing."

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
