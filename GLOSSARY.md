# GLOSSARY — the working vocabulary

What the words mean, in both directions. `LORE.md` owns the world
underneath; `BASILISK.md` owns who is aboard; this is the quick lookup.

**The tools speak git.** For one afternoon on 2026-08-16 the CLI spoke
in-world — `yard muster`, `on the slip`, `seal`, `file`, `refit` — and
it was reverted the same day: a tool you reach for while something is
broken should use the words the rest of the world's documentation uses.
Section II survives as *fiction* vocabulary, for log entries, board copy
and skins. Do not wire it back into a prompt.

## I. The world (canonical, and in use)

These are real, load-bearing, and used in the code and the docs.

| in-world | in the world |
|---|---|
| **galaxy** | a host or VM: balaram, sally, shelly, elsie, narad |
| **ship** | one compose stack — one `basilisk up` |
| **crew member** | one container, standing one post |
| **posting** | the container hostname: `captain`, `jr-eng-cyborg`, `pilot` |
| **the yard** | a Basilisk repository — where hulls are laid down |
| **the bridge viewscreen** | the Eyes Only board — the display itself, as opposed to **Comm**, the posting that runs it |
| **watch change** | a restart: the ship holds station, the watch turns over |
| **yard period** | the galaxy itself went down or was rebuilt |
| **fittings** | `fittings.sexp` — what each post means in container terms |
| **crew level** | a named point in roster-space: `:standard`, `:piloted`, `:guild` |

## II. The yard-side sketch (fiction only — the tools say git)

Kept because it is good, and because a skin or a log entry may want it.
Nothing at a prompt uses these.

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

## III. Two rules that outlived the experiment

These are operational, not decorative, and they are why the deploy
tooling is shaped the way it is.

- **Pull before you push.** A diverged repo means the remote moved while
  you were working; pushing will be rejected, and a merge you did not
  intend is worse than the rejection.

- **A changed mounted file needs a RESTART, not an `up`.** A stack mounts
  individual files — `cyclops-<host>.sexp`, each `gdl-services-init.cl` —
  and docker binds those by inode. `git pull` replaces a changed file
  with a new one, so a container running across the pull keeps reading the
  old bytes, and compose will not notice: it recreates on compose-config
  changes, not on mounted-file content. On 2026-08-16 that cost forty
  minutes in the middle of a production outage — `reload-config` cheerfully
  re-read a stale inode and reported ok.
