;;; basilisk.sexp - the SESSION SHIP: one prompt-lab session's own ship
;;; -*- mode: lisp-data; -*-

;; Copyright © 2026 Gornskew Enterprises
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.  Distributed WITHOUT
;; ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.

;;;
;;; A subtractive refit, so articles of its own rather than an overlay on
;;; the base class: two rooms and a sealed network, raised for one visitor's
;;; session and struck when it ends.
;;;
;;;  - the BRIDGE: the prompt lab (genworks/demos, prompt-lab/ship/
;;;    ship-init.cl) serving exactly one session; it quits when that session
;;;    is done, so the ship can be struck and raised fresh;
;;;  - the READY ROOM: that session's console -- a readymax Emacs behind
;;;    ttyd, its SLIME on the bridge, nothing else in reach (session.el, and
;;;    the door script session-enter, beside this file).
;;;
;;; The network is internal: no route off the host.  One room outside is
;;; JOINED to it by whatever raises the ship: the transporter room of the
;;; ship alongside.  Its Transporter Chief, a reverse proxy, routes the
;;; session's pages and console in and is the ship's only way out, to the
;;; language-model gate that a transporter room keeps as a service.
;;;
;;; Raised per session as compose project ${SHIP_NAME}, with:
;;;   SHIP_NAME     the ship's name; also its network (with DOCKER_NETWORK_NAME),
;;;                 its rooms' names (with BASILISK_PREFIX) and its routes:
;;;                 /prompt-lab/s/<SHIP_NAME>/ for the lab, and the console
;;;                 at the one path every ship shares, SHIP_CONSOLE_PATH
;;;                 (/prompt-lab/console), with ship=<SHIP_NAME>
;;;   SHIP_STATE    a host directory of its own: work/ (the session's files,
;;;                 shared by the two rooms) and archive/ (the lab's archive)
;;;   SHIP_DEMOS    a checkout of genworks/demos, read-only
;;;   SHIP_MONOCLE  a checkout of monocle, read-only
;;;   SHIP_KIT      this directory (session.el, session-enter)
;;; and, optionally, SHIP_TURNSTILE_SITE_KEY, SHIP_LAB_NAME,
;;; SHIP_SESSION_LIFETIME, SHIP_CONSOLE_VARIANT.
;;;
;;; Generate (the empty prefix renders it as a base, not an overlay):
;;;   (load-file "/projects/basilisk/generate-configs.el")
;;;   (skewed-generate-configs "/projects/basilisk/ships/session/" nil "")

(
 :meta
 (:version "0.1"
  :class "session-ship"
  :description "One prompt-lab session: its lab and its console, sealed")

 :defaults
 (:restart "unless-stopped"
  :network-internal t
  :timezone "${TZ:-Etc/UTC}"
  :ulimits ((:resource :nofile :soft 65536 :hard 1048576)))

 :crew
 (
  ;; THE BRIDGE: the lab, one session
  (:post :first-officer
   :module "bridge"
   :description "The prompt lab, serving this ship's one session."
   :type "common-lisp"
   :provenance "genworks"
   ;; the lab exits 0 when its session is done: it stays down, for whatever
   ;; raised the ship to strike it, rather than coming back fresh for a
   ;; second visitor at the same address; a crash still restarts it
   :restart "on-failure"
   :species "${GENDL_IMAGE_BASE:-gendl}:${GENDL_IMAGE_BRANCH:-devo}-ccl"
   :hailing-frequencies ((:name "http" :aboard 9080)
                         (:name "swank" :aboard 4200))
   :filtered-hull? t
   :breathable-volumes ("/tmp:rw,exec,size=256m"
                        "/home/gendl-user/.cache:rw,size=256m,uid=1000,gid=1000"
                        "/home/gendl-user/quicklisp-gendl-1599/cache:rw,size=256m,uid=1000,gid=1000"
                        "/home/gendl-user/quicklisp-gendl-1599/local-projects:rw,size=8m,uid=1000,gid=1000")
   :cap-drop ("ALL")
   :security-opt ("no-new-privileges:true")
   :pids-limit 256
   :mem-limit "640m"
   :cpus 1
   :space-suit (("WORKER_NAME" . "${SHIP_NAME}")
                ("LAB_PREFIX" . "/prompt-lab/s/${SHIP_NAME}")
                ;; this ship carries a console: the lab links it
                ("LAB_CONSOLE" . "1")
                ;; every ship's console behind one path, the ship named by
                ;; ship= (the reverse proxy picks the ready room by it)
                ("LAB_CONSOLE_PATH" . "${SHIP_CONSOLE_PATH:-/prompt-lab/console}")
                ("LAB_SESSION_LIFETIME" . "${SHIP_SESSION_LIFETIME:-1800}")
                ("LAB_TURNSTILE_SITE_KEY" . "${SHIP_TURNSTILE_SITE_KEY:-}")
                ("LAB_NAME" . "${SHIP_LAB_NAME:-}"))
   :no-default-cargo? t
   :cargo-bays ((:dockside "${SHIP_DEMOS}" :stowed-at "/demos-pristine" :mode "ro")
                (:dockside "${SHIP_MONOCLE}" :stowed-at "/monocle" :mode "ro")
                (:dockside "${SHIP_DEMOS}/prompt-lab/ship/ship-init.cl"
                 :stowed-at "/home/gendl-user/gdl-services-init.cl" :mode "ro")
                (:dockside "${SHIP_STATE}/work" :stowed-at "/state" :mode "rw")
                (:dockside "${SHIP_STATE}/archive" :stowed-at "/worker-archive" :mode "rw"))
   :healthcheck (:endpoint "/lisply/ping-lisp" :interval "30s"))

  ;; THE READY ROOM: this session's console
  (:post :captain
   :module "ready-room"
   :description "This session's own console: an Emacs behind ttyd, SLIME on the bridge."
   :type "emacs-lisp"
   :provenance "gornskew"
   ;; the strain must carry SLIME: devo-lite does not yet, so full
   :species "${EMACS_IMAGE_BASE:-readymax}:${EMACS_IMAGE_BRANCH:-devo}-${SHIP_CONSOLE_VARIANT:-full}"
   :hailing-frequencies ((:name "http" :aboard 7080)
                         (:name "webterm" :aboard 6942))
   :space-suit (("WEBTERM" . "ttyd")
                ("WEBTERM_PORT" . "6942")
                ("WEBTERM_ARGS" . "-b ${SHIP_CONSOLE_PATH:-/prompt-lab/console} -a -m 2 -t titleFixed=Prompt-Lab")
                ("WEBTERM_ENTRY" . "/home/emacs-user/session-enter")
                ("TERM" . "xterm-256color")
                ("COLORTERM" . "truecolor"))
   :cap-drop ("ALL")
   :security-opt ("no-new-privileges:true")
   :pids-limit 256
   :mem-limit "256m"
   :cpus 1
   :no-default-cargo? t
   :cargo-bays ((:dockside "${SHIP_STATE}/work" :stowed-at "/state" :mode "rw")
                (:dockside "${SHIP_KIT}/session.el"
                 :stowed-at "/home/emacs-user/.emacs-local" :mode "ro")
                (:dockside "${SHIP_KIT}/session-enter"
                 :stowed-at "/home/emacs-user/session-enter" :mode "ro"))
   :healthcheck (:endpoint "/lisply/ping-lisp" :interval "30s"))))
