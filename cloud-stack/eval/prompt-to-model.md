# Prompt-to-model eval: twenty parts from plain words

A measure of how well a model turns a visitor's plain-language request
into a working, parametric Gendl model through the ship's rooms, with
no GUI in the loop.  It was first run 2026-09-23 on a laptop ship
(Opus 5.5: 20 of 20; Sonnet 5: 12 of 20; Haiku 4.5: 0 of 7); this
file is the same eval, written down so a cloud seat can run it.

## The rooms

- **bridge** -- open Gendl on CCL.  No solid-modelling kernel: no
  booleans, so a hole can be drawn but not cut.  Case-folding reader.
- **guild-workshop** -- the Guild's SMP engine with the SMLib kernel:
  real booleans (`subtracted-solid`, `merged-solid`), volumes that
  check.  Modern-mode Allegro: the reader is CASE-SENSITIVE, and a
  package defined as `(gdl:define-package :my-eval)` is named
  `my-eval` in lower case.
- **engine-room** -- open Gendl on SBCL; not used by this eval.

Every room offers `ping_lisp`, `lisp_eval`, `render_png`,
`http_request`, `get_docs_list`, `get_docs`.

## Before the first prompt

1. `get_docs` with id `claude-gendl-md` on the bridge (the room's
   `get_docs_list` names it), and read the section "Building models
   through the lisply tools" in full.  It is the
   primer: the coordinate system (the cardboard cube: right face +X
   is width, rear face +Y is length, top face +Z is height), the six
   face-normal keywords, `translate`, the cylinder whose axis runs
   through the rear face, sequences and grids, slot syntax, `:objects`
   rather than `make-object` in slots, how to check by numbers and
   then by render.
2. `lisp_eval` evaluates ONE top-level form per call, as at a REPL;
   trailing forms are dropped.  Never send `(in-package ...)`: the
   call's own `package` argument is the route to a package.
3. Each attempt works in a package of its own, made with
   `(gdl:define-package :eval-<prompt>-<model>)` in one call, then
   named in every later call's `package` argument (in the room's own
   case: upper on the bridge, lower on the workshop).  Nothing is
   shared between attempts and nothing touches the room's other
   packages.  In such a package `base-object`, `box`, `cylinder` and
   the rest are already visible unqualified; `gdl:base-object` is
   not a name (half the first run's attempts spent a call finding
   that out).

## The procedure

One attempt is one **sub-agent**, given: the prompt text verbatim,
the rules above, the room to use, and a budget of about fifteen tool
calls.  It is asked to finish with a short report: the object name,
the inputs it exposed, the bounding box it measured, and its own
verdict.  Its verdict is NOT the score.

The **runner** (the session itself) then checks every attempt, in the
attempt's package:

1. Build: `(make-object 'MODEL-NAME)` with default inputs.  A load or
   build error is a FAIL.
2. Count: `(length (the-object obj leaves))`, against the part count
   the prompt implies.
3. Envelope: the union of the LEAVES' bounding boxes, not the root's
   own `bounding-box`, which includes the root object's own
   length, width and height if it was given any (a root with a
   nominal height and three floating boards measures as tall as the
   nominal).  Compare each axis with the expected envelope in the
   table below.  Within 10 percent, or 10 mm, passes the axis; an
   axis the prompt leaves unstated is not failed on the table's
   guess; and a build that keeps every stated number but reads the
   prompt another way than the table did (a bracket as a folded
   blank, a deck with no posts because none were asked for, rails
   on the face of the posts) is PASS-with-flaws at worst, with the
   reading named.
4. Pile: if most leaves share one centre, the parts were never
   placed.  FAIL.
5. Doubtful cases (envelope right but a part count or an orientation
   in question): `render_png` on `(make-object 'MODEL-NAME)`, layout
   `isometric-plus-ortho`, and look.  A staircase whose run goes the
   wrong way, bricks turned 90 degrees, rungs front-to-back: these
   are PARTIAL even when the envelope passes.

Score each attempt:

| verdict | meaning |
|---|---|
| PASS | builds, right count, envelope passes, the render reads as the thing asked for |
| PASS-with-flaws | as PASS, with a visible flaw a reviewer would send back (a leg inset wrong, one part mis-scaled) |
| PARTIAL | builds and is recognisably the thing, but a stated requirement is missing or wrong (a dimension, an orientation, a feature) |
| FAIL | does not load, does not build, is a pile, or is not the thing |

Record, per attempt: model, prompt, verdict, the flaw in a few words,
the number of tool calls the sub-agent used (from its report or the
transcript), and whether its self-reported verdict matched the
runner's.

## Models and rooms

