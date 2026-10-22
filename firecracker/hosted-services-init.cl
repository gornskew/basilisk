;;; hosted-services-init.cl -- the init of a HOSTED microVM: one Gendl
;;; (or GDL) image carrying the prompt lab's deployed-application runtime
;;; and nothing a visitor could drive.  Installed by the hangar's rootfs
;;; build as the image's services-init hook, which run-gendl-services loads
;;; once HTTP and lisply are up.
;;;
;;; Two ways in, by the kernel command line:
;;;
;;;   A COLD BOOT carries the deployment's settings and is activated at
;;;   once: hosted.gate=<url> (the gate's Messages door), hosted.lab=<name>
;;;   (the lab's name at the gate), hosted.lock=<text> (a password that
;;;   shuts the lab's own doors; the deployed doors are not behind it).
;;;
;;;   A TEMPLATE (hosted.template=1) loads the lab -- the long part, the
;;;   lab compiled from source -- and stops there, printing "template
;;;   ready"; the hangar snapshots it.  Every clone restored from the
;;;   snapshot is then activated by the hangar over lisply:
;;;   (gdl-user::hosted-activate! :gate .. :lab .. :lock .. :ip .. :gw .. :epoch ..)
;;;   which hands the clone's address, clock and disk to the guest's init
;;;   (/run/hosted/activate), waits for its own disk at /data, reseeds the
;;;   random states every clone shares with the template, points the lab
;;;   at /data and publishes.
;;;
;;; hosted.engine=solid makes it the solids lab's runtime (its prefix and
;;; engine); gendl otherwise.  The deployment itself is on the data disk
;;; at /data/prompt-lab-deployed/.

(in-package :gdl-user)

(load-quicklisp)

(defun hosted-arg (key)
  "The value of KEY=... on the kernel command line, or nil."
  (let* ((cmdline (with-open-file (in "/proc/cmdline" :if-does-not-exist nil)
                    (if in (read-line in nil "") "")))
         (needle (concatenate 'string key "="))
         (start (search needle cmdline)))
    (when start
      (let* ((from (+ start (length needle)))
             (end (or (position #\Space cmdline :start from) (length cmdline)))
             (value (string-trim '(#\Newline #\Return) (subseq cmdline from end))))
        (and (plusp (length value)) value)))))

(dolist (dir '("/opt/hosted/demos/" "/opt/hosted/monocle/"))
  (pushnew dir ql:*local-project-directories* :test #'equalp))
(ql:register-local-projects)
(ql:quickload :prompt-lab)

(defun hosted-case (name)
  "NAME, written in upper case, as this Lisp's reader names symbols: GDL's
Allegro runs in modern (case-sensitive, lower-case) mode, and an
upper-case name there is another symbol."
  (if (string= (symbol-name 'hosted-case) "HOSTED-CASE") name (string-downcase name)))
(defun hosted-find (name package)
  (and (find-package package) (find-symbol (hosted-case name) package)))
(defun hosted-lab-symbol (name) (intern (hosted-case name) :prompt-lab))
(defun hosted-set (name value) (setf (symbol-value (hosted-lab-symbol name)) value))

;; What every runtime of this rootfs shares: the lab's own doors shut (no
;; sessions, no agent, no browsing), tolls taken through the gate, and
;; the books kept by the lab, not here.  The engine is the image's
;; unless the kernel line names the solids lab.
(hosted-set "*ARCHIVE-ROOT*" nil)
(hosted-set "*PASSWORD-FILE*" nil)
(hosted-set "*EXTERNAL-AGENT?*" nil)
(hosted-set "*BROWSING?*" nil)
(hosted-set "*TOLL-PROVIDER*" :stripe)
(hosted-set "*DEPLOYMENT-PAYMENTS?*" t)
(when (hosted-find "*BOOKS?*" :prompt-lab) (hosted-set "*BOOKS?*" nil))
(when (equal (hosted-arg "hosted.engine") "solid")
  (hosted-set "*URL-PREFIX*" "/prompt-lab/solid")
  (hosted-set "*ENGINE*" :solid))

(defun hosted-configure (gate lab lock)
  "Point the lab at the deployment's disk and set what is this clone's:
the gate, the lab's name there, the password on the lab's own doors."
  (ensure-directories-exist "/data/prompt-lab/")
  (ensure-directories-exist "/data/prompt-lab-deployed/")
  (hosted-set "*WORKSPACE-ROOT*" "/data/prompt-lab/")
  (hosted-set "*DEPLOYED-ROOT*" "/data/prompt-lab-deployed/")
  (hosted-set "*PASSWORD*" (or lock "hosted"))
  (hosted-set "*MESSAGES-URL*" (or gate "http://transporter-room/llm/messages"))
  ;; the gate's ledgers are keyed by the lab's name: this VM reports its
  ;; compiles and runs, and opens its tolls, under the lab's own name
  (when lab
    (if (hosted-find "*LAB-NAME*" :prompt-lab)
        (hosted-set "*LAB-NAME*" lab)
        (setf (symbol-function (hosted-lab-symbol "DEPLOYMENT-LAB-NAME")) (lambda () lab)))))

(defun hosted-publish ()
  (funcall (hosted-lab-symbol "PUBLISH-PROMPT-LAB!"))
  (format t "~&[hosted-init] hosted runtime up at ~a; gate ~a; lab ~a; deployments: ~a~%"
          (symbol-value (hosted-lab-symbol "*URL-PREFIX*"))
          (symbol-value (hosted-lab-symbol "*MESSAGES-URL*"))
          (funcall (hosted-lab-symbol "DEPLOYMENT-LAB-NAME"))
          (mapcar (lambda (r) (gethash "name" r))
                  (funcall (hosted-lab-symbol "DEPLOYMENT-RECORDS"))))
  (finish-output)
  (with-open-file (out "/run/hosted/up" :direction :output :if-exists :supersede :if-does-not-exist :create)
    (write-line "up" out)))

(defun hosted-urandom-integer (octets)
  (or (ignore-errors
       (with-open-file (in "/dev/urandom" :element-type '(unsigned-byte 8))
         (let ((n 0)) (dotimes (i octets n) (setq n (+ (* n 256) (read-byte in)))))))
      (get-universal-time)))

(defun hosted-reseed ()
  "A clone shares the template's random states: every clone would mint the
same session ids.  Fresh states, stirred by the kernel's pool (which the
VM generation counter reseeds on restore)."
  (setq *random-state* (make-random-state t))
  (let ((iid (hosted-find "*IID-RANDOM-STATE*" :gwl)))
    (when (and iid (boundp iid)) (setf (symbol-value iid) (make-random-state t))))
  (dotimes (i (mod (hosted-urandom-integer 2) 4096)) (random 2)))

(defun hosted-activate! (&key gate lab lock ip gw epoch)
  "Activate a clone restored from the template's snapshot.  Hands the
guest's init its new address, clock and disk, and returns at once (the
address is about to move under the caller); a thread of its own waits for
the disk, then configures and publishes.  /run/hosted/up says when."
  ;; the template's lisply secret is every clone's until now: this one's
  ;; becomes a fresh one nobody holds (the caller is already through)
  (let ((secret (hosted-find "*LISPLY-SECRET*" :gendl-lisply)))
    (when secret
      (setf (symbol-value secret) (format nil "~(~32,'0x~)" (hosted-urandom-integer 16)))))
  ;; written aside and renamed into place; the aside name has no type, or
  ;; rename-file would give the target its ".tmp" (merge-pathnames)
  (let ((tmp "/run/hosted/activating"))
    (with-open-file (out tmp :direction :output :if-exists :supersede :if-does-not-exist :create)
      (format out "EPOCH=~a~%IP=~a~%GW=~a~%" (or epoch "") (or ip "") (or gw "")))
    (rename-file tmp "/run/hosted/activate"))
  (bt:make-thread
   (lambda ()
     (handler-case
         (progn
           (loop repeat 300
                 until (or (probe-file "/run/hosted/mounted") (probe-file "/run/hosted/mount-failed"))
                 do (sleep 0.1))
           (if (probe-file "/run/hosted/mounted")
               (progn (hosted-reseed) (hosted-configure gate lab lock) (hosted-publish))
               (format t "~&[hosted-init] activation: the deployment's disk did not mount~%")))
       (error (e) (format t "~&[hosted-init] activation failed: ~a~%" e))))
   :name "hosted activation")
  :activating)

(cond ((equal (hosted-arg "hosted.template") "1")
       (format t "~&[hosted-init] template ready: engine ~a, the lab loaded; waiting to be snapshotted and activated~%"
               (or (hosted-arg "hosted.engine") "gendl"))
       (finish-output))
      (t
       (hosted-configure (hosted-arg "hosted.gate") (hosted-arg "hosted.lab") (hosted-arg "hosted.lock"))
       (hosted-publish)))
