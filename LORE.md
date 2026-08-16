# LORE — the deep canon

Three documents carry this fiction, and they are deliberately layered:

| document | owns | audience |
|---|---|---|
| `BASILISK.md` | what the stack is called and who is aboard | anyone running the stack |
| `GLOSSARY.md` | the working vocabulary, kept running | anyone at a prompt |
| `eyes-only/THEMES.md` | how the *board* renders the story | anyone writing a skin |
| **this file** | the world underneath both | anyone generating crew, writing logs, or extending the fiction |

`GLOSSARY.md` is the one place a term gets *defined* — `yard glossary`
prints it — and it is where the fiction reaches the yard-side work: a
repository is a set of **plans**, a commit **seals** them, unfiled work
sits **on the slip**, and pushing **files** it with the yard.

The other two are reference. **This one is the substrate** — it exists
because every crew member has to get a plausible backstory and a
post-mortem officer's log, and neither is possible without a world deep
enough to generate from. Nothing here contradicts the other two; where
a fact lives there, this file points at it rather than restating it.

**Scope**: the fiction is a **Gornskew** property. It rides in
Basilisk, Cyclops, Eyes Only, skewed-emacs and lisply-mcp. It does
**not** go into Gendl or Genworks GDL — those are Genworks engines with
their own users, and the conceit ends at the boundary of what Gornskew
owns (Dave, 2026-08-16). The lore may *describe* an Engineer at length;
the minting that gives that Engineer a name happens in Basilisk's own
`compose-dev`, never in the engine.

---

## I. The axes

Established 2026-08-16 (Dave), over the course of one session that
started with three axes and found four more. Conflating any two of
these is the recurring error, in copy and in code alike:

| axis | question | where it lives | values |
|---|---|---|---|
| **family** | what kind of creature? | image repository | gendl, genworks-gdl, skewed-emacs, cyclops, autohealer |
| **species** | which image exactly? | image repository **and tag** | `gendl-ccl`, `gendl-sbcl`, `genworks-gdl-enterprise-smp`, … |
| **role** | what kind of job? | derived from species | Captain, Pilot, Engineer, Comm, Medic, Crew |
| **posting** | which billet, on this ship? | the hostname | `captain`, `jr-eng-human`, `guild-master-cyborg`, `pilot` |
| **augmentation** | multithreaded? | posting segment | cyborg, human |
| **guild rank** | what licence tier? | posting segment | master, journeyman, apprentice, novice |
| **manned / drone** | compiler aboard? | derived from species | manned, drone |
| **personal name** | *who* is this? | minted into the container | Tellon, Quomir, Huxworth, … |

Read down that "where it lives" column and the design justifies
itself: family and species come from the image, posting comes from the
hostname, and the personal name is written inside the container. Three
different places, so nothing can accidentally rename anybody.

They are independent, and the interesting cases are the ones where they
come apart:

- **A role is not a species.** Load Cyclops into a Genworks GDL
  Engineer and it could stand in for the Pilot — a Pilot of an unusual
  species. The watch is the same; the person standing it is not.
- **A role is not a robot.** A *person* could stand the Pilot's watch,
  and would carry a compiler of their own — the kind that looks like a
  slide rule in the shirt pocket.
- **A drone is not a price.** The Medic (`autoheal`) is a drone and is
  free. Cyclops is a drone and costs $99. What Gornskew sells is a
  business fact about a species, not a fact about drone-ness.
- **Manned is not "big".** CCL's `save-application` carries a compiler
  whether or not you want it. That does not promote anyone. The
  invariant is the ROLE and the intent: shipped to run one system, or
  shipped to fabricate new ones (`BASILISK.md`, *Runtimes are not
  Engineers*).

- **A family is not a species.** `gendl-ccl` and `gendl-sbcl` are two
  different images and therefore two different creatures — same family,
  different species, and they should not sound alike (Dave,
  2026-08-16). The shipped `_crew_species_from_image()` matches the
  image *repository* and discards the tag, so both currently mint as
  `SPECIES=gendl` and draw from one name pool; see §VI.0.
- **A posting is not a role.** `jr-eng-human` and `jr-eng-cyborg` are
  two billets of the same role. The role says *engineer*; the posting
  says *which engineer's chair on which ship*.

