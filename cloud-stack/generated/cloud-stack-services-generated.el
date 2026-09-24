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
    (:name "guild-workshop"
     :type "common-lisp"
     :lisp-impl "AllegroCL-SMP-Enterprise"
     :sku "gdl"
     :mcp t
     :http-host "guild-workshop"
     :http-port 9098
     :http-host-port ${GDL_SMP_HOST_PORT:-9098}
     :swank-host "guild-workshop"
     :swank-port 4218
    )
   ))
;; Services configuration generated from basilisk.sexp.

(provide 'services-generated)
;;; services-generated.el ends here