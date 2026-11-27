# Levels: what remains when a ship is carved down

A level is a ship with things REMOVED, written down as a manifest of what
REMAINS.  The manifest is the allowlist: a mount, a route, a door, an agent
tool or a secret it does not name should not be there, and `check-level`
proves so against a running ship.  A new feature of the full ship reaches a
lower level only when someone adds it to that level's manifest.

| File | Level |
|---|---|
| `l2-session-ship.sexp` | one session's own ship: its lab and its console, sealed |
| `l3-session-vm.sexp` | one private session in a microVM |
| `l4-free-lab.sexp` | the shared public lab's room |
| `l5-deployed-app.sexp` | one deployed app in a microVM |

L0 (a whole ship of one's own) and L1 (the same, hosted) are not carved, so
they have no manifest yet; their one test will be the inverse: none of the
house's secrets aboard.

## Running

```bash
./basilisk check-level l4                       # the room in this ship's project
./basilisk check-level l2 <ship-project>         # a session ship, by its compose project
./basilisk check-level l5 <vm-name>              # a deployed app's VM, by its name
```

Every check READS: `docker inspect`, `docker network inspect`, `find` and
`curl` inside a room, a microVM's configuration through its API socket (GET),
the hangar's egress rules as written.  Nothing is restarted or written.
Secrets are reported by NAME and LENGTH, never by value.  Network probes go
only between the ship's own rooms (and a level's own network), never off the
host.  Each line says PASS, FAIL or NOT CHECKED (and why); the exit status is
1 when anything failed.

## A manifest

A plist (`read` by Emacs Lisp).  `:rooms` for containers, `:vms` for
microVMs.  For a room:

- `:service` the compose service; `:mounts` the mount TARGETS allowed (a
  target under an allowed directory is allowed too); `:tmpfs` likewise.
- `:secret-env` nil: no environment variable whose name looks like a secret
  may carry a value.  `:secret-files` nil: no file whose name looks like one
  under `:search` (and each mount, two levels down).
- `:harden` what the room must carry: `:cap-drop-all`, `:no-new-privileges`,
  `:read-only`, `:pids-limit`, `:memory`.
- `:networks-internal` t: every network the room is on has no route off
  the host.
- `:reach` doors the room must reach; `:refuse` doors it must not (no
  answer at all, or a refusal: 401, 403, 404).  Each `(:to HOST :port N
  :path P)`; `:ip-of SERVICE` names a room of another project by address.
- `:tools` the agent tools a lab room may offer, by session kind.

For a VM: `:vcpus`, `:mem-mib` (at most), `:drives` (the only drive ids),
`:egress` (the only destinations its rules accept), `:secret-boot-args`
(boot argument names that may carry a value), and `:refuse` / `:answer`:
paths asked of the VM's host through the Transporter Chief.
