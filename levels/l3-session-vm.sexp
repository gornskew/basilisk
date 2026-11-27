;;; l3-session-vm.sexp -- L3, one private session in a microVM: what remains
;;; -*- mode: lisp-data; -*-
;;;
;;; The hangar's private session (pl-<id>): a lab serving its author's
;;; session, on the author's disk.  Its lab doors are the point; developer
;;; doors are not.  Its way out is the gate and the private front, through
;;; the Transporter Chief.

(:level "L3"
 :name "a private session VM"
 :project "basilisk"
 :hangar "hangar"
 :chief "transporter-room"
 :domain "gen.works"
 :vms
 ((:what "the session's microVM"
   :vcpus 1
   :mem-mib 512
   :drives ("rootfs" "data")
   :egress ((:service "transporter-room" :port 80))
   :secret-boot-args nil
   :answer ("/prompt-lab")
   :refuse ("/lisply/ping-lisp" "/lisply/lisp-eval" "/swank" "/_cyclops/status"))))