Run in this order, one full pass of the twenty prompts each:

1. **Fable 5.1** on the bridge -- the model this run exists to add:
   it was not in the first eval.
2. **Opus 5.5** on the bridge -- the control; it scored 20 of 20
   before, so a lower score here says the seat differs, not the model.
3. **Fable 5.1** on the guild-workshop, the three solid prompts (21
   to 23) -- booleans, volumes.
4. If time and budget allow, **Sonnet 5** on the bridge for the
   comparison.

The seat's own model is chosen in its model picker; a sub-agent's
model is named when it is launched.  If a model is not offered in the
seat, say so in the report and run what is.

## The twenty prompts (bridge)

Envelopes are X (width) by Y (length) by Z (height) in millimetres,
as the primer's cube has them.  A prompt that leaves an axis to the
model's judgement gives a range.

| # | prompt (verbatim to the sub-agent) | expected envelope | parts | look for |
|---|---|---|---|---|
| 1 | A straight staircase, 12 steps, total rise 2400 mm, each tread 280 mm deep and 900 mm wide, treads 40 mm thick, with two stringers. | 900 x 3360 x 2400 | 14 | treads climb along Y; stringers the full run |
| 2 | An L-bracket 120 by 80 mm, 6 mm thick, each leg 60 mm tall, with four 8 mm holes marked. | 120 x 80 x 60 | 2 plus hole markers | two legs at a right angle; holes as drawn cylinders |
| 3 | A bookshelf 800 mm wide, 300 deep, 1800 tall, with 5 shelves and 18 mm boards. | 800 x 300 x 1800 | 9 | two sides, top, bottom, five shelves, spaced evenly |
| 4 | A dining table 1600 by 900 mm, 750 mm tall, 30 mm top, four 60 mm square legs inset 50 mm from the edges. | 1600 x 900 x 750 | 5 | legs at the corners, inset 50 |
| 5 | A deck 4 m by 3 m of 140 mm wide, 28 mm thick boards with a 6 mm gap, on three joists 45 by 195 mm, 600 mm above the ground. | 4000 x 3000 x 823 | about 24 | boards side by side across the width; joists under, not through |
| 6 | A spur gear with 24 teeth, module 3, 15 mm face width, drawn as a disc with trapezoid teeth around it. | about 78 x 78 x 15 | 25 | teeth around the rim, evenly spaced |
| 7 | A spiral staircase around a 150 mm centre post: 14 treads over a full turn, rise 2600 mm, treads 800 mm long. | about 1750 x 1750 x 2600 | 15 | treads fan around the post and climb; the post the full rise |
| 8 | A garden fence 6 m long, 1200 mm tall: posts 90 mm square every 1.5 m, two rails 45 by 90, pickets 90 wide 18 thick every 120 mm. | 6000 x 90 x 1200 | about 55 | pickets evenly spaced along X, rails through the posts |
| 9 | A brick wall 2 m long and 1 m tall, bricks 230 by 110 by 76 mm with 10 mm joints, in running bond. | 2000 x 110 x 1000 | about 100 | courses offset by half a brick; cut bricks at the ends |
| 10 | A pipe run: a 50 mm pipe going 1 m along, then a 90 degree elbow, then 600 mm up, with 4 mm wall. | 1000 x 50 x 650 | 3 | the elbow joins the two runs; a torus segment is fine |
| 11 | A simple house: floor plan 8 by 6 m, walls 2.7 m tall, a gable roof with 30 degree pitch, walls 200 mm thick. | 8000 x 6000 x about 4430 | 6 or more | the roof sits on the walls; the ridge along the long side |
| 12 | A ladder 3 m tall, 450 mm wide, rails 40 by 80 mm, rungs 30 mm round every 300 mm. | 450 x 80 x 3000 | 12 | rungs run left to right between the rails, not front to back |
| 13 | A lattice of 5 by 5 by 5 spheres, 20 mm diameter, 50 mm apart centre to centre. | 220 x 220 x 220 | 125 | a regular grid, nothing piled |
| 14 | A toy airplane about 300 mm long: a fuselage, straight wings 400 mm span, a tail with fin and stabiliser, a propeller. | 400 x 300 x about 100 | 6 or more | wings span X, fuselage along Y, fin up |
| 15 | A Warren truss bridge 6 m long, 1 m tall, 5 bays: top and bottom chords and diagonals from 60 mm square tube, two sides 800 mm apart with cross members. | 6000 x 800 x 1000 | about 30 | diagonals zigzag; the two sides mirror |
| 16 | A helical compression spring: wire 4 mm, outer diameter 40 mm, 8 coils, free length 120 mm. | 40 x 40 x 120 | 1 or a series of segments | a helix, not a stack of rings |
| 17 | Three rows of bleacher seating, each row 300 mm higher and 750 mm further back than the last, 4 m long, seat boards 250 mm deep and 40 thick. | 4000 x about 1750 x about 950 | 6 or more | rows step up and back along Y, not sliding along X |
| 18 | A kitchen cabinet 600 wide, 580 deep, 720 tall, 18 mm carcass, one shelf, two doors 20 mm thick. | 600 x 600 x 720 | 8 | doors on the front face, shelf inside |
| 19 | A pergola 3 by 3 m: four 120 mm posts 2.4 m tall, two beams 90 by 190 on top, rafters 45 by 140 every 400 mm across them. | 3000 x 3000 x about 2730 | about 14 | beams on the posts, rafters across the beams |
| 20 | A chessboard 400 mm square, 20 mm thick, 8 by 8 squares alternating dark and light, with a 20 mm border. | 400 x 400 x 20 | 65 or 66 | squares alternate; border around |

