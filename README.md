# Basilisk

**An AI-enabled engineering workstation defined in code**

Basilisk is an open-source _Infrastructure as Code_ (IaC) offering
which can conjure up a live symbolic computing environment that a
human and an AI agent can both access. It turns a bare box into a
hosted workstation that sports an Emacs (console + GUI) plus one or
more Common Lisp engines out of the box, with automatically-wired
connectivity for HTTP, SLIME/Swank (for use with Emacs), and MCP (for
your AI agents to be able to drive the sandboxed stack).

## The inversion

Most tooling in this space hands an agent a sandbox and a shell: a
place to run commands, where every question is answered by starting a
process and reading what it prints. Basilisk hands it a machine that is
*already running* — an Emacs and one or more Common Lisp images, live,
with state, where the REPL is the API. Ask it something and it answers
out of a running image rather than out of a fresh process.

The corollary reads backwards at first. In most Emacs-and-AI projects
the agent lives *inside* Emacs: Emacs is the UI, and a model is wired
into a buffer. Here it is the other way round, and it is not only the
editor — the whole stack sits inside the **agent**. Every service on
the roster is an MCP server the agent calls: the Emacs, each Lisp
engine, and whatever the overlays add. While Emacs is one peer service
among potentially several, a well-running Basilisk stack typically
sports an Emacs. 


## Naming

Following an in-stack "starship and crew" conceit, service hostnames
match compose service names and reflect _postings_ (i.e. job roles) on
a **Basilisk**-class _space vessel_: `captain` (typically the Emacs),
`jr-eng-human` and `jr-eng-cyborg` for the ship's own engineers and
`guild-master-human` / `guild-master-cyborg` for commissioned ones
(these are the Common Lisp KBE-oriented services), a `medic` (autoheal
or similar), an optional `pilot` (an HTTP reverse proxy such as
Gornskew Cyclops), and an optional Comms Officer (telemetry — could be
a Gornskew Eyes Only service).

The `-human` / `-cyborg` suffix distinguishes single-threaded from
multithreaded builds of the same engine; `fittings.sexp` is the
authority on which postings a given crew level brings up.

The details behind the naming conceit are optional reading in
[BASILISK.md](BASILISK.md), [LORE.md](LORE.md) and
[GLOSSARY.md](GLOSSARY.md).


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

Cloning this repository is the only known repeatable way to bring a
stack up. There is no bootstrap path that extracts the compose
machinery out of an image. So you need to clone this repository but
not the `skewed-emacs` or `gendl` ones nor those for any other
component container -- component containers come from the hosted
registry at Docker Hub.


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

Container names take the prefix, but in-network hostnames stay
canonical — `captain` and `jr-eng-human` resolve the same inside every
instance, so nothing configured against a hostname needs to know which
instance it is in.

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


### Supplemental service overlays

A base default Basilisk stack brings up _skewed-emacs_ (Emacs Lisp via
MCP) plus one or more AGPL-licensed Gendl variants, with image builds
maintained by Gornskew. Everything beyond that — an extra engine, a
proxy, a telemetry board, a language runtime the shipped images do not
carry — arrives as an **overlay**.

An overlay is a directory beside your `basilisk/` clone with its own
`basilisk.sexp`. That file is the single source of truth and it is
**sparse**: declare only what deviates from, or adds to, the base
roster. Everything you do not mention is inherited.

```bash
mkdir ~/projects/my-overlay && cd ~/projects/my-overlay
$EDITOR basilisk.sexp          # your deviations and additions
```

Generate the rest from it, in the containerized Emacs or any Emacs that
can see both directories:

```elisp
(load-file "/projects/basilisk/generate-configs.el")
(skewed-generate-configs "/projects/my-overlay/")
```

That writes, all prefixed with your directory's name:

| generated | what it is |
|---|---|
| `my-overlay-compose.yml` | the compose overlay; docker merges it with the base |
| `mcp/my-overlay-mcp*.json`, `mcp/my-overlay-mcp.toml` | MCP client configs for the services you added |
| `generated/my-overlay-services-generated.el` | service discovery for the Emacs dashboard and SLIME |
| `install` | **the install script itself — you do not write this** |

Then install and bring the stack up:

```bash
./install                      # copies the generated files into ../basilisk/
cd ../basilisk && ./basilisk up
```

`./install` copies rather than symlinks, and starts nothing, so running
it repeatedly is safe and is how a clone that missed a step catches up.
Set `BASILISK_DIR=` if your Basilisk clone is not the sibling directory.

Re-run `skewed-generate-configs` **and** `./install` after every edit to
`basilisk.sexp` — the generated files are outputs, never edit them
directly.

#### Sidecars: bringing your own runtime

The shipped containers keep a lean, Lisp-centric runtime: Emacs, Common
Lisp, and Node.js (which powers the lisply-mcp middleware and the
bundled AI TUIs). If you need Python, Ruby, or anything else heavy
enough to deserve its own container, that is not a special case — it is
just an overlay whose `basilisk.sexp` declares one more service. It
joins the shared network and is reachable by hostname from every other
container, same as anything the base stack brought up.

#### Host overlays

A `<host>-stack/` directory is the same mechanism used to pin one
physical machine's deviations — ports, image variant, per-host config
files. It installs identically, and additionally writes
`basilisk/systemd/host.env`, the image-variant and host-port pins read
by `basilisk.service`.

**A stack overlay maps to a host, and the directory name is how.** One
machine, one `<hostname>-stack/`, named for the box it configures —
deploy tooling finds a host's overlay by that name and no other, so the
name is load-bearing rather than descriptive.

#### Standalone deployments: only your own services

