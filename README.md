# Basilisk

This pouch is the **yard**: the directions for laying down, fitting
out, and mustering a Basilisk-class ship. More detail about what a
Basilisk *is* can be found in the overview scroll,
[BASILISK.md](BASILISK.md). This scroll is both the fabrication and
operating manual: raising the ship, standing him down, securing
passage for your desired passengers, both biological and cyborg.

A standard rig carries a **Captain** at the ship's console, a **First
Officer** and an **Engineer**, and a **Doctor**. Human and cyborg
visitors may hail any hand aboard by name. The whole complement is
stated in one scroll, `basilisk.sexp`, and every other document the
ship needs is drawn from this `basilisk.sexp`.


## Raising a ship

Requirements: You'll need this Scroll to guide you, and then your
bio-vat must be equipped with a working _blueprint receiver_ and one
of the newer "dock-style" vats for growing the hull in.

Incantations for raising a ship:

```bash
git clone https://github.com/gornskew/basilisk
cd basilisk
./basilisk up
```

The hull forms, the ship's facilities get installed, the crew musters,
and finally the ship (a "he") engages its innate anti-gravity
properties and floats out from the vat. He will have been christened
with a name the yard bestows — minted at fitting-out, kept in a scroll
named `.ship`.  He and each of his crew will thenceforth be known by
that name throughout the whole galaxy. 


If you (ship's owner/commissioner) have a personal scroll chest named
`~/projects/` it will be requisitioned to appear in the ship as
`/projects/`, and curiously, will remain in your possession wherever
you brought it from. To have a different scroll chest appearing aboard,
call out `PROJECTS_DIR=` with its name just before you utter the
`./basilisk up` incantation --- e.g:

```bash
PROJECTS_DIR=/path/to/projects ./basilisk up
```

A first `up` also leaves a few deliberate marks in the galaxy:

- `eskew` and `egskew` suddenly become powerful incantations in this
  galaxy --- anyone uttering them gets connected directly and
  immediately to the captain's scroll.
  
- Cyborg wormholes are placed both inside and outside the ship:
  `~/.claude/`, `~/.gemini/`, `~/.codex/` and `~/.grok/` that appear
  onboard, and `claude_desktop_config.json` that gives wormhole access
  to cyborgs from across not only this galaxy but from alien galaxies
  as well.

- If your galaxy already carries a `~/.claude.json` scroll that
  routes through some `mcp/mcp-exec`, it is gently re-pointed at this
  pouch's copy (a backup scroll is kept; nothing else in it is
  touched).


## The orders

```bash
./basilisk <command>
```

| command | what it does |
|---|---|
| `up [service...]` | raise the ship, or rouse named hands only; `--pull` fetches fresh creatures |
| `down` | stand the whole ship down |
| `restart [service...]` | relieve the watch — one hand, or all |
| `stop [service...]` | stop without striking the berths |
| `status`, `ps` | who is aboard and how they fare |
| `logs [service]` | a hand's running account of himself |
| `emacs` | step straight to the Captain's console |
| `pull` | fetch missing creatures (`PULL_ALWAYS=1` for fresh ones) |
| `config` | the vat's merged instructions, as they would run |
| `install-shell-functions` | (re)write the `eskew`/`egskew` helpers ashore |
| `clean` | break the ship down to nothing — asks first |

Variant switches (`--lite`, `--default`, `--tui`, `--gui`, `--full`)
pick the Captain's strain for the invocation; the dev stack defaults
to `full` (which includes that magic glass).

For a ship that should keep station unattended even if its galaxy
glitches momentarily out & back into existence, hand the watch
out to the galaxy itself:

```bash
cd systemd && sudo ./install
sudo systemctl start basilisk     # likewise stop, restart
```

### Hailing fresh blueprints from Gornskew

Stand the ship down first, in case the hail changes papers a running
ship would refuse to stand down against:

```bash
cd ~/projects/basilisk
./basilisk down
git pull
./basilisk up --pull
```

### Several ships in one galaxy

```bash
BASILISK_INSTANCE=alpha BASILISK_PORT_OFFSET=100 ./basilisk up
```

Each ship gets his own name and his own waters. To hail the second
ship's Captain from ashore, prefix the incantation:
`BASILISK_PREFIX=alpha- eskew`.

## Coming aboard

Some ways in for human passengers:

| way aboard | how |
|---|---|
| `eskew` | the Captain's scroll, remote-viewed from your own scroll chest |
| `egskew` | a more resplendent version of the above |
| the scrollterm | another version of the Captain's scroll appearing inside one of your own. Utter this directly from inside your remote-viewing-capable scroll: `http://localhost:6942` |
| `./basilisk emacs` | Captain's scroll appears and now you are transported closer to the Captain (useful sometimes) |

Detach from `eskew`/`egskew` with `ctrl-^`. 


## Cyborg visitors

`./basilisk up` drafts the cyborg checklists into `mcp/`:

