;;; basilisk.sexp - the base Basilisk-class outfitting
;;; -*- mode: lisp-data; -*-

;; Copyright © 2026 Gornskew Enterprises
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.  Distributed WITHOUT
;; ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.

;;;
;;; The ship's articles: who is aboard every Basilisk-class ship as she
;;; leaves the yard.  The ship register is the yard's NATIVE TONGUE --
;;; the generator reads these keys directly, and only its outputs
;;; speak docker and compose.  Canon therefore ships no glossary; a
;;; FORK that prefers its own register (corporate, rawhide, ...) adds
;;; a glossary.sexp beside its articles mapping its terms onto these
;;; keys, and overriding the yard's coined vocabulary, without
;;; touching shipped code.
;;;
;;; Edit this file, then run (skewed-generate-all-configs) to regenerate:
;;;
;;;   - docker-compose.yml         (base compose config)
;;;   - mcp/mcp-container.json     (for claude/gemini CLI inside container)
;;;   - mcp/mcp-windows.json       (for Claude Desktop on Windows via WSL)
;;;   - mcp/mcp.toml               (for Codex CLI and Grok CLI)
;;;   - generated/services-generated.el
;;;
;;; DO NOT EDIT the generated files directly.
;;;
;;; A ship takes on more crew by OVERLAY: each host's *-stack repo
;;; carries its own articles in this same register (a Transporter
;;; Chief, a Guild detachment), generated with that repo's prefix and
;;; merged by Docker Compose at up-time (compose-dev picks up all .yml
;;; files; MCP configs merge via mcp/merge-mcp-configs.sh).  A
;;; subtractive refit -- gutting the base complement to taste -- is a
;;; fork of this repo, not an overlay.
;;;
;;; The Captain's species ships in several strains (devo-full,
;;; devo-default, devo-lite, ...): the strain is the tag half of the
;;; species, so the build variant is already part of the species
;;; designation.  docker/BUILD.md in skewed-emacs carries the detail;
;;; EMACS_IMAGE_VARIANT in .env (or a --lite/--full switch) picks the
;;; strain a host flies, and this dev stack defaults to full.