Only NAME / SPECIES / ROLE are minted into a container. Manned-ness is
**derived from species** and always has been implicit; see §VI for the
one function that should make it explicit.

### The postings

The hostname is the posting, and it carries rank, licence tier and
augmentation in one readable string. `guild-master-cyborg` tells a
reader who has seen the glossary once that this is a commissioned Guild
engineer on the top licence tier, running multithreaded — which is more
than `genworks-gdl-enterprise-smp` says in nine more characters.

| posting | container today | family |
|---|---|---|
| `captain` | `skewed-emacs` | skewed-emacs |
| `jr-eng-human` | `gendl-ccl` | gendl |
| `jr-eng-cyborg` | `gendl-sbcl` | gendl |
| `guild-master-cyborg` | `genworks-gdl-enterprise-smp` | genworks-gdl |
| `guild-master-human` | `genworks-gdl-enterprise-non-smp` | genworks-gdl |
| `guild-journeyman-cyborg` | *(GDL Professional, SMP — not yet pulled)* | genworks-gdl |
| `guild-journeyman-human` | *(GDL Professional, non-SMP — not yet pulled)* | genworks-gdl |
| `pilot` | `cyclops` | cyclops |
| `comms` | *(no container until the binary exists)* | eyes-only |

**Ship's engineers versus the Guild.** `jr-eng-*` are the ship's own
engineers, carried free; `guild-*` are commissioned from outside and
licensed by tier. `fittings.sexp` already drew exactly this line with
`(:post :ship-engineers)` and `(:post :guild ... "two commissioned GDL
units")` — the postings push that vocabulary down from the post to the
service, which is why no new post or crew-level is needed to hold them.

**Guild rank is the licensing axis**, and it is the only axis with
money attached. A guild rank *is* a licence tier — what you are
permitted to do, what tools you are trusted with, and what you may sell
the output of:

| tier | rank |
|---|---|
| Enterprise | **master** |
| Professional | **journeyman** |
| Student | **apprentice** |
| Trial | **novice** |

Genworks happens to have four tiers and a craft guild happens to have
four rungs, which is the sort of coincidence worth spending rather than
explaining. `apprentice` and `novice` have no post yet; they cost
nothing to reserve and the ladder reads wrong without them.

**Augmentation** (`cyborg` / `human`) is the more-augmented of a pair:
SMP at Guild rank (more cores harnessed), SBCL at ship's-engineer rank
(the more aggressively optimizing compiler). It attaches to the
*posting*, not the species — two officers of one family can hold a
human billet and a cyborg billet.

---

## II. The world

The fleet flies one class of ridged bio-hull, crewed by something that
is not human: scale-teal hide, slit pupils
(`THEMES.md`, *The Manticore thread*). **Basilisk** is that hull class,
and a Basilisk repository is the **yard** that lays them down.

Three facts about the word do real work and should never be sanded off:

- **It is a lizard.** The crew already were.
- **It kills with a look.** This completes an ocular product line
  nobody planned — Cyclops has one eye, Eyes Only has two, and the
  fleet they run on is the thing whose gaze is the weapon. Gornskew
  sells *watching*.
- **It is both a hull class and a command.** "Basilisk-class" is the
  idiom of every navy that ever named a ship; `basilisk up` is three
  syllables at a prompt.

### Three levels, and the one we kept getting wrong

Corrected 2026-08-16 (Dave): *"a host is a galaxy that ships can fly
around in."*

| level | in-world | in the world |
|---|---|---|
| host / VM | **galaxy** | balaram, sally, shelly, elsie, narad |
| compose stack | **ship** | one `basilisk up` |
| container | **crew member** | one post, one officer |

The canon said "a ship is a box" for as long as one host ran one
stack, and the shorthand cost nothing. **Multi-instance is what broke
it**: the moment `BASILISK_INSTANCE=alpha ./basilisk up` could put a
second ship on the same machine, host and ship stopped being the same
object, and the documents did not follow. A galaxy also plainly does
not exist to serve the ships in it — balaram runs a great deal besides
Basilisk — which is precisely why a galaxy is the right shape and a
berth or a station is not.