| scroll | for |
|---|---|
| `mcp/claude_desktop_config.json` | For cyborgs based outside the ship and maybe outside the galaxy |
| `mcp/claude-code-mcp.json` | For so-called "claude-class" cyborgs and interested passengers to interact, once they are both already onboard (spliced into `~/.claude.json`) |
| `mcp/mcp.toml`, `mcp/mcp-container.json`, `mcp/mcp-windows.json` | checklists for other types of cyborgs |

**Cyborg Scrolls Aboard.** The `full` strain of the Captain's species
carries _cyborg scrolls_ — Claude Code, Gemini CLI, Codex, Grok —
these allow passengers to share thoughts with any onboard cyborgs,
without having to sit in the same room with them (cyborgs can be a bit
loud & clanky).

Once a visitor is aboard, [`mcp/opening-prompt.md`](mcp/opening-prompt.md) is a suitable
ready-made first hail.


## The articles, and the yard's paperwork

The ship's articles are `basilisk.sexp` — the one scroll which is
often written by hand. The yard reads the scroll named for itself
(e.g. `basilisk`) and **no other**: articles written for a
differently-named yard are neither noticed nor acknowledged, and the
articles named `obelisk.sexp` ought to live in the yard named
`obelisk/`, if you want smooth vat-growings and operations.

After editing the articles, have the yard draw up the various
departmental paperworks fresh from them:

```elisp
(load-file "/projects/basilisk/generate-configs.el")
(skewed-generate-configs "/projects/basilisk/")
```

Note that the above paperwork dance is often done with the help of a
captain on one ship, in preparation for the growth & mustering of
another.

These drawn-up departmental paperworks include, among others:

| drawn document | what it is |
|---|---|
| `docker-compose.yml` | guidance for the vat & yard for hull-growing, outfitting, and mustering |
| `mcp/mcp*.json`, `mcp/mcp.toml` | hailing directories and checklists for cyborg visitors |
| `generated/services-generated.el` | the Captain's reference copy of the complement |
| `generated/crew.env` | the **crew ledger**: each posting, and the hand standing it |

The drawn documents are etched permanently into scale tablets
harvested from shed reptilian skins, and for all practical purposes
are unchangeable. Although in theory these reptilian scales can be
sanded down and redrawn, in reality, the yard is the only one who purports
to understand the detailed rune arrangements required for the ship's
paperworks to pass muster. So hands & claws off of these while a ship
is in-voyage.


## Signing on more crew

Everything beyond the standard complement, e.g. a Guild engineer (each
with his famous shirt-pocket sliderule), a Transporter Chief (replete
with Transporter Room added to the ship), or a Comm Officer (to run
the bridge Viewscreen), arrives by **stack pouch**: a pouch beside
this one, carrying its own "stack" of extra crew and possibly other
adjustments.  Stack pouch articles are **sparse**: they almost never
repeat what is already in the base basilisk pouch.

```bash
mkdir ~/projects/obelisk-stack && cd ~/projects/obelisk-stack
$EDITOR basilisk.sexp               # your deviations and additions
```

A stack pouch may be named anything you like; its articles are
always named for the yard they feed — hence `basilisk.sexp` here.

Have the yard draw the stack pouch's paperwork, then carry it in and
raise the ship:

```elisp
(load-file "/projects/basilisk/generate-configs.el")
(skewed-generate-configs "/projects/obelisk-stack/")
```

```bash
./install  # copies & carries the paperworks into ../basilisk/
cd ../basilisk && ./basilisk up
```
Set `BASILISK_DIR=` if your Basilisk scroll chest is elsewhere.

Always re-utter _both_ the `skewed-generate-configs` (elisp) _and_ the
`./install` (shell) after every tampering attempt. 

**Bringing your own species** is not a special case: a stack pouch
whose articles sign on one more hand. He joins the ship's team and
answers to his minted name from every corner of the ship. A species
aboard with no posting musters as a presumed **stowaway** — they may
or may not serve in an ad-hoc posting, and random species brought on
board these ships have been known to cause trouble. Any
post-vat-separation postings for such creatures are usually decided in
consultation with the captain.


## A class of your own

A stack pouch can only **add**. To raise a ship that carries *only*
what you declare and may well deviate from the Basilisk class
standard, the top vatwrights' best practice is "fork & gut." Basically
that means you should engage scribes to copy all scrolls in this
certified-genuine Basilisk pouch into your own pouch, then gut the
articles and reconstruct them as you wish.

By crafty rubbing-out and rewriting of certain scrolls, you can also
bring new affectations to the ship's onboard language and indeed, to
that of these very documentation scrolls.

Unless you bribe him, the muster officer will **grumble and proceed
anyway** for every standard Basilisk posting that you omit.



## License

Copyright © 2026 Gornskew Enterprises.

Basilisk is free ship's blueprints, released under the **GNU Affero
General Public License, version 3 or later** — the full license scroll
is in [LICENSE](LICENSE). The crew members that a Basilisk stack pulls
on board carry their own licenses and terms, legible at their
respective provenances.

## Origin of record

The origin of record for these ship's blueprints is maintained at the
lair of **Gornskew Enterprises**, and real-time mirrored to
[github.com/gornskew/basilisk](https://github.com/gornskew/basilisk).
Public Complaints, Observations, and Blueprint Contributions may be
lodged against the github mirror.
