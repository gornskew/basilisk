# Firecracker, Phase 0: one Lisp room as a microVM

The question this answers: what does a Gendl session cost as a
[Firecracker](https://firecracker-microvm.github.io/) microVM, restored
warm from a snapshot, and how many fit on one host?  The stack's rooms
are containers in a shared kernel; a session that evaluates a visitor's
code wants a kernel of its own.  Firecracker gives VM isolation at
container cost, and a snapshot taken after the Lisp has loaded its
world restores in well under a second, with the clones sharing the
pages they have not written.

Phase 0 is a measurement, not a service.  It boots the stock
`genworks/gendl:devo-ccl` image (and, separately, a GDL betatest
image) as a VM, waits for the lisply ping, snapshots it, restores
clones, and reports what each clone really costs.

## The host

A Linux box with KVM: `/dev/kvm` present, the user in the `kvm` group
(`newgrp kvm` in the shell that runs this, or log in again), `sudo`
for the network pieces, `docker` for building the root filesystem,
`curl`.  Cgroups v2 (any current distribution) keeps restores fast.
About 10 GB of disk under `$FC_DIR` (default `~/firecracker-phase0`).

## The run

```bash
F=/path/to/basilisk/firecracker/phase0
$F fetch                                    # firecracker v1.17.0 + the 6.1 CI kernel
$F rootfs genworks/gendl:devo-ccl gendl     # docker export -> gendl.ext4, a few minutes
$F net                                      # tap fctap0 172.16.0.1/30 (sudo)
$F boot gendl                               # boots, prints the time to the first ping
$F ping gendl                               # ping + (lisp-implementation-version)
$F measure                                  # RSS/PSS of the VM
$F snapshot gendl                           # pause, write vmstate + mem, copy the disk
$F restore gendl 1                          # clone 1 in netns fc1: disk copy, load, ping
$F restore gendl 2
$F restore gendl 3
$F measure                                  # the number Phase 0 is for
$F ping gendl 2                             # a clone answers
$F stop all; $F clean
```

Then the same with the solids engine:

```bash
$F rootfs genworks/gdl:devo-smp-betatest gdl
$F boot gdl && $F snapshot gdl && $F restore gdl 1 && $F ping gdl 1
```

`boot NAME -f` keeps the guest console in the terminal (and gives it a
shell, boot arg `phase0.shell`); run `phase0 configure NAME` from
another shell to start it.  Background boots log the console to
`$FC_DIR/run/NAME.console`.

## What to record

- **Time to first ping** on a cold boot (`boot` prints it), and on a
  restore (`restore` prints disk copy, load+resume, and ping).
- **The `measure` table with three clones up.**  RSS is what each
  process has mapped; PSS divides every shared page among the clones
  sharing it, so the *sum of PSS* is what the clones cost the host.
  PSS well under RSS means the snapshot's pages are being shared as
  hoped.  Divide the host's available memory by one clone's PSS, after
  the reservation for its other work, for the sessions-per-host figure.
- **For GDL:** that a clone restored from the snapshot still answers
  the ping and evaluates a form.  The betatest licenses are minted per
  gdl pipeline with a term of their own, not tied to a machine, so a
  clone should not care that it is a copy; this is the check.
- The `boot` time is what a cold start would cost; the `restore` time
  is what a session would wait for.

## How it is built

- **Root filesystem.** `docker export` of the image, unpacked and
  written with `mkfs.ext4 -d` inside a throwaway Debian container, so
  the tree keeps its ownership without root on the host.  The image
  has no init system; `guest-init` becomes `/sbin/init`: it mounts
  the pseudo filesystems, reads `/etc/phase0.env` (the image's user
  and HTTP port, chosen by `rootfs` from `/opt/gendl` or
  `/opt/genworks-gdl`), and runs the image's own `/etc/rc.local` as
  that user with `START_HTTP=true`.  Everything downstream is the
  image's, unchanged.
- **Kernel.** Firecracker's CI kernel (6.1) from the project's bucket,
  config saved beside it: `ip=` autoconfiguration, virtio block and
  net, ext4, cgroup v2, all built in.  The guest gets its address from
  the kernel command line, so the image needs no network tools.
- **Network.** One tap per VM at `172.16.0.1/30`, guest `172.16.0.2`,
  and nothing beyond it: Phase 0 needs no egress.  Clones keep the
  guest address the snapshot baked in, so each runs in a network
  namespace `fcN` holding a tap of the same name; `ping NAME N` goes
  through `ip netns exec`.  The production shape (a veth pair per
  namespace and NAT to a unique address per clone, or the jailer with
  `--netns`) is in Firecracker's `network-for-clones` document.
- **Paths.** The VM runs in its own directory with the rootfs and
  kernel at *relative* names; the snapshot records those, and a clone
  restored from another directory with its own copy of the disk finds
  it.  Clones share the memory file read-only (`MAP_PRIVATE`, copy on
  write), which is where the page sharing comes from.
- **Snapshot.** `PATCH /vm Paused`, `PUT /snapshot/create` (full), and
  a sparse copy of the paused disk.  Restore is `PUT /snapshot/load`
  with `resume_vm`.  The source VM stays paused; stop it when the
  clones are up.

## Not in Phase 0

Egress from the guest, the jailer (clones run as root under `ip netns
exec`), cgroup limits on CPU, and de-duplicating what a restored clone
replicates (hostname, any token the Lisp minted before the snapshot;
the kernel's random pool is reseeded by Firecracker's VMGenID).
Each of these is a later phase once the numbers are in.  The data
disk and the application inside the VM are the hangar's, below.

## The hangar: a hosted application in a VM of its own

The second question, answered on the same kit: can one application
that a visitor built and deployed in the prompt lab run in a microVM
of its own, behind the ship's reverse proxy, with its CPU, memory and
disk capped and its lifetime tied to whether its author's hosting is
paid -- while the author's deploy flow stays what it was?  `hosted`
is that: a hangar that boots one VM per deployment.

The hangar is a container on the ship's network (`hangar/Dockerfile`:
Debian with iproute2, iptables, curl, e2fsprogs, jq) that is given
the KVM and TUN devices and `NET_ADMIN`, with IP forwarding on and
its own CPU and memory caps as the outer limit on every VM it flies:

```bash
H=/path/to/basilisk/firecracker
docker build -t hangar:phase0 $H/hangar
docker run -d --init --name hangar --network <ship network> --network-alias hangar \
    --device /dev/kvm --device /dev/net/tun --cap-add NET_ADMIN \
    --sysctl net.ipv4.ip_forward=1 --cpus 2 --memory 1536m \
    -v $FC_DIR:/fc -v $H:/hangar:ro \
    -v /projects/.state/prompt-lab-deployed:/deployments:ro \
    hangar:phase0 sleep infinity
```

Firecracker runs inside it as root, which is what Phase 0 accepts; the
jailer is a later phase.  `--init` so a VM that is taken down is
reaped (a bare `sleep` as PID 1 leaves zombies).  The host needs no sudo and nobody in the
`kvm` group: Docker hands the devices over.  Nested virtualization
suffices (the kit was proven on a WSL2 host).

**The root filesystem** is the Phase 0 one plus the hosted runtime:
the demos tree (the prompt lab) and monocle at `/opt/hosted`, and
`hosted-services-init.cl` as the image's services-init hook, which
loads the lab, points it at `/data`, shuts its own doors behind a
password, names the gate and publishes.  `guest-init` mounts a second
virtio disk at `/data` when there is one, and holds the Lisp's stdin
open on a pipe: the image's REPL reads end-of-file otherwise and the
service quits a second after it is up (a container's tty hid this).
Build it with the image's export and checkouts of the two
repositories (fasl files removed):

```bash
cid=$(docker create genworks/gendl:devo-ccl); docker export $cid -o $FC_DIR/gendl.tar; docker rm $cid
mkdir -p $FC_DIR/hosted && cp -r /path/to/demos /path/to/monocle $FC_DIR/hosted/
docker run --rm -v $FC_DIR:/work -v $H:/hangar:ro -v $FC_DIR/hosted:/hosted:ro \
    debian:13-slim bash /hangar/hangar/build-rootfs hosted 4G
```

**The deployment's disk** (`hosted disk NAME`) is a 64 MiB ext4
holding the lab's record and model file for NAME, copied from the
lab's deployed root (mounted read-only at `/deployments`), owned by
the image's user; grants and purses the runtime writes land there and
survive the VM's restarts.  `up` makes it when it is missing.

**Boot** (`hosted up NAME [PORT]`): the VM gets a tap of its own on a
/30 (`172.16.N.0`, N from the name), NAT out through the hangar's
address so the guest reaches the gate, and a DNAT from the hangar's
PORT to the guest's 9080 so the proxy reaches the application; the
kernel command line carries `hosted.gate` (the gate's Messages door),
`hosted.lab` (the lab's name at the gate -- the name the lab itself is
configured with, so the VM's meter reports and the tolls it opens land
on the author's ledgers at the lab, not on ledgers of the VM's own) and
`hosted.lock`.  `VCPUS` and `MEM_MIB` are the VM's caps (1 and 512
are enough for one application); the disks are the third cap.  The
proxy's rule for the deployment names the hangar and the port, with
`:affinity` and an alias so the instance's minted session URLs stay
on the VM:

```lisp
("vm-NAME" :host "hangar" :port 9080)                     ; :backend-aliases
(:path "/prompt-lab/d/NAME" :host "hangar" :port 9080 :affinity t :preserve-host? t)
```

**The lifetime** (`hosted watch NAME`): every few seconds the watcher
asks the gate's `/host-balance` for the deployment; while the gate
says `stopped` (its hosting allowance and what was bought for it are
spent, `stopped_since` set) the VM is taken down, and when a report
fits again it is brought back.  The proxy answers its own 404 in
between; a paused page there is a later rung.

**Measured on the kit's first host** (a 2-vCPU VM at 1024 MiB, then
1 vCPU at 512 MiB; the gendl-ccl image): lisply answers 1.6-3.7 s
after `InstanceStart`, the hosted runtime (the lab compiled from
source inside the VM) 10-15 s after it; one VM costs the host about
266 MiB resident (RSS and PSS alike with one VM up); the deployment
served through the proxy with its session on the VM; the VM's compile
and run reports booked at the gate under the lab's key; the lab's own
doors 403 inside the VM; the watcher taking the VM down within its
interval of the gate's stop and bringing it back on the next fitting
report.

