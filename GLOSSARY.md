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
| **posting** | the container's job role, captured by hostname: `captain`, `jr-eng-cyborg`, `pilot` |
| **the yard** | a Basilisk repository — where hulls are laid down |
| **the bridge viewscreen** | the Eyes Only board — the display itself, as opposed to **Comm**, the posting that runs it, which is typically comms officer |
| **watch change** | a restart: the ship holds station, the watch turns over |
| **yard period** | the galaxy itself went down or was rebuilt |
| **fittings** | `fittings.sexp` — what each post means in container terms |
| **crew level** | a named point in roster-space: `:standard`, `:piloted`, `:guild` |

## II. Some potential git and CI jargon (not yet used)

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


