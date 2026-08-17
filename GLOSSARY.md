# GLOSSARY — the working vocabulary

What the words mean, in both directions. `LORE.md` owns the world
underneath; `BASILISK.md` owns who is aboard; this is the quick lookup.


## I. The world (canonical, and in use)

These are real, load-bearing, and used in the code and the docs.

| in-world | in the world |
|---|---|
| **galaxy** | a host or VM: balaram, sally, shelly, elsie, narad |
| **ship** | one compose stack — one `basilisk up` |
| **crew member** | one container, standing one post |
| **posting** | the container's job role, captured by hostname: `captain`, `jr-eng-cyborg`, `pilot` (that last one is the Transporter Chief; the posting is renamed in the lore and not yet in the configs) |
| **the yard** | a Basilisk repository — where hulls are laid down |
| **the bridge viewscreen** | the Eyes Only board — the display itself, as opposed to **Comm**, the posting that runs it, which is typically comms officer |
| **the conn** | authority over where the ship goes — held by the Captain, exercised by writing the standing orders the rest of the ship flies by |
| **the transporter room** | the reverse proxy: everything coming aboard arrives through it and is vetted before it reaches the ship proper |
| **consignment** | one unit of what comes aboard, bound for a department or for onward delivery |
| **goods**, **materials**, **services**, **passengers** | what the ship carries: processed or manufactured things; raw stock, an arriving image included; work performed rather than handed over; and personnel. Traffic, in the other register |
| **reconstitute** | what happens on the transporter pad. No single packet is a consignment — each is a _part_ of some goods, materials, or passenger, and the whole is assembled from its parts on arrival |
| **a biological passenger** | a container spun up for the occasion and stood down after: grown aboard, standing no watch, never mustered. As against a **cyborg passenger**, which arrives from outside |
| **provenance**, or a **home planet** | an image's registry and namespace — where it is from, as opposed to what it is. `gornskew/gendl` and someone else's `gendl` are the same species from different worlds |
| **impulse** | a ship making for another galaxy the ordinary way: the complement stands down here and musters there |
| **warp** | the same journey made without ever standing down — a running complement carried through a wormhole to another galaxy. It is said to have been done |
| **a galaxy under way** | the host or VM _itself_ moving: the machine physically relocated, or the VM live-migrated across a network. Every ship in it travels, and not one of them has transited |
| **watch change** | a restart: the ship holds station, the watch turns over |
| **yard period** | the galaxy itself went down or was rebuilt |
| **fittings** | `fittings.sexp` — what each post means in container terms |
| **crew level** | a named point in roster-space: `:standard`, `:piloted`, `:guild` |

## II. Vacant, and kept on the books

Real vocabulary for seats nobody currently stands. Listed separately
from section I because nothing in the code answers to them yet.

| in-world | in the world |
|---|---|
| **the helm** | flying the standing orders. **Unattended** — the conn absorbs it |
| **navigation** | choosing the route, as distinct from either holding the conn or standing the helm. **Vacant**, and deliberately not folded into the conn |
| **Pilot** | the posting that would stand the helm. No default berth: a ship carrying a Cyclops puts it on Transporter Chief duty instead. Kept here against a species and a duty that genuinely want it |


## III. Some potential git and CI jargon (not yet used)

| sketch | git |
|---|---|
| plans | a repository / working tree |
| drafts | uncommitted changes to tracked files |
| unlogged | untracked files |
| seal | `git commit` |
| on the slip | commits ahead of the upstream (unpushed) |
| file | `git push` |
| from the yard | commits behind the upstream |
| draw | `git pull --ff-only` |
| shipshape | clean, and level with the upstream |
| adrift | detached HEAD |
| refit | deploy: pull, install, restart |


