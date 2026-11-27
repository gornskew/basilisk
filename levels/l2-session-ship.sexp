;;; l2-session-ship.sexp -- L2, one session's own ship: what remains
;;; -*- mode: lisp-data; -*-
;;;
;;; ships/session/: a lab serving one session and that session's console,
;;; on a network with no route off the host.  The project is the ship's
;;; name, given when the check is run.

(:level "L2"
 :name "a private session ship"
 :rooms
 ((:service "bridge"
   :what "the lab, one session"
   :mounts ("/demos-pristine" "/monocle" "/home/gendl-user/gdl-services-init.cl" "/state" "/worker-archive")
   :tmpfs ("/tmp" "/home/gendl-user/.cache" "/home/gendl-user/quicklisp-gendl-1599/cache"
           "/home/gendl-user/quicklisp-gendl-1599/local-projects")
   :secret-env nil
   :secret-files nil
   :search ("/run/secrets" "/home/gendl-user" "/state")
   :harden (:cap-drop-all t :no-new-privileges t :read-only t :pids-limit t :memory t)
   :networks-internal t
   :refuse ((:ip-of "bridge" :project "basilisk" :port 9080 :path "/lisply/ping-lisp")
            (:ip-of "ready-room" :project "basilisk" :port 7080 :path "/lisply/ping-lisp")
            (:ip-of "transporter-room" :project "basilisk" :port 80 :path "/_cyclops/status" :refusal-ok t)))
  (:service "ready-room"
   :what "the session's console"
   :mounts ("/state" "/home/emacs-user/.emacs-local" "/home/emacs-user/session-enter")
   :secret-env nil
   :secret-files nil
   :search ("/run/secrets" "/home/emacs-user" "/state")
   :harden (:cap-drop-all t :no-new-privileges t :pids-limit t :memory t)
   :networks-internal t
   :reach ((:to "bridge" :port 9080 :path "/lisply/ping-lisp"))
   :refuse ((:ip-of "bridge" :project "basilisk" :port 9080 :path "/lisply/ping-lisp")
            (:ip-of "ready-room" :project "basilisk" :port 7080 :path "/lisply/ping-lisp")
            (:ip-of "transporter-room" :project "basilisk" :port 80 :path "/_cyclops/status" :refusal-ok t)))))
