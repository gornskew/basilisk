;;; basilisk.sexp - the cloud ship's articles: the overlay crew he carries
;;; -*- mode: lisp-data; -*-
;;;
;;; The ship in a CLOUD galaxy is BASILISK-CLASS and is raised inside
;;; a rented vat: the virtual machine a Claude Code cloud session is
;;; given, which arrives with a dock-style vat already fitted (docker,
;;; dockerd, compose) and a blueprint receiver that reaches Docker Hub
;;; and GitHub by default.  The session's own cyborg is the passenger;
;;; the ship is his workshop for the length of the session, and the
;;; vat's memory of him -- the residences pulled, the yard's papers --
;;; is kept between sessions for about a week (the environment cache).
;;; No hull here has a door on the public galaxy: nothing aboard is
;;; served to anyone but the cyborg in the seat.
;;;
;;; The base articles (basilisk/basilisk.sexp) put a Captain, two
;;; junior engineering departments, a Medic and the Museum Curator
;;; aboard every ship of the class.  This overlay signs on ONE hand
;;; more: the Guild's cyborg (SMP) unit, whose residence comes from a
;;; private catalog and needs the Guild's papers (a Docker Hub login)
;;; to be pulled -- cloud-stack/setup.sh installs this overlay only
;;; when those papers are in the vat's environment, and raises the
;;; base rig alone otherwise.
;;;
;;; Written in the ship register -- the yard's native tongue, so no
;;; glossary rides here (only register FORKS carry one).
;;;
;;; To regenerate overlay configs:
;;;   (load-file "/projects/basilisk/generate-configs.el")
;;;   (skewed-generate-configs "/projects/basilisk/cloud-stack/")

(
 :meta
 (:version "4.0"
  :class "basilisk"
  :strain "lite"
  :description "Cloud-stack overlay: the Guild's cyborg unit beside the base rig, for a ship raised in a cloud session's vat")

 :defaults
 (:restart "unless-stopped"
  :cargo-bays ((:dockside "${PROJECTS_DIR}" :stowed-at "/projects"))
  :timezone "${TZ:-Etc/UTC}")

 :mcp
 (:wrapper-path-container "/home/emacs-user/lisply-mcp/scripts/mcp-wrapper.js"
  :request-timeout-ms 30000)

 ;; The Guild qualification rides with the stacks that sign Guild
 ;; hands on -- the canonical yard's base articles carry no
 ;; commercial postings.
 :postings
 ((:post :guild-engineer :requires ("genworks-gdl")))

 :crew
 (
  ;; The Guild's cyborg unit: the SMP engine with the solid-modelling
  ;; kernel aboard, the one an eval of prompt-to-model work wants
  ;; (real booleans, volumes that check).  No services-init cargo and
  ;; no probe: a cloud ship reports to no board.
  (:module "guild-workshop"
   :post :guild-engineer
   :description "Guild engineering, the cyborg (SMP) unit."
   :type "common-lisp"
   :provenance "genworks"
   :species "gdl:devo-enterprise-smp-licensed"
   :hailing-frequencies ((:name "http" :aboard 9098 :galaxy ${GDL_SMP_HOST_PORT:-9098})
                         (:name "swank" :aboard 4218))
   :cyborg-passengers-allowed? t
   :healthcheck (:endpoint "/lisply/ping-lisp" :interval "30s"))))