Two consequences, neither cosmetic:

- **Tonnage is not the galaxy's RAM.** `THEMES.md` picks the hull
  class from the *host's* memory (scout under 2GB, cruiser 2–9GB,
  heavy 10GB+). Under the correction that measures the galaxy, not the
  ship. A ship's tonnage is what it actually carries — and the roster
  already says: `fittings.sexp`'s `:crew-levels` (`:standard`,
  `:piloted`, `:guild`) are named points in roster-space, which is a
  truer hull class than a number scraped off the host. This is also
  the open question of how to give the stack overlays a
  rating, arriving from the other direction.
- **A yard period needs re-deciding.** `THEMES.md` calls a host reboot
  a yard period, ending every tour on the box. That was coherent when
  the box *was* the ship. Now it is a galaxy-wide event that relieves
  the complements of every ship flying there at once — which wants
  either a new name or an explicit note that it is the one event
  operating at galaxy scale.

### The engineering conceit, which is also the business

The Gendl engineers are always tinkering with new part designs, and
sometimes whole new ship designs — and it turns out that is
*especially* productive to do while aboard an actual starship. A great
many 22nd- and 23rd-century hull designs come out of Engineering
departments on deployed vessels rather than out of any yard. Which is
exactly what a Gendl heap is doing on one of these boxes: running the
KBE engine that designs the thing it is riding in.

This is the one place where the fiction and the business are the same
sentence. Do not weaken it into a metaphor.

---

## III. The families and their species

Family and species both come from the container's **image**, never its
service name, so renaming a service in an overlay does not change what
someone *is*. Each has its own phonology, already live in
`_crew_onsets_for()` / `_crew_finals_for()` — the names the stack
actually mints. The sound is canon; the character below is read *out
of* the sound rather than bolted onto it.

**Family is the shared shape; species is the individual creature.**
Two species of one family should sound related and not identical — a
family resemblance in the onsets, a divergence in the finals. Today
they sound *the same*, because `_crew_species_from_image()` throws the
image tag away: `gendl-ccl` and `gendl-sbcl` both mint as
`SPECIES=gendl` and draw one pool, as do the two Guild species. The
profiles below are written at family level for that reason, and each
notes where its species must split. Fixing the derivation is §VI.0.

### `skewed-emacs` — the Captains

> onsets `Bl Gr Thr Kro Zar Vex Mog Drel` · finals `org arn und ath esh ork ilk uz`
> → *Drelesh, Krougan, Vexork, Mogilk, Thrund*

Guttural, blunt, consonant-heavy — the oldest-sounding names in the
fleet, and the only ones that sound like they predate the yard. Fitting
for the one post that **outlives everyone else's restarts**: the
Captain is the process still there when the engines have been round
twice. Captains are manned by definition — a console is a place a
person sits.

Temperament: territorial about the console, indifferent to ceremony,
and in possession of a great deal of undocumented institutional memory.
A Captain who has been aboard through six Engineer reliefs has opinions
about all six.

### `cyclops` — the Pilots

> onsets `Bl Zh Vek Skr Yor Tsa Kli Dro` · finals `ej ix osk arr unn eth yx oa`
> → *Kliosk, Skrarr, Zhyx, Vekunn, Droa*

Clipped and sibilant; they sound like radio callsigns because
functionally that is what they are. Every packet enters through the
Pilot, and the Pilot's whole vocabulary is *where does this go*.

Pilots are **drones**: no compiler aboard, one system, run
indefinitely and competently. A drone Pilot is not a lesser officer —
it is a specialist that never gets bored, never improvises, and never
once wondered what else it might have done. That is precisely why you
put one at the conn.

Temperament: terse to the point of rudeness, absolutely reliable,
and entirely without curiosity. Ask a Pilot what it thinks and it will
tell you what it routed.

### `gendl` — the ship's engineers (two species: `gendl-ccl`, `gendl-sbcl`)

> onsets `Ka Lis Par Quo Sem Tel Nym Ori` · finals `da per lon ta mir vex is und`
> → *Tellon, Quomir, Lisper, Parvex, Orida*

