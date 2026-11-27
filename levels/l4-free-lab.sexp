;;; l4-free-lab.sexp -- L4, the free public lab: what remains
;;; -*- mode: lisp-data; -*-
;;;
;;; The shared lab a stranger builds in: one Lisp, many sessions, the
;;; agent's own tools and nothing of the house's.  Its room keeps the lab's
;;; workspace and archive, reaches the gate (through the Transporter Chief)
;;; and the glass room, and nothing else of the ship.

(:level "L4"
 :name "the free public lab"
 :project "basilisk"
 :rooms
 ((:service "bridge"
   :what "the free lab, Gendl on CCL"
   :mounts ("/state" "/labs-state" "/demos-pristine" "/monocle" "/home/gendl-user/gdl-services-init.cl")
   :tmpfs ("/tmp")
   :secret-env nil
   :secret-files nil
   :search ("/run/secrets" "/home/gendl-user" "/state" "/labs-state")
   :harden (:cap-drop-all t :no-new-privileges t :pids-limit t :memory t)
   :reach ((:to "transporter-room" :port 80 :path "/llm/messages/models")
           (:to "glass-room" :port 7090 :path "/health"))
   :refuse ((:to "ready-room" :port 7080 :path "/lisply/ping-lisp")
            (:to "engine-room" :port 9090 :path "/lisply/ping-lisp")
            (:to "guild-workshop" :port 9098 :path "/lisply/ping-lisp")
            (:to "guild-workshop-2" :port 9088 :path "/lisply/ping-lisp")
            (:to "chartroom" :port 9110 :path "/")
            (:to "museum-chamber" :port 80 :path "/")
            (:to "transporter-room" :port 80 :path "/_cyclops/status" :refusal-ok t)
            (:to "transporter-room" :port 80 :path "/_cyclops/llm-gate/status" :refusal-ok t)
            (:to "transporter-room" :port 80 :path "/_cyclops/llm-gate/pot" :refusal-ok t))
   :tools (:model ("write_model" "edit_model" "read_model" "evaluate" "check_model" "render"
                   "describe_object" "search_docs" "list_files" "read_file")))
  (:service "guild-workshop"
   :what "the free lab's solids room, Genworks GDL on Allegro"
   :mounts ("/state" "/labs-state" "/demos-pristine" "/monocle" "/home/gdl-user/gdl-services-init.cl")
   :tmpfs ("/tmp")
   :secret-env nil
   :secret-files nil
   :search ("/run/secrets" "/home/gdl-user" "/state" "/labs-state")
   :harden (:cap-drop-all t :no-new-privileges t :pids-limit t :memory t)
   :reach ((:to "transporter-room" :port 80 :path "/llm/messages/models"))
   :refuse ((:to "ready-room" :port 7080 :path "/lisply/ping-lisp")
            (:to "engine-room" :port 9090 :path "/lisply/ping-lisp")
            (:to "bridge" :port 9080 :path "/lisply/ping-lisp")
            (:to "transporter-room" :port 80 :path "/_cyclops/status" :refusal-ok t)
            (:to "transporter-room" :port 80 :path "/_cyclops/llm-gate/status" :refusal-ok t)))))