An overlay can only **add**. `./basilisk` loads `docker-compose.yml`
plus every other `.yml` beside it, and the Captain, the ship's
engineers and the Medic are defined in that base file — so no overlay,
however sparse, can take them away.

To ship a stack that runs *only* what you declare — a standalone
Cyclops with nothing but a proxy, or a lone KBE server with nothing but
an engine — you replace the base instead of overlaying it. Two things
make that work:

**1. Declare a `:roster`, not a `:crew-level`.** Every defined crew
level (`:standard`, `:piloted`, `:guild`) includes a Captain, so no
level can express "pilot only". An explicit roster can:

```lisp
(:meta (:version "3.0"
        :class "basilisk"
        :roster (:pilot)          ; just the proxy; nobody else
        :description "Standalone Cyclops")
 :defaults (...)
 :services (...))                 ; deviations from the :pilot fitting
```

**2. Generate with an empty prefix**, which makes the output the base
`docker-compose.yml` rather than an overlay. Pass all three arguments so
your `basilisk.sexp` can live in its own directory while the output
lands in the clone:

```elisp
(load-file "/projects/basilisk/generate-configs.el")
(skewed-generate-configs "/projects/basilisk/"              ; where output goes
                         "/projects/my-cyclops/basilisk.sexp" ; your SSoT
                         "")                                ; "" = base, not overlay
```

The empty prefix also matters for a second reason: an overlay skips
posts already defined in the base, on the grounds that restating them
would fight it. A base generation has nothing to fight, so it emits
every post the roster names — which is what lets a one-post roster
produce a one-service stack.

The generator **warns and proceeds** for every post you left out, e.g.
`no Captain: no MCP tooling and no eskew/egskew — a standalone
deployment rather than a crewed ship`. That is a note, not an error:
these are real shapes, and a Captain is recommended rather than
required.

> **Watch the clone.** `docker-compose.yml` is a *tracked* file.
> Regenerating it in place leaves the clone permanently dirty, and
> anything that pulls before it starts — a deploy script, `git pull`,
> your own muscle memory — will either refuse to pull or clobber your
> generated stack. Commit the generated `docker-compose.yml` in your own
> clone or fork, so it is tracked-and-correct rather than
> tracked-and-modified. A standalone deployment's clone *is* the yard
> for that ship; treat it as one.


#### Pro Tip: Overlays mount individual files — pull, THEN restart

A base stack mounts whole directories — `${PROJECTS_DIR}` onto
`/projects` — and a whole-directory mount tracks its contents, so an
edit to an application's source while a container is running lands
immediately. Overlays are different: they mount **individual files** —
each container gets its initialization script, and the proxy its
`.sexp` config, mounted as a single file rather than as a directory.

Docker binds a single file by **inode**, and `git pull` does not edit
a file in place — it replaces it with a new one. A container running
across the pull therefore keeps reading the file that existed when it
started: the old content, at a path that now holds different bytes.

Nothing announces this. The stack is healthy, the file on disk is
correct, and a hot reload cheerfully re-reads the stale inode and
reports success:

```bash
git pull                                  # the .sexp gets a new inode
curl -X POST .../_cyclops/reload-config   # re-reads the OLD one, says ok
```

Solution: pull first, then restart the stack (`sudo systemctl restart
basilisk`, or `./basilisk down && ./basilisk up`) so the mounts
re-resolve.  Restarting before the pull is the same as not restarting
at all.

When you verify, check the **thing you changed**, not a summary
statistic near it — a rule count does not move when you edit an
existing rule, so grep the live routes for the actual rule, and
`docker exec <container> cat <mounted-file>` settles any doubt.



## Driving it from an MCP (Model Context Protocol) client

`./basilisk up` generates mcp client configurations into the `mcp/`
subdirectory, detecting the platform as it goes:

| file | for |
|---|---|
| `mcp/claude_desktop_config.json` | Claude Desktop — invokes `mcp/mcp-exec` directly on Linux/macOS, through `wsl` on Windows |
| `mcp/mcp.toml`, `mcp/mcp-container.json`, `mcp/mcp-windows.json` | other clients and the in-container agents |

See [docs/CLAUDE_DESKTOP.md](docs/CLAUDE_DESKTOP.md) for the Claude
Desktop walkthrough on all three platforms.


**In-container AI terminal agents.** The `full` image variant carries
terminal agents — Claude Code, Gemini CLI, Codex, Grok Build — already
wired to the rest of the stack, so an agent you talk to in a shell
inside the Captain reaches the same services an external client would.
`./basilisk up` installs the merged config for each of them. The `lite`
variant ships none, and an external client such as Claude Desktop works
identically either way.

Which agents, how they are built in, and where each keeps its
credentials belong to the image that carries them: see
[skewed-emacs/docker/README.md](https://github.com/gornskew/skewed-emacs/blob/devo/docker/README.md).

Once a client is connected,
[`mcp/opening-prompt.md`](mcp/opening-prompt.md) is a suitable
ready-made first message.

## License

Copyright © 2026 Gornskew Enterprises.

Basilisk is free software, released under the **GNU Affero General
Public License, version 3 or later** — the full text is in
[LICENSE](LICENSE). The images a Basilisk stack pulls carry their own
terms: the Gendl variants are AGPL likewise, while the licensed
`genworks/gdl` enterprise images are commercial and governed by their
own agreement.

## Origin of record

The origin of record for this repository is maintained by **Gornskew
Enterprises**, and mirrored to
[github.com/gornskew/basilisk](https://github.com/gornskew/basilisk). Public
Issues and PRs may be lodged against this github mirror. 