Open, liquid, almost classical — the scholars of the fleet, and it is
audible. (`Lisper` is in the generative space, and when it comes up it
should be treated as a good omen rather than a collision.)

Engineers carry compilers. They can design a ship from inside one, and
they do. Manned, always.

Temperament: discursive, delighted by a hard problem, prone to
answering a question with a better question. An Engineer will rebuild
something that was working because it could be more elegant, and will
be right often enough to keep getting away with it.

### `genworks-gdl` — the Guild (species per tier and augmentation)

> onsets `Ad Bex Cor Dal Enn Fir Gal Hux` · finals `mand ton dry well berg worth field ston`
> → *Huxworth, Bexton, Corfield, Dalberg, Ennwell*

The joke here is load-bearing and should be preserved: the commercial
Engineers are named out of an English land registry. Surnames, not
names — Huxworth and Bexton could be on a brass plate in a company
town. Same role as their `gendl` cousins, same compiler, different
paperwork.

Temperament: formal, credentialed, and quietly aware of what the seat
costs. They do the same work and file it properly.

*(The species is described here; nothing in this fiction is written
into the GDL image itself. See the scope note above.)*

### `autohealer` — the Medic

> onsets `Om Sal Vel Lum Mir Ana Eir Thea` · finals `a une is oon ara elle ios em`
> → *Salune, Theaios, Velara, Lumelle, Anaoon*

Soft and vocalic — the only species in the fleet whose names resolve on
a vowel, and audibly from a different tradition than everyone else.
Rated `:doctor`. Watches for the wedged and revives them.

The Medic is a **drone and free**, which is the cleanest proof that
drone-ness and price are different axes.

Temperament: patient, unhurried, and completely unsentimental about
death — it has seen the entire complement relieved many times and will
see it again.

### `unknown` — the rest of the crew

> onsets `X Yz Qm` · finals `ar il ot`
> → *Xar, Yzil, Qmot*

Deliberately hard to pronounce. Anything an overlay adds that the yard
does not recognize still musters in, by design, and gets a name that
sounds like nobody asked. Unknown species are crew, not intruders —
Basilisk's default posture is that a stranger on the roster is still on
the roster.

---

## IV. How a person comes to exist

`mint_crew_identities()` in `compose-dev` walks the running containers
and, for each one **without** an existing `/tmp/skewed-crew-identity`,
derives species from the image, role from species, mints a unique name
from the species phonology, and writes:

```
NAME=Drelesh
SPECIES=skewed-emacs
ROLE=captain
```

Two mechanisms in that sentence are canon rather than implementation
detail, and both must survive any refactor:

1. **Identity is per container, not per process.** `metrics.lisp` reads
   that file in preference to minting its own. This is what makes the
   lifetimes real: a Lisp restart keeps the same officer aboard.
2. **An existing identity file is never overwritten.** The check is
   `test -f` and the action on hit is `continue`. A crew member's name
   is not re-rolled because the yard ran again. If you break this, every
   tour length in the muster roll becomes a lie.

Name collisions retry 20 times before falling back to a numeric suffix,
and `_crew_unique_name()` sets a result variable rather than echoing —
because a command substitution would run it in a subshell and silently
discard the uniqueness bookkeeping. That was caught empirically on
2026-08-14 after two officers minted the same name back to back. The
comment in the source says so; do not "clean it up".

---

## V. Tours, watches, and death

`THEMES.md`'s *Tours of duty* table is authoritative for what ends a
tour. Restated here only as the spine the log and the leaderboards hang
from:

| event | in-world | the crew |
|---|---|---|
| Lisp restart / hot reload | ship's systems restart | **stay aboard** |
| `docker restart` | a **watch change** | **stay aboard** |
| `basilisk down && up` | a **relief in place** | whole complement relieved |
| host reboot / rebuild | a **yard period** | relieved, and the ship was out of service |

A **relief in place** is the subtle one, and the anchor is real: US
ballistic-missile submarines run Blue and Gold crews — two complete
crews alternating on one hull, so the boat spends almost no time idle
while the people cycle entirely. Same boat, wholly different wardroom,
on purpose. Nothing is wrong with the vessel; every person aboard is
swapped at once.