**The application's side doors** -- its tollbooths paid and the way
back from the card page, its files, hosting bought at its paused page
-- answer under the deployment's own address, `<prefix>/d/NAME/<door>`,
so the one rule above carries the whole application to the VM.  **The
VM books nothing:** it grants a toll on the gate's settled word and
confirms hosting bought, and the lab's own sweep books both from what
the gate lists as settled and not yet booked, as it does for a payer
who never came back.  The lab's name rides in with `hosted.lab` and is
the name the lab is configured with, so one ledger per lab at the
gate.

### The hangar as a room

The hangar is a room in the ship's articles (`basilisk.sexp`, a
`:hangar-chief` posting; narad-stack's and balaram-stack's articles
sign it on).  Its species is `hangar/Dockerfile`, built from this
directory as context -- Debian, Firecracker and its kernel baked in,
and these scripts:

```bash
cd ~/projects/basilisk/firecracker      # the kit: the build's context is this directory
docker build -f hangar/Dockerfile -t gornskew/hangar:trial .
hangar/make-rootfs ~/firecracker-hangar      # on the host, with docker: the hosted rootfs (the room's /fc)
cd .. && ./basilisk up hangar                # the room makes its template, then flies the fleet
```

The scripts are BAKED INTO the image: after pulling a change to this
directory, build the image again before raising the room, or the room
keeps flying the old loop (`docker logs` shows a `hangar up` line and
nothing about a feed).  The rootfs wants the same after a change to the
lab's code (`hangar/make-rootfs`).

