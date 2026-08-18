# Basilisk

This pouch is the **yard**: everything needed to lay down, fit out,
and muster a Basilisk-class ship. What a Basilisk *is* — the vat, the
articles, the crew — is the overview scroll,
[BASILISK.md](BASILISK.md). This scroll is the operating manual: how
to raise him, how to sign on more crew, and how to keep him sailing.

A standard rig carries a _Captain_ (the ship's console — visitors
received over MCP, HTTP, and SLIME/Swank), a _1st Officer_ and a
_Ship's Engineer_ (the engines: they reckon, they build, and they
draw), and a _Ship's Doctor_. Human and cyborg visitors hail any hand
aboard by name. The whole complement is stated in one scroll,
`basilisk.sexp`, and every other document the ship needs is drawn
from it.


## Raising a ship

### Requirements

- Git
- Docker

### Quickest start

```bash
git clone https://github.com/gornskew/basilisk
cd basilisk
./basilisk up
```

The hull forms, the crew musters, and he floats out under a name the
yard bestows — the name is minted at fitting-out and his whole galaxy
knows him by it.

If you have a `~/projects/` directory it ends up stowed at
`/projects` aboard every crew member, and is created if missing. The
only intentional side effect ashore is that `eskew` and `egskew`
become available commands in your shell — they hail the Captain's
console.

Cloning this pouch is the only known repeatable way to raise a ship.
There is no path that conjures the yard back out of a crew member;
the creatures themselves come from their home worlds (Docker Hub) on
their own, so you need this pouch and no other.

### Custom projects directory

`./basilisk` drafts `.env` via `./generate-env.sh`. Do not edit
`.env` directly. To stow a different directory:

```bash
PROJECTS_DIR=/path/to/projects ./basilisk up
```

### Several ships in one galaxy

```bash
BASILISK_INSTANCE=alpha BASILISK_PORT_OFFSET=100 ./basilisk up
```

Each ship gets his own name and his own waters. Aboard any of them
the crew answer to the same names — `captain` hails the Captain on
every ship of the class — so nothing configured against a crew name
needs to know which ship it sails in.

### Pulling updates

`./basilisk up` fetches only missing creatures. For fresh ones use
`./basilisk up --pull` (or set `PULL_ALWAYS=1`). Stand the ship down
before pulling the pouch, in case the pull changes papers a running
ship would refuse to stand down against:

```bash
cd ~/projects/basilisk
./basilisk down
git pull
./basilisk up --pull
```


## The articles, and the yard's paperwork

The ship's articles are `basilisk.sexp` — the one scroll written by
hand. The yard reads that name and **no other**: articles written for
a differently-named yard are not read, and the error names both the
file it wanted and any stranger's scroll it found.

After editing the articles, have the yard redraw the paperwork:

```elisp
(load-file "/projects/basilisk/generate-configs.el")
(skewed-generate-configs "/projects/basilisk/")
```

That writes, among others:

| drawn document | what it is |
|---|---|
| `docker-compose.yml` | the vat's own instructions |
| `mcp/mcp*.json`, `mcp/mcp.toml` | hailing directories for cyborg visitors |
| `generated/services-generated.el` | the Captain's copy of the complement |
| `generated/crew.env` | the **crew ledger**: each posting, and the hand standing it |

The drawn documents are outputs. Never edit them directly; edit the
articles and redraw.


## Signing on more crew

A base ship carries the standard rig. Everything beyond that — an
extra engine, an ingress, a board, a runtime the shipped creatures do
not carry — arrives by **overlay**: a pouch beside this one, one
pouch per ship design, carrying its own `basilisk.sexp` (same name;
the yard reads no other). Overlay articles are **sparse**: state only
what deviates from, or adds to, the standard rig. Everything you do
not mention is inherited.

```bash
mkdir ~/projects/my-overlay && cd ~/projects/my-overlay
$EDITOR basilisk.sexp          # your deviations and additions
```

Have the yard draw the overlay's paperwork, then carry it in and
raise the ship:

```elisp
(load-file "/projects/basilisk/generate-configs.el")
(skewed-generate-configs "/projects/my-overlay/")
```

```bash
./install                      # carries the papers into ../basilisk/
cd ../basilisk && ./basilisk up
```

`./install` copies rather than points, and starts nothing, so running
it repeatedly is safe and is how a pouch that missed a step catches
up. Set `BASILISK_DIR=` if your Basilisk clone is not the sibling
directory. Re-run the drawing **and** `./install` after every edit to
the articles.

### Standing orders and templated fittings

Some fittings — an ingress's standing orders, a services-init hook —
need to name other crew members. They never do so directly: a
templated fitting names a **posting**, and the yard resolves it
against the crew ledger on the way up, so the orders survive renames
and reliefs untouched.