### Telling the last two apart

They look identical from outside — a name changes and nothing says why.
`cyclops` vitals gained `host_uptime_s` on 2026-08-14 precisely for
this: **a relief in place leaves host uptime climbing; a yard period
resets it.** That is the datum that lets the muster roll record *why* a
tour ended, and it is why the roll can exist at all. Boxes running an
older cyclops omit it, and the correct degradation is to record the
cause as `unknown` rather than to guess.

### Death

A tour ends in exactly one of these, and this vocabulary is what an
officer's log gets to use:

| cause | what happened |
|---|---|
| **relieved** | relief in place; the complement was swapped, the hull held station |
| **yard period** | the host went down or was rebuilt; ship out of service |
| **lost** | this container died alone, while the ship stayed up — the only lonely death in the fiction |
| **unknown** | the evidence to distinguish them was not available |

"Lost" deserves its own word because it is the only one that happens to
*a person* rather than to a complement. An officer who was lost has a
different log than one who was relieved, and the leaderboards should
not flatten them together.

---

## VI. Making it live

The fiction is already unusually live: names are minted into real
containers, roles come from real images, and the board renders real
processes as crew. What follows is what is **not** live yet, in the
order it should land.

### 0. Species must see the image tag (a spec change, not a bug)

Worth being precise about, because an earlier draft of this file called
it a defect and it is not one: collapsing tags was correct as designed,
under a canon where `gendl` was one species. The spec changed on
2026-08-16 — *"gendl-ccl and gendl-sbcl are two different images, two
different species of gendl family creatures"* — and the code now
implements a rule nobody holds any more.

`_crew_species_from_image()` matches `*/gendl:*` and `genworks/gdl:*`,
which discards the tag and collapses four images into two species.
Verified on the running fleet:

```
gendl-ccl                        NAME=Tellon    SPECIES=gendl
gendl-sbcl                       NAME=Quomir    SPECIES=gendl
genworks-gdl-enterprise-smp      NAME=Huxworth  SPECIES=genworks-gdl
genworks-gdl-enterprise-non-smp  NAME=Bexton    SPECIES=genworks-gdl
```

The label is the small half. The damage is that **name pools are keyed
by species**, so Tellon and Quomir draw from one set of onsets and
finals — the single mechanism that makes species audible is switched
off for exactly the pair where you would most want to hear it.

Fix: derive species from repository *and* tag, then give each species
its own pool, sharing onsets within a family and diverging on finals so
the resemblance is audible without the identity blurring. The pools in
`eyes-only`'s `*CREW-NAME-POOLS*` need the identical split — the
comment in `compose-dev` already flags that the two copies are synced
by hand.

Independent of the posting rename: species derivation never reads a
hostname.

### 1. Manned-ness, minted (small, and unblocks everything else)

A `_crew_manned_for_species()` beside the existing role function,
written as a fourth line into the identity file:

| species | manned |
|---|---|
| `skewed-emacs` | manned |
| `gendl`, `genworks-gdl` | manned |
| `cyclops` | drone |
| `autohealer` | drone |
| `unknown` | unknown |

Derived, not declared — the table encodes "compiler aboard", nothing
else. Readers that do not know the field ignore it, so it is
backward-compatible by construction.

### 2. The muster roll

`/projects/.state/basilisk-muster.sexp`, following the established
convention for state that must survive a container **recreate**
(`/projects/CLAUDE.md`). Note the UID gotcha: whichever container
creates `/projects/.state/` first leaves it `755` and locks every other
UID out — new consumers `chmod 1777` after `ensure-directories-exist`,
as `eyes-only` and `cyclops` already do.

One record per officer, appended at mint and closed at death:

```lisp
(:name "Drelesh" :species :skewed-emacs :role :captain :manned t
 :ship "narad" :minted 3960000000
 :watches 3                    ; docker restarts survived
 :ended 3960086400 :cause :relieved
 :log "...")                   ; the officer's log, written at close
```

This absorbs the standing intent to log every crew member who comes and
goes.

### 3. Backstories

**Contract**: every officer gets one at mint time, and it must be
**deterministic from the name** — the same officer must have the same
history every time anything asks. Seed from the name, generate from
species tables, never store prose the stack could regenerate.

