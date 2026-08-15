;;; services-generated.el --- Generated from services.sexp -*- lexical-binding: t; -*-

;; Copyright © 2026 Gornskew Enterprises
;;
;; The software, data and information contained herein are proprietary
;; to, and comprise valuable trade secrets of, Gornskew Enterprises.
;; They may be stored and used only in accordance with a written
;; license agreement from Gornskew Enterprises, and may not be
;; redistributed.

;;; DO NOT EDIT - Regenerate with: (skewed-generate-all-configs)

(defvar skewed-generated-services nil)
(setq skewed-generated-services
  '(
    (:name "cyclops"
     :type "reverse-proxy"
     :lisp-impl "AllegroCL-Runtime"
     :mcp t
     :http-host "cyclops"
     :http-port 80
     :http-host-port ${CYCLOPS_HOST_PORT:-19069}
    )
    (:name "genworks-gdl-enterprise-smp"
     :type "common-lisp"
     :lisp-impl "AllegroCL-SMP-Enterprise"
     :mcp t
     :http-host "genworks-gdl-enterprise-smp"
     :http-port 9098
     :http-host-port 9098
     :swank-host "genworks-gdl-enterprise-smp"
     :swank-port 4218
    )
    (:name "genworks-gdl-enterprise-non-smp"
     :type "common-lisp"
     :lisp-impl "AllegroCL-Enterprise"
     :mcp t
     :http-host "genworks-gdl-enterprise-non-smp"
     :http-port 9088
     :swank-host "genworks-gdl-enterprise-non-smp"
     :swank-port 4208
    )
    (:name "gendl-ccl"
    )
   ))
;; Services configuration generated from services.sexp.

(provide 'services-generated)
;;; services-generated.el ends here