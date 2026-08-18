# BASILISK

A _Basilisk_ is a craft based on a hull that is grown in a
_biological vat_. These hulls can be grown in many forms and sizes,
but the volkswagen or chevrolet of Basilisks is a standard rig with
enough facilities for a _Captain_, a _1st Officer_, a _Ship's
Engineer_, and a _Ship's Doctor_. These ships tend to engage in
various hosting and transit missions while floating in their
_galaxy_.

The ship's articles that list the specifics are written in one place
and one place only: the `basilisk.sexp` scroll that you will find in
the same courier pouch as this overview scroll. From that scroll, the
requirements flow into all the vat's nutritional juices.

So `basilisk.sexp` is your order requisition for a fully crewed space
vessel. With it, and with a bio-vat nearby, merely by uttering the
incantation `./basilisk up`, a hull will immediately begin to form in
the vat. Once it is fully grown, the Shipyard will arrange recruiting
a complement of officers for the shiny new outfitted hull. Then he
will float out of his berth into his _galaxy_ — a he, as Basilisks
run male so far as anyone can tell, under a name the Shipyard bestows
at fitting-out. That name is the one his whole galaxy hails him by.


## The articles in basilisk.sexp

Every hand aboard is listed in the articles, and only one thing must
be stated about each: the **species**. Everything else can be
derived.

- A hand posted to duty answers to the posts he stands — all of them,
  run together, which is how a name like `engr-comms` comes
  about. State a `:name` only to overrule the derivation.
- A species aboard with **no posting** is a **stowaway**: comprehended,
  fed, and entered on the muster as `stowaway-<species>` — aboard, and
  assigned to nothing.

The articles are sparse on purpose: state what deviates, and inherit
the rest from traditional values. 


## Postings and species

A **posting** relates to what a hand is _for_; a **species** relates
to what his or her or its _form is_ and what, purportedly, he or she
or it is _skilled at doing_.

Each posting lists its required qualifications in the `:postings`
table of the articles scroll. Each species carries its capabilities in
its own papers, which travel with the creature — the Shipyard keeps no
register of species and never adjudicates whether a creature qualifies
as one. Where a creature hails from is **provenance**: a home planet
guarantees nothing about what a creature is, so _genworks/gendl_ and
_blorg/gendl_ are presenting as the same species from different
worlds. Species can also come in specific _strains_. 

At muster, each hand's papers are read against the qualifications of
every post he or she or it is to stand. A hand who cannot show a
required qualification draws a grumble — and the muster proceeds. That
is the price of an open muster, paid knowingly: a mis-posted hand
causes no grounding or even delay, just the grumble, because an
ability can potentially be acquired aboard by arrangement & learning,
which no papers can show in advance.


## The crew

- The **Captain** sits at the Conn, and for now also navigates and
  pilots the vehicle.

- The **1st Officer** stays on the bridge and assists the Captain and
  the ship's visitors with technical matters. The 1st Officer is
  responsible for bridge technical issues as well as entertaining
  guests.

- The **Ship's Engineer** stays in Engineering and takes care of
  engineering activities, both for the whole ship and for visiting
  passengers — who are often trying to design or improve their own
  ships. 

- The **Ship's Doctor** watches for the sickly and the unproductive,
  and revives or dispatches them. Patient, detached, and completely
  unphased by death.


## Signing on more crew

A pouch beside this one — whose name ending in `-stack`, one pouch per
new ship config or design.  Place a scroll into this pouch with your
adjustments or additional crew requirements, then whisper `./install`
and your nearby `basilisk/` pouch will get the memo, so the next time
you vibrate the `./basilisk up` mantra, you will get one of your newly
dreamt up custom ships, with crew.


