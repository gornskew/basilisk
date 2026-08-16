# Basilisk

**An AI-enabled engineering workstation defined in code**

Basilisk is an open-source _Infrastructure as Code_ (IaC) offering
which can conjure up a live symbolic computing environment that a
human and an AI agent can both access. It turns a bare box into a
hosted workstation that sports an Emacs (console + GUI) plus one or
more Common Lisp engines out of the box, with automatically-wired
connectivity for HTTP, SLIME/Swank (for use with Emacs), and MCP (for
your AI agents to be able to drive the sandboxed stack).

Basilisk also names a hull class of space vessel, and this repository
is the shipyard that lays them down (see the whole [lore](LORE.md) if
you wish).

Basilisk also serves as the open-source foundation under the Gornskew
Enterprises product line, whose paid binaries: **Cyclops**, a $99 http
reverse proxy that always has a seat waiting at the Helm, and **Eyes
Only**, a $69 Telemetry solution that can slot into an available Comms
posting.


## Running it

### Requirements

- Git
- Docker

### Quickest start

```bash
git clone https://github.com/gornskew/basilisk
cd basilisk
./basilisk up
```

If you have a `~/projects/` directory, it will end up mounted at
`/projects` in the containers, and will be created if missing. The
only intentional side effect on the host is that `eskew` and `egskew`
become available commands in your shell.

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
Lisp via MCP), **gendl-ccl** and **gendl-sbcl** (the free Gendl kernel
on Clozure CL and SBCL). For commercial Genworks GDL — NURBS modeling
primitives, on Allegro CL — licensed users receive a supplemental
overlay repository:

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
AI TUIs). 

If you need Python, Ruby, or other another heavy environment that
deserves its own separate container, you can bring it in as a
"sidecar" using the same overlay technique, where a local
`services.sexp` serves as the Single Source of Truth and basilisk's
`generate-configs.el` takes care of the rest (remember to run its
`skewed-generate-configs` on your sidecar directory after changing
`services.sexp`)

## Driving it from an MCP client

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
`geminly`, `codexly` and `grokly` from any shell (e.g. `M-x vterm`)
inside the container e.g. in an `eskew` session.

The `./basilisk up` merges the same service configs and installs them
per agent — `/tmp/merged-mcp-config.json` for Claude and Gemini, a
managed block in `~/.codex/config.toml` and `~/.grok/config.toml` for
the others — so the agent you talk to in a terminal is itself wired to
the Emacs and Gendl images it lives beside. Credentials live in
host-mounted dotfiles and survive restarts. The `lite` variant ships
none of these built-in TUIs, but an external client such as Claude
Desktop will work exactly the same either with -lite or -full
variants.

Once a client is connected,
[`mcp/opening-prompt.md`](mcp/opening-prompt.md) is a suitable
ready-made first message.