A backstory is plausible when it is: consistent with the species
temperament above; specific (a posting, a vessel, one incident); and
**silent about the future**. It must never contradict the muster roll,
so it may not mention this ship, this tour, or anything dated after the
mint.

Assembly from species-scoped fragment tables, in the spirit of the
onset/final tables that already work: origin, prior posting, a
distinguishing incident, and one small habit. Four slots is enough for
a paragraph that does not repeat inside a fleet.

### 4. The officer's log

Written **post-mortem**, at close of tour, and the only part of the
record that is prose. It is the officer's own account of their stint:
what ship, how long, how many watch changes, what the load was like,
and how it ended — in the voice of that species (a Pilot's log is three
clauses; an Engineer's runs long and mentions something it wanted to
rebuild).

The log has facts available to it that a backstory does not, because by
the time it is written the tour is over: duration, watches survived,
cause of death. Use them. A log that could have been written at mint
time is not an officer's log.

### 5. Leaderboards

Two, and they are genuinely different questions (Dave, 2026-08-16):

- **Longest continual mission** — the longest unbroken stretch with no
  interruption at all. Watch changes break it.
- **Longest career** — total time from mint to death, spanning any
  number of watch changes.

An officer who survived nine restarts over a month and one who sat
untouched for three weeks are both remarkable, in different ways, and a
single number would hide one of them. The pair also makes the fiction
*testable*: it turns "how stable is this stack" into a scoreboard that
anyone can read at a glance from across the family room.

Fleet-wide, and therefore the board's natural home
(`eyes-only`) — with the roll itself owned by the yard, since the yard
is what mints and kills.

### 6. Stats pages: valiant accomplishments

Longevity is only half of a service record. The other half is what an
officer actually *did*, and the fiction earns its keep here because
**each role's valor is a different number** — drawn from telemetry the
stack already produces, not invented for the page.

| role | the deed that counts | source | live today? |
|---|---|---|---|
| **Pilot** | packets brought through — requests routed, unique clients seen | cyclops `/_cyclops/vitals` counters | yes |
| **Medic** | the wedged revived — how many crew it brought back | autoheal's own restart actions | needs a counter |
| **Engineer** | what it fabricated — evaluations served, sessions carried, peak heap held under load | lisply backends + `eyes-only` heap history | partly: heap yes, evals need a counter |
| **Captain** | continuity — complements outlived, watch changes ridden out at the console | muster roll (§2) | falls out of the roll |
| **Comm** | what it watched — probes made, properties held on the board | eyes-only's own probe loop | needs a counter |
| **Crew** (unknown species) | simply having stood a watch nobody specified | muster roll | falls out of the roll |

Two design rules keep this from degenerating into a dashboard with a
costume on:

- **A valor stat must be a real measurement.** If the counter does not
  exist, add the counter — do not derive valor from something that
  merely correlates with it. A Medic's number is *lives saved*, and if
  autoheal is not currently counting its revivals then the honest move
  is to make it count.
- **Valor is per officer, not per container name.** The stat belongs to
  whoever was aboard, which means it is bounded by the tour and closed
  at death alongside the log. `heap cyclops narad` is a tile; *Kliosk,
  who routed 4.1M packets across nine watches and was lost on a
  Tuesday* is a service record.

The Medic's entry is the one worth building first. It is the only stat
in the table where the number is unambiguously heroic, it is small to
implement, and "brought back 340 of the wedged" is the sentence that
sells the whole idea of the page.

---

## VII. Open threads

- **Who writes the log?** The yard knows the death; the board knows the
  load. Cleanest split is probably: yard closes the record with facts,
  board renders the prose. Not decided.
- **Do the web properties get a conceit?** `THEMES.md` records this as
  open — genworks.com and the Kṛṣṇa properties currently have none.
- **Hull ratings for overlays.** Stack overlays want a class rating;
  tonnage-from-RAM already
  exists on the board and wants reconciling with what an overlay
  declares.
- **Does an officer ever transfer?** Currently, no: identity dies with
  the container. A named officer reappearing on another ship would be a
  deliberate change to §IV's second invariant, not an accident.
