;;; l5-deployed-app.sexp -- L5, one deployed app: what remains
;;; -*- mode: lisp-data; -*-
;;;
;;; A microVM the hangar flies for one deployment: the app, its tolls, the
;;; hosting meter.  No agent, no lab doors, no developer doors; its only way
;;; out is the gate, through the Transporter Chief.  The VM is named when the
;;; check is run; its host is <name>.<domain>.

(:level "L5"
 :name "a deployed app"
 :project "basilisk"
 :hangar "hangar"
 :chief "transporter-room"
 :domain "gen.works"
 :vms
 ((:what "the app's microVM"
   :vcpus 1
   :mem-mib 512
   :drives ("rootfs" "data")
   :egress ((:service "transporter-room" :port 80))
   :secret-boot-args nil
   :answer ("/")
   :refuse ("/lisply/ping-lisp" "/lisply/lisp-eval" "/swank" "/_cyclops/status"
            "/prompt-lab/api/sessions" "/prompt-lab/api/config" "/prompt-lab/sheet-list"
            "/prompt-lab/api/agent" "/prompt-lab/mcp"))))
