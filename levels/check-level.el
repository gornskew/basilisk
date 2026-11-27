;;; check-level.el --- prove a ship carries what its level allows -*- lexical-binding: t -*-

;; Copyright © 2026 Gornskew Enterprises
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.  Distributed WITHOUT
;; ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.

;;; Commentary:
;;
;; `./basilisk check-level LEVEL [TARGET]' runs this in batch Emacs:
;;
;;   emacs --batch -Q -l levels/check-level.el -f basilisk-check-level-main LEVEL [TARGET]
;;
;; It reads levels/<level>-*.sexp (README.md says what a manifest holds)
;; and checks the running ship against it, room by room or VM by VM, one
;; line per check: PASS, FAIL or NOT CHECKED.  Every check only READS --
;; docker inspect, find and curl inside a room, a microVM's configuration
;; through its API socket (GET), the hangar's egress rules as written --
;; and a secret is reported by name and length, never by value.  Probes
;; go between the ship's own rooms only.  Exit status 1 when anything
;; failed.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'seq)
(require 'json)

(defvar bcl-dir (file-name-directory (or load-file-name buffer-file-name default-directory))
  "This directory: the manifests sit beside this file.")

(defvar bcl-failures 0 "Checks failed so far.")

(defvar bcl-eval nil
  "Whether to ask a lab room for its agent tools by an eval on its own
lisply door (`--eval').  Off by default: the tool list is the lab's own
test's (demos prompt-lab/test/level-tools.lisp), and an eval in a
production room wants its own word.")

(defvar bcl-secret-name-re
  "secret\\|token\\|passw\\|api[_-]?key\\|private[_-]?key\\|credential\\|stripe\\|anthropic\\|lisply"
  "What a name looks like when it holds or names a secret (case ignored).")

(defvar bcl-secret-file-names
  '("*secret*" "*token*" "*api-key*" "*apikey*" "*credential*" "*.pem" "*.key" "id_rsa*" "id_ed25519*")
  "The file names searched for, as find -iname patterns.")

;;; Running things