(
 :meta
 (:version "2.0"
  :description "base Basilisk-class outfitting")

 :defaults
 (:restart "unless-stopped"
  :cargo-bays ((:dockside "${PROJECTS_DIR}" :stowed-at "/projects"))
  :timezone "${TZ:-Etc/UTC}"
  :network-ipv6 t
  :network-ipv4-subnet "172.20.0.0/16"
  :network-ipv6-subnet "fd00:cafe::/80")

 ;; How cyborg passengers come aboard: the lisply-mcp wrapper that
 ;; every posting with :cyborg-passengers-allowed? answers through.
 :mcp
 (:wrapper-path-container "/home/emacs-user/lisply-mcp/scripts/mcp-wrapper.js"
  :request-timeout-ms 30000)

 ;; POSTING QUALIFICATIONS: what a species must be capable of to stand
 ;; each post.  Requirements only -- deliberately NOT a fitting
 ;; catalogue (no service definitions, no rosters; that idea retired
 ;; 2026-08-17).  A species states its CAPABILITIES in its own image
 ;; manifest (the basilisk.capabilities label -- the SSoT for what an
 ;; image can do), and the muster verifies the match at up-time,
 ;; warning and proceeding: an ability may also come aboard by
 ;; arrangement (a services-init hook, at boot or later), which the
 ;; manifest cannot know.  A crew entry's :post may be a LIST -- one
 ;; crew member standing several posts, none primary, ordering
 ;; meaningless -- and its name is a slug incorporating every post it
 ;; stands, with license to abbreviate aggressively.
 :postings
 (;; A skewed-emacs Captain is recommended, not a class invariant --
  ;; and the qualification scheme says exactly that: a Captain of
  ;; another species musters with a warning and proceeds.
  (:post :captain :requires ("skewed-emacs"))
  (:post :first-officer
   :description "Bridge duty: assists the Captain and the ship's visitors."
   :requires ("gendl"))
  (:post :ships-engineer :requires ("gendl"))
  (:post :transporter-chief :requires ("reverse-proxy"))
  ;; The radio shack is a room still on the drawing board (the Eyes
  ;; Only refit); until it is grown into the hull, the posting sits on
  ;; the books like the Navigator's, and the First Officer carries the
  ;; pocket viewscreen meanwhile.
  (:post :radio-shack
   :description "Keeps the radio shack: the viewscreens, and hails to the fleet."
   :requires ("bridge viewscreen operations"))
  (:post :navigator
   :description "Keeps the chartroom: orbits, transfers, ephemerides."
   :requires ("astrodynamics"))
  (:post :museum-curator
   :description "Keeps the museum chamber and its antique machine."
   :requires ("museum keeping")))

 :crew
 (
  ;; ROOMS TAKE TYPE SLUGS, CREW TAKE MINTED NAMES (Dave, 2026-08-23;
  ;; supersedes the 2026-08-16 names-are-postings law).  Each entry is
  ;; an INTERIOR-MODULE -- a residential module the vatwright plugs
  ;; into the hull, arriving PRE-STAFFED from its catalog.  :module is
  ;; the module type; its slug becomes the compose service key, the
  ;; hostname and the in-network hail (the type-hail: ready-room,
  ;; bridge...).  The CONTAINER NAME carries the primary resident's
  ;; personal name, minted at muster by compose-dev's muster_crew and
  ;; persisted in .muster -- so a recreate under a fresh name IS a
  ;; relief: new face, new name, same room.  The module-sku is the
  ;; image type, repo:tag (the register key remains :species for now),
  ;; with the provenance -- the home planet -- split off beside it.
  ;; See BASILISK.md, "The articles" and "Postings, skus, and crew".
  ;;
  ;; ONLY :species IS REQUIRED of a crew entry (Dave, 2026-08-17).
  ;; :name is the author's slug and optional: absent, the yard derives
  ;; it from :module, else from the posts stood (hyphen-joined), or,
  ;; for a module aboard with NO assigned posting -- a STOWAWAY
  ;; residence, comprehended like anyone else -- as stowaway-<repo>,
  ;; the designator making one obvious from its slug alone.
  ;; :provenance is only needed off Docker Hub's library; :post only
  ;; when capabilities are expected of the berth.
  (:post :captain
   :module "ready-room"
   :description "The ship's console, and the longest-lived process aboard."
   :type "emacs-lisp"
   :cyborg-passengers-allowed? t
   :provenance "gornskew"
   :species "${EMACS_IMAGE_BASE:-skewed-emacs}:${EMACS_IMAGE_BRANCH:-devo}-${EMACS_IMAGE_VARIANT:-full}"
   :hailing-frequencies ((:name "http" :aboard 7080)
                         (:name "webterm" :aboard 6942 :galaxy ${TTYD_HOST_PORT:-6942}))
   :space-suit (("WEBTERM" . "${WEBTERM:-ttyd}")
                ("WEBTERM_PORT" . "6942")
                ("TERM" . "xterm-256color")
                ("COLORTERM" . "truecolor"))
   ;; The Captain's papers and effects, stowed aboard from the galaxy.
   :cargo-bays ((:dockside "${USER_HOME}/.claude/.credentials.json"
                 :stowed-at "/home/emacs-user/.claude/.credentials.json")
                (:dockside "${USER_HOME}/.gemini/google_accounts.json"
                 :stowed-at "/home/emacs-user/.gemini/google_accounts.json")
                (:dockside "${USER_HOME}/.gemini/oauth_creds.json"
                 :stowed-at "/home/emacs-user/.gemini/oauth_creds.json")
                (:dockside "${USER_HOME}/.codex/auth.json"
                 :stowed-at "/home/emacs-user/.codex/auth.json")
                ;; Papers only -- never stow all of ~/.grok: it would
                ;; bury the belt's own grok binary under ~/.grok/bin
                ;; and downloads.
                (:dockside "${USER_HOME}/.grok/auth.json"
                 :stowed-at "/home/emacs-user/.grok/auth.json")
                (:dockside "/tmp/.X11-unix" :stowed-at "/tmp/.X11-unix" :mode "rw")
                (:dockside "${EMACS_LOCAL_SRC:-/nonexistent}/.emacs-local"
                 :stowed-at "/home/emacs-user/.emacs-local" :mode "ro")
                (:dockside "${EMACS_LOCAL_SRC:-/nonexistent}/.emacs-local-early"
                 :stowed-at "/home/emacs-user/.emacs-local-early" :mode "ro"))
   ;; How this post shows on a bridge viewscreen.  :in-stack is the
   ;; ONLY routing allowed for the :emacs kind -- emacs lisply has
   ;; no token gate, so it never rides a public path.  Off-ship, the
   ;; Captain is sampled through that ship's own gendl-ccl proxy
   ;; (publish-emacs-metrics!), which is gated.
   :probe (:tile "heap skewed-emacs"
           :in-stack (:kind :emacs
                      :url "http://ready-room:7080/lisply/lisp-eval"
                      :alert-mb 2000)
           :remote (:kind :metrics
                    :path "/eyes-only-metrics/skewed-emacs"
                    :alert-mb 2000))
   :healthcheck (:endpoint "/lisply/ping-lisp" :interval "30s"))

  ;; The First Officer stays on the bridge: assists the Captain and
  ;; the ship's visitors with technical matters, and entertains
  ;; guests.  The usual match is the gendl-ccl strain (the Ship's
  ;; Engineer below being gendl-sbcl); the :species pin is what GUARANTEES it
  ;; -- the post states the duty, the species states the creature.
  (:post :first-officer
   :module "bridge"
   :description "The First Officer: bridge duty, visitors, and guests."
   :type "common-lisp"
   :provenance "gornskew"
   :species "${GENDL_IMAGE_BASE:-gendl}:${GENDL_IMAGE_BRANCH:-devo}-ccl"
   :hailing-frequencies ((:name "http" :galaxy ${GENDL_CCL_HOST_PORT:-19080} :aboard 9080)
                         (:name "swank" :aboard 4200))
   :cyborg-passengers-allowed? t
   ;; One probe for the department pair, and it rides here: this
   ;; engineer carries the metrics publisher; the cyborg department
   ;; publishes nothing, so there is no tile to ask for.  No :in-stack
   ;; form either -- a bridge viewscreen samples its own ship's image
   ;; without a probe entry.
   :probe (:tile "heap gendl-ccl"
           :remote (:kind :metrics
                    :path "/eyes-only-metrics/gendl-ccl"
                    :alert-mb 1200))
   :healthcheck (:endpoint "/lisply/ping-lisp" :interval "72s"))

  ;; The Ship's Engineer keeps the engine room: the gendl-sbcl strain.
  (:post :ships-engineer
   :module "engine-room"
   :description "The Ship's Engineer: engineering for ship and passengers."
   :type "common-lisp"
   :provenance "gornskew"
   :species "${GENDL_IMAGE_BASE:-gendl}:${GENDL_IMAGE_BRANCH:-devo}-sbcl"
   :hailing-frequencies ((:name "http" :galaxy ${GENDL_SBCL_HOST_PORT:-29080} :aboard 9090)
                         (:name "swank" :aboard 4210))
   :cyborg-passengers-allowed? t
   :healthcheck (:endpoint "/lisply/ping-lisp" :interval "90s"))

  ;; The Doctor stands the dead-man's watch (added 2026-07-26, after a
  ;; Captain fell into an unbounded call and could not be roused from
  ;; within).  A fitness check only MARKS a crew member unfit; nothing
  ;; relieves them without an actor, so relief must come from outside
  ;; the afflicted.  The Doctor revives ANY crew member who fails their
  ;; fitness check.
  (:post :doctor
   :module "sick-bay"
   :description "Watches for the wedged and revives them."
   :type "utility"
   :provenance "willfarrell"
   :species "autoheal:latest"
   :space-suit (("AUTOHEAL_CONTAINER_LABEL" . "all")
                ("AUTOHEAL_INTERVAL" . "15")
                ("AUTOHEAL_START_PERIOD" . "60"))
   ;; The galaxy's own docker socket: how the Medic reaches the crew.
   :cargo-bays ((:dockside "/var/run/docker.sock"
                 :stowed-at "/var/run/docker.sock")))

  ;; NO NAVIGATOR IN THE BASE RIG (ruling 2026-08-21): the chartroom
  ;; species is heavy, so the :navigator posting stays on the books
  ;; with no berth -- like the Transporter Chief, a hand to stand it
  ;; arrives by stack pouch, his chartroom residence arriving with
  ;; him.  The posting on the books is the class homage.

  ;; The museum chamber: atmosphere-filtered, grown into every
  ;; Basilisk-class hull -- the chamber honors the ancestor the way
  ;; the chartroom honors the engine, and no hull qualifies as a
  ;; proper Basilisk without it.  Its sole keeper is the Museum
  ;; Curator, a museum droid tending an antique machine with a
  ;; long-running deployment of Space Travel.  Filtered, not sealed
  ;; (ruling 2026-08-20): the hull takes no writes and nothing is
  ;; stowed from dockside, /tmp the one breathable volume -- but the
  ;; antique machine's own console rides the ship's lines as THE
  ;; MUSEUM TERMINAL: hail the room, museum-chamber:1052, aboard
  ;; only, and the machine itself answers.  A halted machine abandons
  ;; ship so the hull's restart policy re-boots the exhibit.
  ;;
  ;; The Curator RETURNED to the base articles 2026-08-23, refit
  ;; proven: the chamber idles near-silent now, and the species on
  ;; the register is verified before it ever ships.  The museum flies
  ;; with every hull of the class -- preservation by replication.
  (;; :name derives from the module -- "museum-chamber"; the room IS
   ;; the hail, so the old :network-alias is simply the name now.
   :post :museum-curator
   :module "museum-chamber"
   :description "Keeper of the museum chamber and its antique machine."
   :type "utility"
   :provenance "gornskew"
   :species "museum-chamber:trial"
   :hailing-frequencies ((:name "telnet" :aboard 1052))
   :filtered-hull? t
   :breathable-volumes ("/tmp")
   :no-default-cargo? t
   ;; THE EXHIBIT SLEEPS BETWEEN VISITORS (ruling 2026-08-23): the
   ;; curator droid keeps the door -- the museum terminal answers at
   ;; all hours at ~zero cost -- and a visitor's call lights the
   ;; exhibit (~1 min to boot the antique and light the plate); after
   ;; MUSEUM_IDLE_SECONDS empty it is put away again.  Dark is
   ;; healthy BY DESIGN.  An UNHURRIED hand does not hold the gangway
   ;; regardless: the raise validates everyone else and returns while
   ;; the chamber comes up in the background under the Doctor's
   ;; watch.  With the sleeper the door answers within seconds, but
   ;; the flag stays for MUSEUM_EAGER=1 hulls (the old always-on
   ;; behavior), where the boot once held every raise ~44s -- which
   ;; is exactly how an anonymous visitor concludes the ship is
   ;; wedged and scuttles it at 30.
   :unhurried? t)
  )
 )
