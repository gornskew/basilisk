# GLOSSARY — the translation dictionary

`BASILISK.md` is the source, written in the corporate register.
`LORE.md` is its translation into the ship register. **This file is
what makes that translation mechanical rather than inventive**: a term
is substituted from the tables below, never coined on the spot.

Read left-to-right to translate, right-to-left to look up something you
met in the lore and want to place. Columns are ordered source-first
because that is the direction the work runs.


## I. In use

Load-bearing in the code and both documents.

| corporate | lore |
|---|---|
| host, or VM: balaram, sally, shelly, elsie, narad | **galaxy** |
| one compose stack — one `basilisk up` | **ship** |
| container | **crew member** |
| the job a container stands, carried on its hostname | **posting** |
| image type, `repo:tag` | **species** |
| the tag half of an image type | **strain** |
| registry and namespace — where an image is from | **provenance**, a **home planet** |
| a Basilisk repository, where stacks are defined | **the yard** |
| routing authority: writing `cyclops.sexp` | **the conn** |
| the reverse proxy | **the transporter room** |
| reassemble a request from its packets | **reconstitute** |
| one packet | **a part** of some consignment |
| one unit of work, in or out | **a consignment** |
| raw input; processed output; work performed; connecting processes | **materials**, **goods**, **services**, **passengers** |
| an external client connecting in | **a cyborg passenger** |
| a container started on demand and stopped after | **a biological passenger** |
| the captain image's toolkit | **the Captain's belt** |
| headless capture — `webshot` over `chromium` | **the glass** |
| the monitoring board | **the bridge viewscreen** |
| restart | **watch change** |
| recreate — the complement is replaced, the stack persists | **relief in place** |
| the host went down or was rebuilt | **yard period** |
| moving a stack between hosts, stopped or live | **transiting** at impulse, or at **warp** |
| moving the host itself, physically or by live migration | **a galaxy under way** |


## II. Vacant, and kept on the books

Real vocabulary for seats nobody stands. Kept out of section I because
nothing in the code answers to them yet.

| corporate | lore |
|---|---|
| request forwarding — unattended, absorbed by routing authority | **the helm** |
| route planning, as distinct from the authority to write routes | **navigation** |
| the post that would do forwarding only; no default berth | **Pilot** |


## III. Sketched, not yet used

A git and CI register, drafted and not adopted.

| git | sketch |
|---|---|
| a repository / working tree | plans |
| uncommitted changes to tracked files | drafts |
| untracked files | unlogged |
| `git commit` | seal |
| commits ahead of upstream | on the slip |
| `git push` | file |
| commits behind upstream | from the yard |
| `git pull --ff-only` | draw |
| clean, and level with upstream | shipshape |
| detached HEAD | adrift |
| deploy: pull, install, restart | refit |


## Keeping the two registers in step

1. **Write in `BASILISK.md` first.** It is the source. Corporate → lore
   adds costume and is safe; lore → corporate has to recover precision
   it never had, and would guess.
2. **Add the term here before using it** in either file. A term used in
   only one document is how the two drift apart.
3. **Headings correspond.** `BASILISK.md` sections map onto `LORE.md`
   sections I–VII in order. Adding a section to one means adding it to
   the other.
4. **Register-only content is marked**, and does not need a counterpart:
   `LORE.md` VIII–X are lore-native (names, character, death, and the
   rules governing the register itself).
5. **The veil looks after itself.** `LORE.md` cannot narrate machinery,
   because machinery terms are substituted out on the way in. It is a
   property of the translation, not a discipline anyone has to keep.
6. **Species names pass through untranslated.** _skewed-emacs_,
   _gendl_, _Genworks GDL_, _cyclops_, _autoheal_, _eyes-only_ are
   proper nouns in both registers — the name of a kind of creature and
   the name of an image are the same word on purpose, which is the
   whole content of "species is the image type". They will show up in a
   leak scan of `LORE.md` and are not leaks.

A cheap check that catches the common failure — a section added to one
file and forgotten in the other — is to compare the two heading lists:
`BASILISK.md`'s sections should map one-for-one onto `LORE.md` I–VII,
in order, with VIII onward marked lore-native.