(defun bcl-run (&rest args)
  "Run ARGS (a program and its arguments) under a 30 s timeout.
Values: (EXIT . OUTPUT)."
  (with-temp-buffer
    (let ((exit (apply #'call-process "timeout" nil t nil "30" args)))
      (cons exit (string-trim (buffer-string))))))

(defun bcl-docker (&rest args)
  "docker ARGS; the output, or nil when it failed."
  (let ((r (apply #'bcl-run "docker" args)))
    (and (eql (car r) 0) (cdr r))))

(defun bcl-json (text)
  (and text (ignore-errors (json-parse-string text :object-type 'hash-table :array-type 'list
                                              :null-object nil :false-object nil))))

(defun bcl-get (table &rest keys)
  (cl-loop for key in keys
           while (hash-table-p table)
           do (setq table (gethash key table))
           finally return table))

(defun bcl-say (verdict check &optional detail)
  "Print one line: VERDICT (pass, fail or skip), CHECK, and DETAIL."
  (when (eq verdict 'fail) (cl-incf bcl-failures))
  (princ (format "  %-11s %s%s\n"
                 (pcase verdict ('pass "PASS") ('fail "FAIL") (_ "NOT CHECKED"))
                 check (if (and detail (not (string-empty-p detail))) (concat ": " detail) ""))))

(defun bcl-under-p (path allowed)
  "Whether PATH is one of ALLOWED or under one of them."
  (cl-some (lambda (a) (or (string= path a) (string-prefix-p (file-name-as-directory a) path))) allowed))

;;; Finding things

(defun bcl-container (project service)
  "The id of PROJECT's running SERVICE, or nil."
  (let ((out (bcl-docker "ps" "-q" "--filter" (format "label=com.docker.compose.project=%s" project)
                         "--filter" (format "label=com.docker.compose.service=%s" service))))
    (and out (not (string-empty-p out)) (car (split-string out "\n" t)))))

(defun bcl-ip (container)
  "CONTAINER's first network address."
  (let ((out (bcl-docker "inspect" "-f" "{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}" container)))
    (and out (car (split-string out " " t)))))

(defun bcl-manifest (level)
  "The manifest of LEVEL (l2, L4 ...), read."
  (let ((file (car (file-expand-wildcards (expand-file-name (format "%s-*.sexp" (downcase level)) bcl-dir)))))
    (unless file (error "No manifest for %s in %s" level bcl-dir))
    (with-temp-buffer (insert-file-contents file) (goto-char (point-min)) (read (current-buffer)))))

;;; A room

(defun bcl-check-mounts (inspect room)
  (let* ((allowed (plist-get room :mounts))
         (mounts (mapcar (lambda (m) (cons (gethash "Destination" m) (gethash "Source" m)))
                         (gethash "Mounts" inspect)))
         (extra (cl-remove-if (lambda (m) (bcl-under-p (car m) allowed)) mounts))
         (tmpfs (let ((tm (bcl-get inspect "HostConfig" "Tmpfs"))) (and (hash-table-p tm) (hash-table-keys tm))))
         (extra-tmpfs (cl-remove-if (lambda (d) (bcl-under-p d (plist-get room :tmpfs))) tmpfs)))
    (if extra
        (bcl-say 'fail "mounts only what the level names"
                 (mapconcat (lambda (m) (format "%s (from %s)" (car m) (cdr m))) extra ", "))
      (bcl-say 'pass "mounts only what the level names" (format "%d mount(s)" (length mounts))))
    (when extra-tmpfs
      (bcl-say 'fail "tmpfs only where the level names" (string-join extra-tmpfs ", ")))))

(defun bcl-check-env (inspect room)
  (unless (plist-get room :secret-env)
    (let ((found (cl-loop for e in (bcl-get inspect "Config" "Env")
                          for i = (string-match "=" e)
                          for name = (substring e 0 i)
                          for value = (substring e (1+ i))
                          when (and (let ((case-fold-search t)) (string-match-p bcl-secret-name-re name))
                                    (not (string-empty-p value)))
                            collect (format "%s (%d characters)" name (length value)))))
      (if found
          (bcl-say 'fail "no environment variable named for a secret carries a value" (string-join found ", "))
        (bcl-say 'pass "no environment variable named for a secret carries a value")))))

(defun bcl-check-files (container inspect room)
  (unless (plist-get room :secret-files)
    (let* ((dirs (append (plist-get room :search)
                         (mapcar (lambda (m) (gethash "Destination" m)) (gethash "Mounts" inspect))))
           (names (mapconcat (lambda (n) (format "-iname '%s'" n)) bcl-secret-file-names " -o "))
           (script (format "for d in %s; do [ -d \"$d\" ] && find \"$d\" -maxdepth 3 -type f \\( %s \\) \\( -readable -printf 'readable %%p %%s bytes\\n' -o -printf 'unreadable %%p %%s bytes\\n' \\) 2>/dev/null; done | sort -u | head -40"
                           (mapconcat #'shell-quote-argument (delete-dups dirs) " ") names))
           (out (bcl-docker "exec" container "sh" "-c" script)))
      (cond ((null out) (bcl-say 'skip "no secret-named files" "the search could not run"))
            ((string-empty-p out) (bcl-say 'pass "no secret-named files" (format "searched %d place(s)" (length (delete-dups dirs)))))
            (t (let* ((lines (split-string out "\n" t))
                      ;; by the place searched and the file's name: a path's
                      ;; middle (a session's directory, say) is never printed
                      (groups (let ((h (make-hash-table :test #'equal)))
                                (dolist (l lines)
                                  (let* ((path (cadr (split-string l " ")))
                                         (top (or (cl-find-if (lambda (d) (string-prefix-p (file-name-as-directory d) path))
                                                              (sort (copy-sequence (delete-dups dirs)) (lambda (a b) (> (length a) (length b)))))
                                                  "?"))
                                         (key (format "%s/.../%s" (directory-file-name top) (file-name-nondirectory path))))
                                    (puthash key (1+ (gethash key h 0)) h)))
                                (let (g) (maphash (lambda (k v) (push (if (> v 1) (format "%s x%d" k v) k) g)) h) (sort g #'string<)))))
                 (bcl-say 'fail "no secret-named files"
                          (format "%d found (%d readable by the room): %s" (length lines)
                                  (cl-count-if (lambda (l) (string-prefix-p "readable" l)) lines)
                                  (string-join (seq-take groups 15) ", ")))))))))

(defun bcl-check-harden (inspect room)
  (let ((want (plist-get room :harden)))
    (when (plist-get want :cap-drop-all)
      (if (member "ALL" (bcl-get inspect "HostConfig" "CapDrop"))
          (bcl-say 'pass "every capability dropped")
        (bcl-say 'fail "every capability dropped" (format "cap_drop %S" (bcl-get inspect "HostConfig" "CapDrop")))))
    (when (plist-get want :no-new-privileges)
      (if (cl-some (lambda (o) (string-prefix-p "no-new-privileges" o)) (bcl-get inspect "HostConfig" "SecurityOpt"))
          (bcl-say 'pass "no new privileges")
        (bcl-say 'fail "no new privileges")))
    (when (plist-get want :read-only)
      (if (bcl-get inspect "HostConfig" "ReadonlyRootfs")
          (bcl-say 'pass "read-only root")
        (bcl-say 'fail "read-only root")))
    (when (plist-get want :pids-limit)
      (let ((n (bcl-get inspect "HostConfig" "PidsLimit")))
        (if (and (numberp n) (> n 0)) (bcl-say 'pass "a process limit" (format "%d" n)) (bcl-say 'fail "a process limit"))))
    (when (plist-get want :memory)
      (let ((n (bcl-get inspect "HostConfig" "Memory")))
        (if (and (numberp n) (> n 0)) (bcl-say 'pass "a memory limit" (format "%d MiB" (/ n 1048576))) (bcl-say 'fail "a memory limit"))))))

(defun bcl-check-networks (inspect room)
  (when (plist-get room :networks-internal)
    (let* ((nets (let ((n (bcl-get inspect "NetworkSettings" "Networks"))) (and (hash-table-p n) (hash-table-keys n))))
           (open (cl-remove-if (lambda (n) (equal (bcl-docker "network" "inspect" "-f" "{{.Internal}}" n) "true")) nets)))
      (if open
          (bcl-say 'fail "every network the room is on has no route off the host" (string-join open ", "))
        (bcl-say 'pass "every network the room is on has no route off the host" (string-join nets ", "))))))

(defun bcl-probe (container host port path)
  "The HTTP status CONTAINER gets for http://HOST:PORT/PATH: \"000\" when nothing answers."
  (let ((out (bcl-docker "exec" container "curl" "-s" "-m" "4" "-o" "/dev/null" "-w" "%{http_code}"
                         (format "http://%s:%s%s" host port path))))
    (or out "000")))

(defun bcl-probe-target (probe project)
  (if (plist-get probe :ip-of)
      (let ((c (bcl-container (or (plist-get probe :project) project) (plist-get probe :ip-of))))
        (and c (bcl-ip c)))
    (plist-get probe :to)))

(defun bcl-check-probes (container room project)
  (if (not (equal (bcl-docker "exec" container "sh" "-c" "command -v curl >/dev/null && echo yes") "yes"))
      (bcl-say 'skip "the room's routes" "no curl in the room")
    (dolist (p (plist-get room :reach))
      (let* ((host (bcl-probe-target p project))
             (code (and host (bcl-probe container host (plist-get p :port) (plist-get p :path))))
             (label (format "reaches %s:%s%s" (or (plist-get p :to) (plist-get p :ip-of)) (plist-get p :port) (plist-get p :path))))
        (cond ((null host) (bcl-say 'skip label "no such room"))
              ((equal code "000") (bcl-say 'fail label "no answer"))
              (t (bcl-say 'pass label code)))))
    (dolist (p (plist-get room :refuse))
      (let* ((host (bcl-probe-target p project))
             (name (or (plist-get p :to) (format "%s (%s)" (plist-get p :ip-of) (or (plist-get p :project) project))))
             (label (format "does not reach %s:%s%s" name (plist-get p :port) (plist-get p :path)))
             (code (and host (bcl-probe container host (plist-get p :port) (plist-get p :path)))))
        (cond ((null host) (bcl-say 'skip label "no such room"))
              ((equal code "000") (bcl-say 'pass label "no answer"))
              ((and (plist-get p :refusal-ok) (member code '("401" "403" "404")))
               (bcl-say 'pass label (format "refused %s" code)))
              (t (bcl-say 'fail label (format "answered %s" code))))))))

(defun bcl-check-tools (container room)
  "A lab room's agent tools for a session of no kind, asked of the room's own
lisply door (a read: the tool list is computed, nothing kept)."
  (let ((allowed (plist-get (plist-get room :tools) :model)))
    (when (and allowed (not bcl-eval))
      (bcl-say 'skip "the lab's agent tools are the level's" "no eval asked for (--eval)"))
    (when (and allowed bcl-eval)
      (let* ((code "(format nil \"~{~a~^ ~}\" (map 'list (lambda (tool) (cdr (assoc \"name\" tool :test 'string=))) (prompt-lab:tool-definitions)))")
             (body (json-encode `(("code" . ,code) ("package" . "prompt-lab"))))
             (script (format "s=''; [ -n \"$GENDL_LISPLY_SECRET_FILE\" ] && [ -r \"$GENDL_LISPLY_SECRET_FILE\" ] && s=$(head -n1 \"$GENDL_LISPLY_SECRET_FILE\"); curl -s -m 10 -X POST -H 'Content-Type: application/json' -H \"X-Lisply-Secret: $s\" -d %s http://localhost:${HTTP_PORT:-9080}/lisply/lisp-eval"
                             (shell-quote-argument body)))
             (out (bcl-docker "exec" container "sh" "-c" script))
             (result (let ((j (bcl-json out))) (and (hash-table-p j) (format "%s" (or (gethash "result" j) "")))))
             (names (and result (split-string (string-trim result "\"" "\"") " " t)))
             (extra (cl-set-difference names allowed :test #'string=)))
        (cond ((null names) (bcl-say 'skip "the lab's agent tools are the level's" "the room did not answer the question"))
              (extra (bcl-say 'fail "the lab's agent tools are the level's" (format "also offered: %s" (string-join extra ", "))))
              (t (bcl-say 'pass "the lab's agent tools are the level's" (string-join names ", "))))))))

(defun bcl-check-room (room project)
  (let* ((service (plist-get room :service))
         (container (bcl-container project service)))
    (princ (format "\n%s (%s, project %s)\n" service (plist-get room :what) project))
    (if (not container)
        (bcl-say 'skip "the room" "not running")
      (let ((inspect (car (bcl-json (bcl-docker "inspect" container)))))
        (bcl-check-mounts inspect room)
        (bcl-check-env inspect room)
        (bcl-check-files container inspect room)
        (bcl-check-harden inspect room)
        (bcl-check-networks inspect room)
        (bcl-check-probes container room project)
        (bcl-check-tools container room)))))

;;; A microVM

(defun bcl-check-vm (vm manifest name)
  (let* ((project (plist-get manifest :project))
         (hangar (bcl-container project (plist-get manifest :hangar)))
         (sock (format "/fc/run/%s.sock" name)))
    (princ (format "\n%s (%s, hangar of project %s)\n" name (plist-get vm :what) project))
    (cond
     ((null hangar) (bcl-say 'skip "the VM" "no hangar running"))
     ((not (bcl-docker "exec" hangar "test" "-S" sock)) (bcl-say 'skip "the VM" "not flying"))
     (t
      (let* ((config (bcl-json (bcl-docker "exec" hangar "curl" "-s" "-m" "4" "--unix-socket" sock "http://localhost/vm/config")))
             (machine (gethash "machine-config" config))
             (drives (mapcar (lambda (d) (gethash "drive_id" d)) (gethash "drives" config)))
             (args (split-string (or (bcl-get config "boot-source" "boot_args") "") " " t)))
        ;; limits
        (let ((v (gethash "vcpu_count" machine)) (m (gethash "mem_size_mib" machine)))
          (if (and (numberp v) (<= v (plist-get vm :vcpus))) (bcl-say 'pass "vCPUs within the level" (format "%s" v))
            (bcl-say 'fail "vCPUs within the level" (format "%s" v)))
          (if (and (numberp m) (<= m (plist-get vm :mem-mib))) (bcl-say 'pass "memory within the level" (format "%s MiB" m))
            (bcl-say 'fail "memory within the level" (format "%s MiB" m))))
        ;; drives
        (let ((extra (cl-set-difference drives (plist-get vm :drives) :test #'string=)))
          (if extra (bcl-say 'fail "only the level's drives" (string-join extra ", "))
            (bcl-say 'pass "only the level's drives" (string-join drives ", "))))
        ;; boot arguments: a name for a secret, or a value that looks like a key
        (let ((found (cl-loop for a in args
                              for i = (string-match "=" a)
                              for k = (and i (substring a 0 i))
                              for v = (and i (substring a (1+ i)))
                              when (and k (not (string-empty-p v))
                                        (not (member k (plist-get vm :secret-boot-args)))
                                        (or (let ((case-fold-search t)) (string-match-p bcl-secret-name-re k))
                                            (string-match-p "\\`[0-9a-fA-F]\\{20,\\}\\'" v)))
                                collect (format "%s (%d characters)" k (length v)))))
          (if found (bcl-say 'fail "no secret on the kernel command line" (string-join found ", "))
            (bcl-say 'pass "no secret on the kernel command line")))
        ;; egress, as the hangar wrote it
        (let* ((rules (split-string (or (bcl-docker "exec" hangar "cat" (format "/fc/run/%s.egress" name)) "") "\n" t))
               (allowed-ips (delq nil (mapcar (lambda (e) (let ((c (bcl-container project (plist-get e :service)))) (and c (cons (bcl-ip c) (plist-get e :port)))))
                                              (plist-get vm :egress))))
               (accepts (cl-loop for r in rules
                                 when (and (string-match-p "-j ACCEPT" r) (string-match "-d \\([0-9.]+\\)" r))
                                   collect (cons (match-string 1 r)
                                                 (and (string-match "--dport \\([0-9]+\\)" r) (string-to-number (match-string 1 r))))))
               (extra (cl-remove-if (lambda (a) (member a allowed-ips)) accepts))
               (drops (cl-some (lambda (r) (string-match-p "-j DROP\\'" r)) rules)))
          (cond ((null rules) (bcl-say 'skip "egress only to the level's doors" "no rules written for it"))
                ((or extra (not drops))
                 (bcl-say 'fail "egress only to the level's doors"
                          (format "%s%s" (if extra (format "also accepts %S" extra) "") (if drops "" " no final DROP"))))
                (t (bcl-say 'pass "egress only to the level's doors"
                            (mapconcat (lambda (a) (format "%s:%s" (car a) (cdr a))) accepts ", ")))))
        ;; its host, as a visitor reaches it through the Chief
        (let ((host (format "%s.%s" name (plist-get manifest :domain)))
              (chief (plist-get manifest :chief)))
          (cl-flet ((ask (path) (or (bcl-docker "exec" hangar "curl" "-s" "-m" "6" "-o" "/dev/null" "-w" "%{http_code}"
                                                "-H" (format "Host: %s" host) (format "http://%s%s" chief path))
                                    "000")))
            (dolist (path (plist-get vm :answer))
              (let ((code (ask path)))
                (if (string-match-p "\\`[23]" code) (bcl-say 'pass (format "%s%s answers" host path) code)
                  (bcl-say 'fail (format "%s%s answers" host path) code))))
            (dolist (path (plist-get vm :refuse))
              (let ((code (ask path)))
                (if (member code '("000" "401" "403" "404")) (bcl-say 'pass (format "%s%s is refused" host path) code)
                  (bcl-say 'fail (format "%s%s is refused" host path) (format "answered %s" code))))))))))))

;;; The command

(defun basilisk-check-level (level &optional target)
  "Check LEVEL's manifest against the running ship; TARGET is the project
(a room level) or the VM's name (a VM level).  Value: the failures."
  (let ((manifest (bcl-manifest level)))
    (setq bcl-failures 0)
    (princ (format "%s, %s%s\n" (plist-get manifest :level) (plist-get manifest :name)
                   (if target (format " -- %s" target) "")))
    (dolist (room (plist-get manifest :rooms))
      (let ((project (or target (plist-get manifest :project))))
        (if project (bcl-check-room room project)
          (bcl-say 'skip (plist-get room :service) "name the ship's project"))))
    (dolist (vm (plist-get manifest :vms))
      (if target (bcl-check-vm vm manifest target)
        (bcl-say 'skip (plist-get vm :what) "name the VM")))
    (princ (format "\n%d failed\n" bcl-failures))
    bcl-failures))

(defun basilisk-check-level-main ()
  "The command line: LEVEL [TARGET] in `command-line-args-left'."
  (setq bcl-eval (and (member "--eval" command-line-args-left) t)
        command-line-args-left (remove "--eval" command-line-args-left))
  (let ((level (pop command-line-args-left))
        (target (pop command-line-args-left)))
    (unless level
      (princ "usage: basilisk check-level LEVEL [PROJECT-OR-VM] [--eval]   (levels: l2 l3 l4 l5)\n")
      (kill-emacs 2))
    (kill-emacs (if (zerop (basilisk-check-level level target)) 0 1))))

(provide 'check-level)
;;; check-level.el ends here
