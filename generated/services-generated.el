;;; services-generated.el --- Generated from basilisk.sexp -*- lexical-binding: t; -*-

;; Copyright © 2026 Gornskew Enterprises
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.  Distributed WITHOUT
;; ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.

;;; DO NOT EDIT - Regenerate with: (skewed-generate-all-configs)

(defvar skewed-generated-services nil)
(setq skewed-generated-services
  '(
    (:name "ready-room"
     :type "emacs-lisp"
     :lisp-impl "Emacs"
     :mcp t
     :http-host "ready-room"
     :http-port 7080
    )
    (:name "bridge"
     :type "common-lisp"
     :lisp-impl "CCL"
     :mcp t
     :http-host "bridge"
     :http-port 9080
     :http-host-port ${GENDL_CCL_HOST_PORT:-19080}
     :swank-host "bridge"
     :swank-port 4200
    )
    (:name "engine-room"
     :type "common-lisp"
     :lisp-impl "SBCL"
     :mcp t
     :http-host "engine-room"
     :http-port 9090
     :http-host-port ${GENDL_SBCL_HOST_PORT:-29080}
     :swank-host "engine-room"
     :swank-port 4210
    )
    (:name "sick-bay"
     :type "utility"
    )
    (:name "museum-chamber"
     :type "utility"
    )
   ))
;; Services configuration generated from basilisk.sexp.

(provide 'services-generated)
;;; services-generated.el ends here