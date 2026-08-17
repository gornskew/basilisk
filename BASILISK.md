# BASILISK


## A Class of Space Vessel

A Basilisk is a class of ridged bio-hull inter-stellar (not
inter-galactic) space vessel, fabricated in various tonnages.
`basilisk up ...` is the general replicator recipe for
bio-replicator-fabricating, outfitting, and mustering these ridged
hulls.

Other terminology the lore may bring into play now or later: `muster`
(the crew log), `roster` (the server-side crew table), `watch` (a
`docker restart`), `yard` (a host reboot), `relief` and `tour` (what a
recreate does to a complement). Freeze-dry or Cryogenically preserved
Corpses which may be reänimated (dumped lisp images). And so on. 


## Who and/or What Is Typically Aboard These Vessels


| post | in-world |
|---|---|
| **Captain** | has the conn; and is the ship's console, the one process that outlives the others' restarts |
| **Transporter Chief** | everything and everyone coming aboard transports in through their room, and is vetted there before reaching the ship proper |
| **Engineers** | the KBE engines — designing ships from aboard one |
| **Comm** | the Communications Officer: runs the board any ship can project on its bridge viewscreen or other display |
| **Medic** | rated `:doctor`; so-called "healer" that watches for the wedged and revives or dispatches them |
| **Crew** | anything else an overlay adds — unknown species still muster in, by design |

> The Transporter Chief's posting is still spelled `pilot` in
> `services.sexp`, the generated compose, and everything downstream of
> them. The lore settled first and the configs follow; renaming a
> posting and renaming a live container are two different jobs, and
> only the first one is done.

### The conn, the helm, and navigation

The **Captain has the conn** — authority over where the ship goes,
exercised by writing the standing orders the rest of the ship then
flies by. Nothing else aboard holds it.

The **helm** — flying those orders — currently goes **unattended**, and
the conn absorbs the piloting. **Navigation** is a separate thing from
both, and the seat is **vacant**; it is not part of the conn and should
not be quietly folded into it.

So a default ship carries no **Pilot**. That posting is kept here
prospectively: if a species and a duty turn up that genuinely want a
Pilot's watch, the seat is ready for them. A ship augmented with a
Cyclops puts it on Transporter Chief duty instead, which is what it is
actually good at — a reverse proxy **receives**. It never goes
anywhere, and "Pilot at the helm" described an outbound act the
software does not perform.

None of which fixes a hull in place. A ship may make for another galaxy
at **impulse**, standing down here and mustering there; or it may be
carried through a wormhole at **warp**, which is the same journey made
without ever standing down. And a **galaxy** may itself get under way —
the machine relocated, or the VM live-migrated across a network — in
which case every ship aboard travels and not one of them has transited.
All of it is reserved. None of it is routine.


### What the Transporter Chief is for

The Chief's job is **not security**. It is knowing who is who and what
is what. The departments are bad at that precisely because they are
busy doing their own work. Security is a separate role, and the Chief
has security officers under him.

Without a Chief aboard, visitors still get in — each department simply
keeps its own mini-transporter and takes them unscreened, straight
into Engineering, or in to see the Captain.

Anything non-biological that clears the transporter room goes on to
the **Captain** for a second vetting, who either receives it personally
or hands it off to an Engineer, ship's or Guild.


## What a Ship Carries

A Basilisk picks up, processes, and delivers. Everything arriving
reconstitutes on the transporter pad as one of four things:

| aboard | what it is |
|---|---|
| **materials** | raw stock, brought aboard to be worked on |
| **goods** | processed or manufactured: the finished thing, or an ingredient for the next one |
| **services** | work performed rather than cargo handed over — the Engineer does the thing, and what leaves is the result |
| **passengers** | personnel: **cyborg** ones arriving from outside, **biological** ones grown aboard for the occasion |

Nothing arrives whole. Each thing that crosses the pad, inbound or
outbound, is a **part** — of some goods, of some materials, or of some
passenger — and what reconstitutes is the assembled whole, never the
part on its own. Services are the odd one out of the four, being
performed rather than carried: what comes and goes around a service is
still goods and materials.

A **consignment** comes aboard, may be routed to ship's or Guild
engineering for processing or as an ingredient, and something else
gets delivered elsewhere. The ship navigates **to** each consignment:
it travels to the source, rather than waiting for the consignment to
travel to it.

Passengers come in both kinds, and **both pass the Captain's watch**. A
**cyborg** passenger arrives from outside with business to transact,
clears the transporter room, and is received by the Captain — who
either deals with it personally or walks it down to an Engineer. A
**biological** one does not arrive at all: the Captain **invites** it,
and it is grown for the occasion, brought into being to carry someone
through what they came for and stood down afterwards.

Which is why passengers are load-bearing rather than ornamental: an
arriving passenger really can cause new crew to be constructed, and can
just as well be the thing that gets constructed.

The stock itself comes aboard the same way. An **image** arrives from
its home planet as materials — reconstituted from its parts on the pad
like anything else — and what gets grown from those materials may be a
new crew member, or a passenger that lives only as long as the business
it came for. A ship can take delivery of the means to make its own
complement, and then make it, without ever putting in anywhere.

Note what is _not_ aboard: livestock. Every noun in this lore has
something on the other side of the veil, and a detail that maps onto
nothing is decoration.


## Which _Species_ typically fills each _Posting_? 

- **Captains** are almost exclusively from a sometimes horrifying,
  sometimes friendly and gentle, Gnu-Human hybrid presenting species
  called _skewed-emacs_.

- **Transporter Chiefs** tend to be of the _cyclops_ drone species.

- **Comms** tend to be of the _eyes-only_ drone species. Local ship's
  engineers are usually junior engineers of some gendl variety (human
  or cyborg).