`./install` carries such fittings into `templates/`; at `./basilisk
up` the yard rewrites each one from the ledger into `generated/`,
and the rewritten copy is what the crew member carries. A placeholder
naming a posting nobody stands draws a warning at up-time. One hand
per posting for now — where several stand one posting, the first
declared answers the hail.

### Bringing your own species

If you need Python, Ruby, or anything else heavy enough to deserve
its own berth, that is not a special case — it is an overlay whose
articles sign on one more hand. He joins the ship's waters and
answers to his name from every other berth, like anyone the standard
rig brought aboard. A species aboard with no posting musters as a
**stowaway**: comprehended, fed, and assigned to nothing.


## A class of your own

An overlay can only **add**: the standard rig is stated in the base
articles, and no overlay, however sparse, can take a hand away. To
raise a ship that carries *only* what you declare — a lone ingress,
a single engine and nothing else — fork the pouch and gut the
articles to taste. Name the fork's pouch for its class, and name its
articles to match: the yard reads the scroll named for itself, which
is what keeps one class's articles from quietly composing in
another's yard.

The muster **grumbles and proceeds** for every posting you left out —
`no Captain: no MCP tooling and no eskew/egskew — a standalone
deployment rather than a crewed ship`. That is a note, not an error:
these are real shapes, and a Captain is recommended rather than
required.

> **Watch the pouch.** `docker-compose.yml` is a *tracked* scroll.
> Redrawing it in place leaves the pouch permanently dirty, and
> anything that pulls before it starts — a deploy script, `git pull`,
> your own muscle memory — will either refuse to pull or clobber your
> drawn papers. Commit the drawn `docker-compose.yml` in your own
> pouch or fork, so it is tracked-and-correct rather than
> tracked-and-modified. A standalone ship's pouch *is* the yard for
> that ship; treat it as one.


## Pro tip: single scrolls bind by substance — pull, THEN restart

A base ship stows whole shelves — `${PROJECTS_DIR}` at `/projects` —
and a stowed shelf tracks its contents, so an edit ashore lands
aboard immediately. Fittings are different: a crew member carries an
individual scroll — his init hook, the ingress's standing orders —
bound as a single scroll rather than a shelf.

A single scroll is bound by its **physical substance**, not its
name, and `git pull` does not edit a scroll in place — it replaces
it with a new one. A hand reading across the exchange keeps reading
the substance that existed when he came aboard: the old words, at a
name that now holds different ones.

Nothing announces this. The ship is healthy, the scroll ashore is
correct, and a hot reload cheerfully re-reads the stale substance and
reports success:

```bash
git pull                                  # the .sexp gets new substance
curl -X POST .../_cyclops/reload-config   # re-reads the OLD one, says ok
```

Solution: pull first, then relieve the ship (`sudo systemctl restart
basilisk`, or `./basilisk down && ./basilisk up`) so the bindings
re-resolve. Relieving before the pull is the same as not relieving
at all.

When you verify, check the **thing you changed**, not a summary
statistic near it — a rule count does not move when you edit an
existing rule, so ask the live ship for the actual rule, and

```bash
docker exec <crew-member> cat <the-scroll-aboard>
```

settles any doubt.


## Cyborg visitors (MCP clients)

`./basilisk up` drafts hailing directories into the `mcp/`
subdirectory, detecting the platform as it goes:

| scroll | for |
|---|---|
| `mcp/claude_desktop_config.json` | Claude Desktop — invokes `mcp/mcp-exec` directly on Linux/macOS, through `wsl` on Windows |
| `mcp/mcp.toml`, `mcp/mcp-container.json`, `mcp/mcp-windows.json` | other clients and the agents aboard |

See [docs/CLAUDE_DESKTOP.md](docs/CLAUDE_DESKTOP.md) for the Claude
Desktop walkthrough on all three platforms.

**Agents aboard.** The `full` strain of the Captain's species carries
terminal agents — Claude Code, Gemini CLI, Codex, Grok Build —
already acquainted with the rest of the crew, so an agent you talk to
at the Captain's console reaches the same hands an off-ship visitor
would. `./basilisk up` issues each of them the merged hailing
directory. The `lite` strain carries none, and an off-ship client
such as Claude Desktop works identically either way.

Which agents, how they come aboard, and where each keeps its papers
belong to the species that carries them: see
[skewed-emacs/docker/README.md](https://github.com/gornskew/skewed-emacs/blob/devo/docker/README.md).

Once a visitor is aboard,
[`mcp/opening-prompt.md`](mcp/opening-prompt.md) is a suitable
ready-made first hail.


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
[github.com/gornskew/basilisk](https://github.com/gornskew/basilisk).
Public Issues and PRs may be lodged against this github mirror.
