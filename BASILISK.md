# BASILISK

The corporate register. This file is the source: it says what a stack
is and how it behaves, in plain operational terms.

`LORE.md` says the same things in the ship register. `GLOSSARY.md` is
the term table that maps between them, and is what keeps the two in
step — every heading here has a counterpart there, and the vocabulary
is substituted, not reinvented. Content that exists in only one
register is marked as such in the file that owns it.


## What a Basilisk is

One Docker Compose stack: a set of containers on one host, generated
from a single declaration and brought up with `basilisk up`.

The **stack** is the unit of interest. Not the host, which can carry
several stacks at once, and not the container, which is one member of
one stack. A stack is described by `basilisk.sexp`, which every other
config is generated from — compose file, MCP registries, the Emacs
service table.


## Posts

A **post** is the job a container stands. Posts are named for what
they do, and the container's hostname is the post name.

| post | usual image | what it does |
|---|---|---|
| **captain** | `skewed-emacs` | hosts the editor daemon and the `lisply-mcp` layer; the long-lived process other containers are restarted around |
| **transporter chief** | `cyclops` | the reverse proxy: everything entering the stack arrives through it and is identified there |
| **engineers** | `gendl`, `gdl` | the KBE engines; they evaluate, compute, and render |
| **comms** | `eyes-only` | serves the monitoring board |
| **medic** | `autoheal` | watches container health and restarts what has wedged |
| **crew** | anything an overlay adds | unrecognized images still participate, by design |


## Posts and images are two different axes

A post says what a container is **for**. An image says what it **is**.
They are declared separately and resolved separately:

- **post** comes from the `basilisk.post` label, falling back to the
  hostname. It decides which containers exist at all, since a stack is
  composed by listing posts.
- **species** is the image type, written `repo:tag` — `gendl:devo-ccl`,
  `cyclops:master`. It is derived from the image reference and never
  looked up. The registry and namespace are stripped: they are
  **provenance**, saying where an image is from rather than what it is,
  so `gornskew/gendl` and anyone else's `gendl` are the same species
  from different sources.

Nothing adjudicates whether an image qualifies as a species. A
declaration is taken at face value, and an image that cannot perform
its post is discovered in service rather than refused at the gate.

The tag is part of the species, which is why `gendl:devo-ccl` and
`gendl:devo-sbcl` are two species and not one.


## Routing authority

The **captain holds routing authority** for the stack, and exercises it
by writing the proxy's configuration — `cyclops.sexp` — which the
reverse proxy then serves. Nothing else in the stack decides where
traffic goes.

Two related roles are currently empty, and named here so they are not
quietly merged into the above:

- **Request forwarding** is unattended; routing authority absorbs it.
- **Route planning**, deciding what the configuration should say, is a
  separate concern from holding the authority to write it. Nobody owns
  it yet.

Consequently a default stack has no forwarding-only post. Where a
stack includes a `cyclops`, it is put on transporter chief duty, which
matches what the software does: a reverse proxy **receives**. It never
initiates outbound connections on the stack's behalf.

None of which pins a stack to one host. A stack can be brought down
here and stood up elsewhere; a running stack can in principle be
migrated between hosts without stopping; and the host itself can move,
physically or as a live VM migration, in which case every stack on it
relocates without any of them having been migrated. All three are
possible and none is routine.


## What the reverse proxy is for

Its job is **identification, not security**: knowing which request is
which and which backend it belongs to. The backends are poor at this
precisely because they are busy serving. Security is a separate
concern layered on top, not the same one.

Without a reverse proxy in the stack, nothing is closed off — traffic
simply arrives at each service directly and unscreened, straight to an
engine or to the captain.

Anything that clears the proxy and is not a plain document request
reaches the **captain**, which either handles it or dispatches it to an
engineer, ship's or guild.


## What moves through a stack

Everything arriving is reassembled at the proxy into one of four
things:

| kind | what it is |
|---|---|
| **materials** | raw input, brought in to be worked on — an image pull included |
| **goods** | processed or manufactured output: a finished result, or an input to the next step |
| **services** | work performed rather than content transferred — the engine does the thing, and the result is what leaves |
| **passengers** | processes with business here: **external** clients connecting in, and **local** ones started on demand |

**No single packet is a unit of any of these.** Each packet in or out
is part of some goods, materials, or passenger, and what is reassembled
is the whole. Services are the odd one of the four, being performed
rather than carried: what arrives and departs around a service is still
goods and materials.

A unit of work arrives, may be routed to an engine for processing or as
an input, and something else is delivered elsewhere. The stack reaches
**out to** each source rather than waiting for the source to reach it.

Both kinds of passenger pass through the captain. An **external**
passenger — a client connecting over MCP — arrives through the proxy
and terminates at the captain, which owns that layer. A **local** one
does not arrive at all: the captain starts it, on demand, to carry a
piece of work, and stops it afterwards. Such a container is short-lived
by design, stands no post, and is never registered in the crew table.

Which is why passengers are load-bearing: an incoming request really
can cause new containers to be created, and can itself be the container
that gets created. Containers so created are **siblings** on the same
daemon — they come up in the same stack, on the same network, alongside
the existing containers rather than nested inside any of them.


## What the captain carries

The image name `skewed-emacs` undersells the post considerably. The
captain image is a toolkit, of which the editor is only the
best-known component:

| tool | for |
|---|---|
| `emacs`, `emacsclient` | the editor and its daemon |
| `node` + `lisply-mcp` | the MCP layer through which clients connect |
| `webshot` + `chromium` | headless capture, driven over CDP with a real viewport |
| `git` | version control |
| `ttyd` | browser-facing terminal |
| `claude`, `codex`, `grok`, `gemini` | agent CLIs, for outbound work |

Two of those run on `node`, so the runtime is load-bearing twice over:
it carries both the inbound MCP layer and the screen capture.

**The toolkit is not uniform across images.** The headless browser
ships in `-full` and `-aituis` and is an optional `skewed-install`
module elsewhere, so a lite captain may have no capture ability at all.
Anything that expects to `webshot` from a given stack should check
rather than assume.

There is deliberately no `docker` CLI and no docker socket mounted
today. Adding them would be another entry in the table above — a
capability of the image, not a change of species.
