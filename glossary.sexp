;;; glossary.sexp - the yard's dictionary: ship register -> machinery keys
;;; -*- mode: lisp-data; -*-

;; Copyright © 2026 Gornskew Enterprises
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.  Distributed WITHOUT
;; ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.

;;;
;;; The articles (services.sexp beside this file) are written in the
;;; ship register.  The yard (generate-configs.el) substitutes each
;;; term below with the key its machinery expects, immediately after
;;; reading, so the generators themselves never learn the register.
;;;
;;; A fork that prefers plain machinery vocabulary replaces the
;;; articles and this dictionary together; entries may map a term to
;;; itself, and with no glossary.sexp at all the yard applies the
;;; identity translation.
;;;
;;; CONTRACT: terms listed under :terms may be used only as KEYS in
;;; the articles, never as values -- substitution is position-blind.
;;;
;;; :provenance and :species are not listed: their fold into docker's
;;; one image reference is structural, not a rename -- see
;;; skewed--join-species in generate-configs.el.
;;;
;;; :vocabulary is the other half of the dictionary: strings the yard
;;; COINS when generating, rather than keys it renames -- e.g. the
;;; designator prefixed onto the derived name of a species aboard with
;;; no assigned posting.  All register vocabulary the yard emits must
;;; ride here, never in generator code (Dave, 2026-08-17): with no
;;; glossary at all the yard falls back to register-neutral machinery
;;; words ("unassigned"), and a fork's glossary carries its own.

(
 :terms
 (
  :crew                        :services
  :hailing-frequencies         :ports
  :aboard                      :container
  :galaxy                      :host
  :cargo-bays                  :volumes
  :dockside                    :source
  :stowed-at                   :target
  :space-suit                  :environment
  :cyborg-passengers-allowed?  :mcp
  :strain                      :image-variant
 )

 :vocabulary
 (:stowaway-designator "stowaway"
  ;; Crew-muster titles, keyed by the machinery role strings.
  :muster-titles (:captain "Captain"
                  :pilot "T-Chief"
                  :engineer "Engineer"
                  :comm "Comm"
                  :doctor "Medic"
                  :stowaway "Stowaway"
                  :crew "Crew")
  :no-ingress-warning "no Transporter Chief aboard: nothing fronts HTTP; publish ports directly")
)