The articles give the room `/dev/kvm` and `/dev/net/tun`, `NET_ADMIN`
and `ip_forward` (`:devices`, `:cap-add`, `:sysctls`), a CPU and
memory ceiling that is the outer cap on every VM aboard (`:cpus`,
`:mem-limit`), the lab's deployed root read-only at `/deployments`,
and a volume of its own at `/fc` (`HANGAR_DIR`) for the rootfs, the
data disks and the run directory.  Nothing else of the ship's shelf
comes aboard: the VMs' applications are strangers' code.

`hangar-init` is PID 1's charge.  THE FEED (2026-10-22): a lab on
another host serves its deployed root through two doors behind a
token -- `<prefix>/api/hangar/deployments` (the list, each with a
stamp that changes when it is deployed again) and
`<prefix>/api/hangar/deployment?name=` (the record and the model file)
-- and the room mirrors it into `/fc/feed` every pass when
`HANGAR_FEED_URL` is set (the token at `HANGAR_FEED_TOKEN_FILE`): a
new deployment flies, one deployed again has its VM grounded, its
data disk's two files replaced (the guest's journal replayed first, or
the next boot would replay it over the change) and its VM raised, one
gone from the feed loses its VM.  Without a feed URL, `/deployments`
is read as mounted.  The FLEET LOOP reads the deployed root every few
seconds: a deployed web application gets a data disk and a
VM (`hosted disk`, `hosted up`, a port of its own), a VM whose hosting
the gate reports stopped is taken down and a paused page stands in for
it, hosting added brings it back, and a deployment taken down takes
its VM with it and retires its disk (the un-hosting rule, below).  THE ROUTING
IS THE SHIP'S PROXY'S: every pass the loop REGISTERS each host with
the chief (`POST /_cyclops/hangar/vms`, the admin secret), and a
`:hangar` rule in cyclops sends a registered host to its VM (the
hangar's port for it), a paused host's root to the proxy's own paused
page (whose host-topup form the rule carries to the lab's room), and
any other host -- the applications that are not in VMs, the previews
-- to the rule's own backend.  One rule for every host under the
domain, and a new deployment needs none:

```lisp
(:host-match ("*.gen.works") :path "/" :hangar t :host "bridge" :port 9080
 :preserve-host? t :root-target-path "/prompt-lab/d/{label}")
```

(cyclops's wildcard host match, root rule and `:hangar` kind,
2026-10-21: the host's root becomes the deployment's path, every
longer path passes through, the host is the stickiness so no affinity
is wanted.)  `/run/hangar/status.json` in the room says what flies;
`/run/hangar/alive`, touched every pass, is the health check; the
chief's `GET /_cyclops/hangar/vms` shows what it was told.  The
environment: `GATE_URL`, `LAB` (the lab's configured name at the gate,
so the VMs report on the lab's ledgers), `APPS_DOMAIN`,
`CYCLOPS_ADMIN_URL` and `CYCLOPS_ADMIN_SECRET`, `HANGAR_INTERVAL`,
`VCPUS` and `MEM_MIB` per VM, `HANGAR_ENGINE` (`gendl` or `solid`: the
engine whose rootfs the room flies), `HANGAR_SNAPSHOT` (1, below; 0
boots every VM cold).

### A snapshot per engine (2026-10-22)

Each engine has one rootfs (`hangar/make-rootfs` writes
`hosted.ext4`; `ENGINE=solid hangar/make-rootfs` writes
`hosted-solid.ext4` from the GDL image) and, made by the room, one
TEMPLATE: `hosted template ENGINE` boots the rootfs with
`hosted.template=1`, the lab loads (the long part) and stops short of
any deployment, and the hangar pauses it and writes a full snapshot,
memory and disk, under `/fc/snap/ENGINE/`.  The room makes it before
raising anything when it is missing or older than the rootfs -- so a
new rootfs is picked up on the next pass (a running VM keeps the one
it was restored from, and a full hangar waits for a free place first;
a template that fails is not tried again until the rootfs is made
again, and VMs boot cold meanwhile).

`hosted up` then RESTORES each VM from the snapshot: its own copy of
the snapshot's disk, its own data disk in the placeholder's slot (the
same 64 MiB), `PUT /snapshot/load` onto a tap of its own
(`network_overrides`), and an ACTIVATION over lisply --
`hosted-activate!` hands the guest its address, clock and disk; the
guest's init sets the clock, mounts `/dev/vdb` at `/data` and moves
`eth0` to the VM's own /30, and the Lisp reseeds its random states
(every clone shares the template's), points the lab at `/data` and
publishes.  A clone's activation sits at the template's address
behind a lock, one at a time, for the second it takes.  No snapshot,
or a data disk of another size: the VM boots cold as before.

**The eval door is shut.**  The VM's published port reaches the whole
image, lisply included, and `lisp-eval` evaluates whatever it is
sent; the guest now runs with a lisply secret (gendl's
`GENDL_LISPLY_SECRET`).  A template's is the hangar's
(`/fc/snap/ENGINE/lisply-secret`, on the kernel line as
`hosted.lisply`); a clone takes its activation with it and at once
rotates it to one nobody holds; a cold boot's is a fresh one nobody
holds.  The ping stays open; the hangar watches the deployment's door.

**Measured on narad** (1 vCPU per VM; gendl at 512 MiB, GDL at 2048
MiB):

| | gendl | solid (GDL) |
|---|---|---|
| template: the lab loaded | 12.7-14.4 s | 36.4 s |
| snapshot written | 1.6-4.5 s | 6.3 s |
| snapshot memory, disk | 513 MiB, 938 MiB | 2.1 GiB, 1.5 GiB |
| clone up (disk copy, load, activation, publish) | 1.8 s | 1.6-3.8 s |
| clone resident (RSS, PSS) | 170, 102-135 MiB | 135-320 MiB |
| cold boot, for comparison | 11.7 s, 254 MiB | -- |

Each clone's session ids differ from the others', its clock is the
host's, it lists only its own deployment, `lisp-eval` answers 403 to
no secret and to the template's alike, and the chief routes its host
to it.  GDL's Allegro reads symbols in lower case: the hosted init
names the lab's settings through `hosted-case`.

### The un-hosting rule for a deployment taken down (2026-10-23)

The lab frees a deployment's name when it is taken down, so a disk left
under the name would hand the old app's files and its visitors' purses
to whoever deploys the name next.  When a deployment leaves the
deployed root, the room takes its VM down and RETIRES its data disk at
once: the disk moves to `/fc/retired/<name>.<epoch>/data.ext4`, and its
records -- the deployment's record, model file, purses and grants, and
the workspace -- are extracted beside it as plain files (`tree/`, via
debugfs, the guest's journal replayed first).

- **The same author deploys the name again** (the record's owner
  matches) within `HANGAR_RETIRE_DAYS` (30): the newest retired disk
  comes back under the live name, the new record and model file written
  onto it, so the app's purses and grants carry over.
- **Anyone else deploys the name:** a fresh disk; the old author's
  retired disk stays where it is until it expires.
- **After `HANGAR_RETIRE_DAYS`:** the disk image is removed and
  `disk-removed` stamped; the extracted records are kept for good (a few
  KB -- what visitors held in purses is a claim worth keeping).
- **A pass that could not read the deployed root** (the feed down)
  retires nothing.

Proven in a throwaway room on narad (a 52 s grace period): deployed by
one owner, the VM up; taken down, the disk retired with its records
extracted; deployed again by the same owner, the same disk back (the
same inode); taken down and deployed by another owner, a fresh disk
carrying the new owner's record while the first owner's waited;
the grace period lapsed, the image removed and the records kept.

A deployment whose hosting is merely STOPPED at the gate keeps its disk
and its name: it is paused, not gone.  Counting a stopped deployment's
days from the gate's `stopped_since` toward the same retirement is the
other half of the rule, not built yet.

**Not here yet:** the jailer; un-hosting a deployment stopped at the
gate; a hangar flying both engines at once
(one room per engine for now); a read-only shared rootfs in place of
each clone's copy.
