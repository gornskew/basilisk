# GLOSSARY — the running list

The in-world terms are **canonical**. Git's and Docker's words are the
translation, not the other way round (Dave, 2026-08-16). `yard glossary`
prints this file, so this is the one place a term gets defined; add rows
here as the fiction reaches new machinery.

`LORE.md` owns the world underneath these words; `BASILISK.md` owns who
is aboard. This file owns the working vocabulary — what you type and what
the tools print back.

## The world

| in-world | in the world |
|---|---|
| **galaxy** | a host or VM: balaram, sally, shelly, elsie, narad |
| **ship** | one compose stack — one `basilisk up` |
| **crew member** | one container, standing one post |
| **posting** | the container hostname: `captain`, `jr-eng-cyborg`, `pilot` |
| **the yard** | a Basilisk repository — where hulls are laid down |
| **watch change** | a restart: the ship holds station, the watch turns over |
| **yard period** | the galaxy itself went down or was rebuilt |

## The yard-side work (git)

| in-world | git |
|---|---|
| **plans** | one repository / working tree |
| **drafts** | uncommitted changes to tracked files |
| **unlogged** | untracked files — not in the plans at all |
| **seal** | `git commit` — fix the drafts into the plans |
| **on the slip** | sealed but unfiled: commits ahead of the upstream |
| **file** | `git push` — send the slip to the yard |
| **from the yard** | commits behind the upstream: filed by someone else |
| **draw** | `git pull --ff-only` — take the yard's copy |
| **diverged** | slip and yard both moved; draw before filing |
| **shipshape** | clean, and level with the yard |
| **adrift** | detached HEAD |
| **private slip** | a repository with no remote at all |
| **muster** | roll call across every set of plans under a root |
| **survey** | read the slip: the unfiled commits, listed |
| **refit** | deploy: draw, install, and put back into service |

Per-file states, as `yard muster -l` and `yard seal` print them:

| in-world | git porcelain |
|---|---|
| **redrawn** | `M` modified |
| **added** | `A` added |
| **struck** | `D` deleted |
| **renamed** | `R` renamed |
| **retyped** | `T` typechange |
| **contested** | `U` unmerged / conflicted |
| **unlogged** | `??` untracked |

A filled bullet `●` marks what the index holds — what a seal would take.
A hollow `○` marks a change still only in the working tree.

## Notes on usage

- **Draw before you file.** A diverged set of plans means the yard moved
  while you were drawing on your copy.
- **Unlogged files never travel.** Neither a seal nor a filing carries
  them unless you say `-u`; a fleet-wide `git add -A` is how build junk
  and stray secrets get sealed in.
- **A refit calls a watch change when the plans it mounts changed.**
  Docker binds single files by inode, so a drawn-over config file is
  invisible to a running crew member until it is recreated. This is not
  pedantry: on 2026-08-16 it cost forty minutes of a production outage.
