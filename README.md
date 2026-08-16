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

## The inversion

Most tooling in this space hands an agent a sandbox and a shell: a place
to run commands, where every question is answered by starting a process
and reading what it prints. Basilisk hands it a machine that is *already
running* — an Emacs and one or more Common Lisp images, live, with
state, where the REPL is the API. Ask it something and it answers out of
a running image rather than out of a fresh process.

The corollary is the part that reads backwards at first. In most
Emacs-and-AI projects the agent lives *inside* Emacs: Emacs is the UI,
and a model is wired into a buffer. Here Emacs is inside the **agent** —
it is an MCP *server*, a tool the agent calls, sitting alongside the
Lisp engines as one more crew member that answers questions. Any MCP
client will do: Claude Desktop, Claude Code, Cursor, Gemini CLI, Codex,
LM Studio, or one you wrote yourself.

That is why the unit of delivery here is a fleet and not a package. An
editor plugin can put a model in your buffer; what it cannot do is hand
that model a compiler, a live image, and a REPL to think with — wired
up, reachable, and introspectable — in one command. This repo is that
command.

Two audiences arrive at this claim from opposite directions, so it is
argued in two places and only once each. The comparison against the
in-Emacs tools specifically — gptel, aidermacs, agent-shell,
claude-code-ide.el — belongs to the reader who came from the Emacs
world, and lives in the [skewed-emacs
README](https://github.com/gornskew/skewed-emacs). This page makes the
systems argument. Neither restates the other.

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

## Running it

### Requirements

- Git
- Docker

### Quickest start

```bash
git clone gitlab.genworks.com:gornskew/basilisk
cd basilisk
./basilisk up
```

Your `~/projects/` directory is mounted at `/projects` in the containers
and created if missing. The only intentional side effect on the host is
that `eskew` and `egskew` become available in your shell.

There is deliberately no way to start a stack from a `skewed-emacs`
clone, and no no-clone bootstrap path. `basilisk` downloaded on its own
used to create a container from the skewed-emacs image and extract the
compose machinery out of the repo snapshot baked inside it. That is gone
(2026-08-15): now that the shipyard is its own repo, cloning it is both
simpler and honest. An image is a crew member's quarters, not a delivery
vehicle for the shipyard.

### Custom projects directory

`./basilisk` generates `.env` via `./generate-env.sh`. Do not edit `.env`
directly. To use a non-default projects directory:

```bash
PROJECTS_DIR=/path/to/projects ./basilisk up
```

### Several instances on one box

```bash
BASILISK_INSTANCE=alpha BASILISK_PORT_OFFSET=100 ./basilisk up
```

Container names take the prefix; in-network hostnames stay canonical, so
`skewed-emacs` and `gendl-ccl` resolve the same inside every instance.

### Pulling updates

`./basilisk up` pulls missing images only. For fresh images use
`./basilisk up --pull` (or set `PULL_ALWAYS=1`). Bring the composition
down before pulling the repo, in case the pull changes compose config
that a running stack would shut down against:

```bash
cd ~/projects/basilisk
./basilisk down
git pull
./basilisk up --pull
```

### Supplemental service overlays (commercial GDL)

A base stack includes three Lisp environments: **skewed-emacs** (Emacs
Lisp via MCP), **gendl-ccl** and **gendl-sbcl** (the free Gendl kernel on
Clozure CL and SBCL). For commercial Genworks GDL — NURBS modeling
primitives, on Allegro CL — licensed users receive a supplemental overlay
repository:

```bash
cd ~/projects/
git clone <overlay-repo-url>    # e.g. genworks-gdl-betatest
cd <overlay-repo>/
./install                       # copies configs into ../basilisk/
cd ../basilisk/
./basilisk up                   # picks up the overlay automatically
```

`./install` copies compose overlays (`.yml`) and MCP config overlays into
the Basilisk clone; compose merges all `.yml` files there, and
`./basilisk up` merges MCP configs for all services. Set `BASILISK_DIR=`
if the clone lives somewhere else.

Host overlays (`/projects/<host>-stack/`) install the same way, and
additionally write `basilisk/systemd/host.env` — the image-variant and
host-port pins read by `basilisk.service`.

### Bring your own runtimes

The shipped containers keep a lean, Lisp-centric runtime: Emacs, Common
Lisp, and Node.js (which powers the lisply-mcp middleware and the bundled
AI TUIs). Notably **no Python ships in any image** — the build uses it
transiently in the builder stage, but runtime images are Python-free by
design.

Need Python, Ruby, or anything else? Bring it as a sidecar: drop an extra
`.yml` beside the compose files defining your service, and `./basilisk
up` merges it into the stack on the shared network, visible to Emacs and
the other containers.

### Troubleshooting

**Dangling containers.** If containers do not shut down cleanly, list
them with `docker ps` and force one out with `docker rm -f <name>`.

**Dangling network.** A `skewed-network` (or legacy
`skewed-emacs-network`) left behind can prevent a clean start:

```bash
cd ~/projects/basilisk
./basilisk down
docker network rm skewed-network   # only if necessary
./basilisk up
```

## Driving it from an MCP client

Wiring an MCP client to the fleet is a **Basilisk-level** concern, not a
skewed-emacs one, for a reason worth stating: the config being generated
registers *every* server on the roster — `skewed-emacs`, `gendl-ccl`,
`gendl-sbcl`, and whatever the overlays add. A Captain's repo could not
write that file, because it does not know what else is aboard.

`./basilisk up` generates the client configs into `mcp/`, detecting the
platform as it goes:

| file | for |
|---|---|
| `mcp/claude_desktop_config.json` | Claude Desktop — invokes `mcp/mcp-exec` directly on Linux/macOS, through `wsl` on Windows |
| `mcp/mcp.toml`, `mcp/mcp-container.json`, `mcp/mcp-windows.json` | other clients and the in-container agents |

See [docs/CLAUDE_DESKTOP.md](docs/CLAUDE_DESKTOP.md) for the Claude
Desktop walkthrough on all three platforms.

**In-container AI terminal agents.** The `full` image variant carries
Claude Code, Gemini CLI, Codex and Grok Build, launched as `claudly`,
`geminly`, `codexly` and `grokly` from any shell inside the container.
`./basilisk up` merges the same service configs and installs them per
agent — `/tmp/merged-mcp-config.json` for Claude and Gemini, a managed
block in `~/.codex/config.toml` and `~/.grok/config.toml` for the others
— so the agent you talk to in a terminal is itself wired to the Emacs and
Gendl images it lives beside. Credentials live in host-mounted dotfiles
and survive restarts. The `lite` variant ships none of them; an external
client such as Claude Desktop works exactly the same either way.

Once a client is connected,
[`mcp/opening-prompt.md`](mcp/opening-prompt.md) is a ready-made first
message.

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

This repo lives at **`gitlab.genworks.com:gornskew/basilisk`** — that is
the origin of record. It is mirrored to
[github.com/gornskew/basilisk](https://github.com/gornskew/basilisk)
(live as of 2026-08-15), which is the one to link to from public docs
and the one most people will clone.