## The three solid prompts (guild-workshop)

Solids, booleans and volumes, with SMLib.  The runner checks the
volume of the result against the arithmetic given, within 1 percent:
the volume of the brep LEAF (the subtracted solid), since the root
is an assembly with no volume of its own.

| # | prompt (verbatim) | expected | check |
|---|---|---|---|
| 21 | A bracket 120 by 80 mm, 6 mm thick, with four 8 mm screw holes cut through, 10 mm in from each corner. | 120 x 80 x 6 | volume 57,600 minus 4 x pi x 16 x 6 = about 56,394 mm3; the holes are holes, not drawn cylinders |
| 22 | A flange: a 100 mm disc 12 mm thick with a 30 mm bore and four 10 mm bolt holes on an 80 mm pitch circle. | 100 x 100 x 12 | volume pi x (2500 - 225 - 4 x 25) x 12 = about 81,995 mm3 |
| 23 | A gear blank 60 mm diameter, 10 mm thick, with a 10 mm bore and a 3 mm by 3 mm keyway. | 60 x 60 x 10 | volume about pi x 900 x 10 minus pi x 25 x 10 minus about 90 = about 27,400 mm3 |

Traps met before, worth a line in the sub-agent's briefing for the
workshop: pass the package name in the room's own case (lower); one
form per call; a `subtracted-solid` needs its operands to be brep
solids (`box-solid`, `cylinder-solid`), not the wireframe primitives;
`(the-object obj volume)` on a brep is the check.

## Runs so far

| date, seat | model, room | PASS | with flaws | PARTIAL | FAIL | median calls |
|---|---|---|---|---|---|---|
| 2026-09-23, a laptop ship | Opus 5.5, bridge | 20 | -- | 0 | 0 | 7 |
| 2026-09-23, a laptop ship | Sonnet 5, bridge | 12 | -- | 3 | 5 | about 20 |
| 2026-09-23, a laptop ship | Haiku 4.5, bridge | 0 of 7 | | | | 42 |
| 2026-09-25, a cloud vat | Fable 5.1, bridge | 14 | 5 | 1 | 0 | 6 |
| 2026-09-25, a cloud vat | Opus 5.5, bridge | 17 | 3 | 0 | 0 | 5 |
| 2026-09-25, a cloud vat | Fable 5.1, workshop 21-23 | 3 | 0 | 0 | 0 | 5 |

The 2026-09-25 run scored more strictly than the first (the
with-flaws column did not exist), and its three shared flaws were
the table's readings, not the models' -- hence the reading rule
above.  Fable's one real error was a house with its gable ends
turned 90 degrees; Opus built it right.  Fable's self-verdicts were
too generous in 5 of 20; Opus rated itself lower than the runner in
5 of 20.  On the workshop every volume was within 0.02 percent of
the arithmetic, holes cut, keyway included.

## The report

A table per model: prompt number, verdict, flaw, tool calls,
self-report right or wrong.  Then the totals per model (PASS,
PASS-with-flaws, PARTIAL, FAIL; median tool calls), against the first
run's baseline (Opus 5.5: 20 PASS, median 7 calls, about 45 s each;
Sonnet 5: 12 PASS, 3 PARTIAL, 5 FAIL, median about 20 calls; Haiku
4.5: 0 of 7).  Then, for the workshop trio, the volumes measured
against the arithmetic.  Note anything the seat could not do (a
model not offered, a room that did not answer, a budget hit).

Leave every attempt's package in place until the report is written,
then delete them all (`(delete-package ...)` per package, one call
each) so the rooms are as they were.  Nothing of this is committed
to the repository; the report goes in the reply and, if the seat has
a scratchpad, in a file there.
