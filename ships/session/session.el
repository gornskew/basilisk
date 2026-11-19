;;; session.el --- a session ship's console settings  -*- lexical-binding: t; -*-

;; Copyright © 2026 Gornskew Enterprises
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.  Distributed WITHOUT
;; ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.

;;; Commentary:

;; Stowed at ~/.emacs-local in a session ship's ready room, so the
;; readymax init loads it last.  This Emacs belongs to ONE prompt-lab
;; session: its SLIME reaches that session's lab on the ship's bridge and
;; nothing else (the ship's network is sealed), and the whole ship is
;; struck when the session ends.

;;; Code:

(defconst session-lab-host "bridge"
  "The room whose Gendl runs this session's lab.")

(defconst session-lab-port 4200
  "Its swank hailing frequency.")

(defconst session-work-dir "/state/prompt-lab/"
  "Where the lab keeps the session's files, shared with this room.")

(setq slime-lisp-host session-lab-host
      slime-connect-host-history (list session-lab-host)
      slime-port session-lab-port
      slime-connect-port-history (list (number-to-string session-lab-port)))

;; Leaving (C-x C-c) closes the frame, never the daemon.
(setq confirm-kill-emacs nil)

;; A model file's "Package:" cookie would otherwise stop the visit at a
;; y/n prompt: apply the safe file variables, drop the rest silently.
(setq enable-local-variables :safe)

(defun session-connect ()
  "Connect SLIME to the session's lab once; a no-op when connected."
  (condition-case err
      (unless (and (fboundp 'slime-connected-p) (slime-connected-p))
        ;; readymax sideloads SLIME: slime-config puts it on the load path
        (require 'slime-config)
        (slime-connect session-lab-host session-lab-port))
    (error
     (message "SLIME not connected yet (%s) -- M-x slime-connect RET %s RET %d"
              (error-message-string err) session-lab-host session-lab-port))))

(defun session-welcome-buffer ()
  "The *Prompt Lab* buffer: what this console is and how to use it."
  (let ((buf (get-buffer-create "*Prompt Lab*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "YOUR PROMPT LAB CONSOLE -- this session's own Emacs and Lisp\n\n")
        (insert "Above is your session's model file.  Change it, then:\n\n")
        (insert "  C-x C-s    save; then press Review my edits on the lab page, and\n")
        (insert "             the lab compiles your change and the agent looks it over\n")
        (insert "  C-c C-c    or try a definition at point in your session's Lisp now\n")
        (insert "  C-x b      switch buffers (the REPL is *slime-repl ccl*)\n")
        (insert "  C-x C-c    leave this window; your session stays as it is\n\n")
        (insert "This Emacs and its Lisp are yours alone, and go when your\n")
        (insert "session ends.  What you build is public, as on the lab page.\n"))
      (special-mode)
      (goto-char (point-min)))
    buf))

(defun session-greet ()
  "After a new client frame: connect SLIME, then seat the welcome pane."
  (let ((frame (selected-frame)))
    (session-connect)
    (run-at-time
     1 nil
     (lambda ()
       (when (frame-live-p frame)
         (with-selected-frame frame
           (let ((win (split-window (frame-root-window frame) -12 'below)))
             (set-window-buffer win (session-welcome-buffer))
             (message "Your session's console: C-x C-s saves, C-c C-c tries a definition."))))))))

(add-hook 'server-after-make-frame-hook #'session-greet)

(message "Session console settings loaded: SLIME -> %s:%d, files under %s"
         session-lab-host session-lab-port session-work-dir)

;;; session.el ends here
