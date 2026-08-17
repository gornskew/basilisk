;;; generate-configs.el --- Generate configs from services.sexp -*- lexical-binding: t; -*-

;; Copyright © 2026 Gornskew Enterprises
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.  Distributed WITHOUT
;; ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.

;;;
;;; Usage: (load "/projects/skewed-emacs/generate-configs.el")
;;;        (skewed-generate-all-configs)
;;;
;;; Or from command line:
;;;   emacs --batch -l generate-configs.el -f skewed-generate-all-configs
;;;
;;; For overlays (non-skewed-emacs directories), also generates install script.
;;;
;;; This generator reads ONE services.sexp and outputs configs.
;;; Overlay behavior is handled at runtime:
;;;   - Docker Compose: native multi-file merge (-f base.yml -f overlay.yml)
;;;   - MCP configs: merged at startup via mcp/merge-configs.sh
;;;   - Install script: auto-generated for overlays (non-empty prefix);;; This generator reads ONE services.sexp and outputs configs.
;;; Overlay behavior is handled at runtime:
;;;   - Docker Compose: native multi-file merge (-f base.yml -f overlay.yml)
;;;   - MCP configs: merged at startup via mcp/merge-configs.sh

;;; Code:

(require 'cl-lib)
(require 'json)

(defvar skewed-gen-input-file nil
  "Input services.sexp file. Set before calling generator.")

(defvar skewed-gen-output-dir nil
  "Output directory for generated files. Set before calling generator.")

(defvar skewed-gen-output-prefix ""
  "Prefix for output filenames (e.g. 'betatest-' for overlay configs).")

;;; ============================================================================
;;; Reading and Parsing
;;; ============================================================================

(defun skewed--read-sexp-file (filepath)
  "Read and parse a .sexp file, returning the plist."
  (when (file-exists-p filepath)
    (with-temp-buffer
      (insert-file-contents filepath)
      (goto-char (point-min))
      (read (current-buffer)))))

(defun skewed--get-prop (plist key)
  "Get property KEY from PLIST."
  (plist-get plist key))

(defun skewed--has-mcp-services-p (config)
  "Return non-nil if CONFIG has at least one service with :mcp t."
  (cl-some (lambda (svc) (skewed--get-prop svc :mcp))
           (skewed--get-prop config :services)))

(defun skewed--mcp-approved-tools (_svc)
  "Return the standard tool names that should be pre-approved for an MCP service."
  '("ping_lisp" "http_request" "lisp_eval"))

;;; ============================================================================
;;; skewed_search Config Generation
;;; ============================================================================


;;; ============================================================================
;;; Docker Compose Generation
;;; ============================================================================

(defun skewed--generate-compose-yaml (config)
  "Generate docker-compose.yml content from CONFIG."
  (let* ((defaults (skewed--get-prop config :defaults))
         (services (skewed--get-prop config :services))
         (network-name (or (skewed--get-prop defaults :network) "skewed-network"))
         (lines '()))
    
    ;; Header
    (push "# Copyright © 2026 Gornskew Enterprises" lines)
    (push "#" lines)
    (push "# This program is free software: you can redistribute it and/or modify" lines)
    (push "# it under the terms of the GNU Affero General Public License as" lines)
    (push "# published by the Free Software Foundation, either version 3 of the" lines)
    (push "# License, or (at your option) any later version.  Distributed WITHOUT" lines)
    (push "# ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>." lines)
    (push "" lines)
    (push "# DO NOT EDIT - Generated from services.sexp" lines)
    (push "# Regenerate with: (skewed-generate-all-configs)" lines)
    (push "" lines)
    
    ;; Only include networks block for base config (no prefix)
    (when (string-empty-p skewed-gen-output-prefix)
      (let ((ipv6        (skewed--get-prop defaults :network-ipv6))
            (ipv4-subnet (skewed--get-prop defaults :network-ipv4-subnet))
            (ipv6-subnet (skewed--get-prop defaults :network-ipv6-subnet)))
        (push "networks:" lines)
        (push "  skewed-network:" lines)
        (push (format "    name: ${DOCKER_NETWORK_NAME:-%s}" network-name) lines)
        (push "    driver: bridge" lines)
        (when ipv6
          (push "    enable_ipv6: true" lines)
          (when (or ipv4-subnet ipv6-subnet)
            (push "    ipam:" lines)
            (push "      config:" lines)
            (when ipv4-subnet
              (push (format "        - subnet: \"%s\"" ipv4-subnet) lines))
            (when ipv6-subnet
              (push (format "        - subnet: \"%s\"" ipv6-subnet) lines))))
        (push "" lines)))

    
    (push "services:" lines)
    (push "" lines)
    
    ;; Services
    (dolist (svc services)
      (let* ((name (skewed--get-prop svc :name))
             (image (skewed--get-prop svc :image))
             (ports (skewed--get-prop svc :ports))
             (env (skewed--get-prop svc :environment))
             (vols (skewed--get-prop svc :volumes))
             (user (skewed--get-prop svc :user))
             (network-mode (skewed--get-prop svc :network-mode))
             (extra-hosts (skewed--get-prop svc :extra-hosts))
             (group-add (skewed--get-prop svc :group-add))
             (healthcheck (skewed--get-prop svc :healthcheck))
             (env-file (skewed--get-prop svc :env-file))
             (restart (or (skewed--get-prop svc :restart)
                          (skewed--get-prop defaults :restart)
                          "unless-stopped")))
        
        (push (format "  %s:" name) lines)
        (when image
          (push (format "    image: %s" image) lines))
        ;; N INSTANCES ON ONE HOST.  These two look redundant and are not.
        ;;
        ;; container_name is GLOBAL to the docker daemon, so it is the one
        ;; thing that genuinely collides between instances; it carries
        ;; ${BASILISK_PREFIX}, empty by default so a lone stack is named
        ;; exactly as before.
        ;;
        ;; hostname is per-NETWORK, and each instance gets its own network,
        ;; so it stays canonical -- every instance's Captain answers to
        ;; "skewed-emacs" inside its own fleet.  That is what lets
        ;; `run_compose exec skewed-emacs`, in-network DNS, and mcp-exec's
        ;; --backend-host keep working unchanged in every instance.
        (push (format "    container_name: ${BASILISK_PREFIX:-}%s" name) lines)
        (push (format "    hostname: %s" name) lines)
        ;; DECLARED TAXONOMY, as a label (Dave, 2026-08-16).  A service
        ;; must say which :post it stands.  Emitting it as a label is
        ;; what lets mint_crew_identities and `docker ps -f label=...`
        ;; read the posting instead of pattern-matching a hostname, and
        ;; it is authoritative: the declared label beats the hostname.
        ;;
        ;; THERE IS NO :species LABEL any more (Dave, 2026-08-17).
        ;; Species is the image type -- it is spelled `image:' two lines
        ;; up -- so a second, declarable copy of it could only ever
        ;; disagree with the thing it was describing.  Nothing declared
        ;; :species in any services.sexp when this came out, and nothing
        ;; read the label but the resolution chain that went with it.
        (let* ((raw-post (skewed--get-prop svc :post))
               (post (if (keywordp raw-post)
                         (substring (symbol-name raw-post) 1) raw-post)))
          (when post
            (push "    labels:" lines)
            (push (format "      basilisk.post: \"%s\"" post) lines)))
        (when user (push (format "    user: %s" user) lines))
        (push (format "    restart: %s" restart) lines)
        (push "    stdin_open: true" lines)
        (push "    tty: true" lines)
        (when network-mode
          (push (format "    network_mode: %s" network-mode) lines))
        
        ;; Ports
        (unless network-mode
          (let ((ports-with-host (cl-remove-if-not (lambda (p) (skewed--get-prop p :host)) ports)))
            (when ports-with-host
              (push "    ports:" lines)
              (dolist (port ports-with-host)
                (let ((container (skewed--get-prop port :container))
                      (host (skewed--get-prop port :host)))
                  (push (format "      - \"%s:%s\"" host container) lines))))))
        
        ;; Environment
        (push "    environment:" lines)
        (dolist (port ports)
          (let ((port-name (upcase (skewed--get-prop port :name)))
                (container (skewed--get-prop port :container))
                (host (skewed--get-prop port :host)))
            (when (equal port-name "HTTP")
              (push (format "      - HTTP_PORT=%s" container) lines)
              (when host
                (push (format "      - HTTP_HOST_PORT=%s" host) lines))
              (push "      - START_HTTP=true" lines))
            (when (equal port-name "SWANK")
              (push (format "      - SWANK_PORT=%s" container) lines)
              (when host
                (push (format "      - SWANK_HOST_PORT=%s" host) lines))
              (push "      - START_SWANK=true" lines))))
        (dolist (env-pair env)
          ;; Quote the whole NAME=VALUE as a YAML single-quoted scalar.
          ;; Unquoted values with a trailing colon (e.g. HTTP_HOST=::)
          ;; parse as YAML mappings and break docker compose validation.
          (push (format "      - '%s=%s'"
                        (car env-pair)
                        (replace-regexp-in-string "'" "''"
                                                  (format "%s" (cdr env-pair))))
                lines))
        (push (format "      - TZ=%s" (or (skewed--get-prop defaults :timezone) "${TZ:-Etc/UTC}")) lines)

        ;; env_file (long-form, required:false) -- lets a service read
        ;; secrets from an uncommitted per-host file without breaking
        ;; startup when the file is absent (default-secure).  Each spec is
        ;; a string PATH (required) or a plist (:path P :required BOOL).
        (when env-file
          (push "    env_file:" lines)
          (dolist (spec (cond ((stringp env-file) (list env-file))
                              ((keywordp (car env-file)) (list env-file))
                              (t env-file)))
            (let ((path (if (stringp spec) spec (skewed--get-prop spec :path)))
                  (required (if (stringp spec) t (skewed--get-prop spec :required))))
              (push (format "      - path: %s" path) lines)
              (push (format "        required: %s" (if required "true" "false")) lines))))
        
        ;; Volumes
        (let ((default-vols (skewed--get-prop defaults :volumes))
              (svc-vols vols))
          (push "    volumes:" lines)
          (dolist (vol default-vols)
            (let ((src (skewed--get-prop vol :source))
                  (tgt (skewed--get-prop vol :target)))
              (push "      - type: bind" lines)
              (push (format "        source: %s" src) lines)
              (push (format "        target: %s" tgt) lines)
              (push "        bind:" lines)
              (push "          create_host_path: true" lines)))
          (dolist (vol svc-vols)
            (let ((src (skewed--get-prop vol :source))
                  (tgt (skewed--get-prop vol :target))
                  (mode (skewed--get-prop vol :mode)))
              (if mode
                  (push (format "      - %s:%s:%s" src tgt mode) lines)
                (push (format "      - %s:%s" src tgt) lines)))))
        
        ;; Extra hosts
        (when (and extra-hosts (not network-mode))
          (push "    extra_hosts:" lines)
          (dolist (host-pair extra-hosts)
            (push (format "      - \"%s:%s\"" (car host-pair) (cdr host-pair)) lines)))
        
        ;; Group add
        (when group-add
          (push "    group_add:" lines)
          (dolist (grp group-add)
            (push (format "      - \"%s\"" grp) lines)))
        
        ;; Ulimits
        (let ((ulimits (skewed--get-prop svc :ulimits)))
          (when ulimits
            (push "    ulimits:" lines)
            (dolist (ul ulimits)
              (let* ((resource (let* ((raw (symbol-name (skewed--get-prop ul :resource)))
                       (stripped (if (string-prefix-p ":" raw) (substring raw 1) raw)))
                  (downcase stripped)))
                     (soft (skewed--get-prop ul :soft))
                     (hard (skewed--get-prop ul :hard)))
                (push (format "      %s:" resource) lines)
                (when soft (push (format "        soft: %s" soft) lines))
                (when hard (push (format "        hard: %s" hard) lines))))))

                ;; Networks
        (unless network-mode
          (push "    networks:" lines)
          (push "      - skewed-network" lines))
        
        ;; Healthcheck
        (when healthcheck
          (let ((endpoint (skewed--get-prop healthcheck :endpoint))
                (interval (or (skewed--get-prop healthcheck :interval) "60s"))
                (http-port (skewed--get-prop
                            (cl-find-if (lambda (p) (equal (skewed--get-prop p :name) "http")) ports)
                            :container)))
            (push "    healthcheck:" lines)
            (push (format "      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:%s%s\"]"
                          (or http-port 80) endpoint) lines)
            (push (format "      interval: %s" interval) lines)
            (push "      timeout: 3s" lines)
            (push "      retries: 3" lines)
            (push "      start_period: 15s" lines)))
        
        (push "" lines)))
    
    (string-join (nreverse lines) "\n")))

;;; ============================================================================
;;; MCP Config Generation  
;;; ============================================================================

(defun skewed--generate-mcp-json-container (config)
  "Generate MCP config for in-container usage (claude/gemini CLI)."
  (let* ((mcp-config (skewed--get-prop config :mcp))
         (wrapper-path (skewed--get-prop mcp-config :wrapper-path-container))
         (request-timeout (skewed--get-prop mcp-config :request-timeout-ms))
         (services (skewed--get-prop config :services))
         (servers '()))

    (dolist (svc services)
      (when (skewed--get-prop svc :mcp)
        (let* ((name (skewed--get-prop svc :name))
               (ports (skewed--get-prop svc :ports))
               (http-port (skewed--get-prop
                           (cl-find-if (lambda (p) (equal (skewed--get-prop p :name) "http")) ports)
                           :container))
               (args (list wrapper-path
                           "--server-name" name
                           "--backend-host" name
                           "--http-port" (number-to-string http-port))))
          (when request-timeout
            (setq args (append args (list "--request-timeout-ms"
                                          (number-to-string request-timeout)))))
          (push (cons name `((command . "node")
                             (args . ,(vconcat args))))
                servers))))

    (let ((json-encoding-pretty-print t))
      (json-encode (list (cons 'mcpServers (nreverse servers)))))))

(defun skewed--generate-mcp-json-windows (config)
  "Generate MCP config for Windows Claude Desktop via WSL.
Uses placeholder ${SKEWED_CLONE_PATH} which gets substituted at merge time."
  (let* ((exec-path "${SKEWED_CLONE_PATH}/mcp/mcp-exec")
         (request-timeout (skewed--get-prop (skewed--get-prop config :mcp) :request-timeout-ms))
         (services (skewed--get-prop config :services))
         (servers '()))

    (dolist (svc services)
      (when (skewed--get-prop svc :mcp)
        (let* ((name (skewed--get-prop svc :name))
               (ports (skewed--get-prop svc :ports))
               (http-port (skewed--get-prop
                           (cl-find-if (lambda (p) (equal (skewed--get-prop p :name) "http")) ports)
                           :container))
               (args (list exec-path
                           "--server-name" name
                           "--backend-host" name
                           "--http-port" (number-to-string http-port))))
          (when request-timeout
            (setq args (append args (list "--request-timeout-ms"
                                          (number-to-string request-timeout)))))
          (push (cons name `((command . "wsl")
                             (args . ,(vconcat args))))
                servers))))

    (let ((json-encoding-pretty-print t))
      (json-encode (list (cons 'mcpServers (nreverse servers))
                         (cons 'globalShortcut ""))))))

(defun skewed--generate-mcp-toml (config)
  "Generate MCP config in TOML format for Codex and Grok.
Codex also gets nested tool-approval tables; Grok's merge step
filters those out and keeps only top-level [mcp_servers.NAME] tables."
  (let* ((mcp-config (skewed--get-prop config :mcp))
         (wrapper-path (skewed--get-prop mcp-config :wrapper-path-container))
         (request-timeout (skewed--get-prop mcp-config :request-timeout-ms))
         (services (skewed--get-prop config :services))
         (lines '()))
    
    (dolist (svc services)
      (when (skewed--get-prop svc :mcp)
        (let* ((name (skewed--get-prop svc :name))
               (ports (skewed--get-prop svc :ports))
               (http-port (skewed--get-prop
                           (cl-find-if (lambda (p) (equal (skewed--get-prop p :name) "http")) ports)
                           :container)))
          (push (format "[mcp_servers.%s]" name) lines)
          (push "command = \"node\"" lines)
          (let ((args (list wrapper-path "--server-name" name
                            "--backend-host" name "--http-port" (number-to-string http-port))))
            (when request-timeout
              (setq args (append args (list "--request-timeout-ms"
                                            (number-to-string request-timeout)))))
            (push (format "args = [%s]"
                          (mapconcat (lambda (arg) (format "\"%s\"" arg)) args ", "))
                  lines))
          (dolist (tool-name (skewed--mcp-approved-tools svc))
            (push "" lines)
            (push (format "[mcp_servers.%s.tools.%s__%s]"
                          name name tool-name)
                  lines)
            (push "approval_mode = \"approve\"" lines))
          (push "" lines))))
    
    (string-join (nreverse lines) "\n")))

;;; ============================================================================
;;; Services Discovery (Elisp) Generation
;;; ============================================================================

(defun skewed--generate-elisp (config)
  "Generate services-generated.el for Emacs dashboard."
  (let* ((services (skewed--get-prop config :services))
         (lines '()))
    
    (push ";;; services-generated.el --- Generated from services.sexp -*- lexical-binding: t; -*-" lines)
    ;; The header is EMITTED, not hand-added.  It was hand-added before
    ;; 2026-08-15 and every regeneration silently stripped it again --
    ;; harmless while regenerating was rare, not harmless now that symbolic
    ;; rosters make it routine.  It said "proprietary / trade secret" until
    ;; 2026-08-16, when basilisk got a LICENSE and the banner started
    ;; contradicting it; the emitted notice now matches the repo.
    (push "" lines)
    (push ";; Copyright © 2026 Gornskew Enterprises" lines)
    (push ";;" lines)
    (push ";; This program is free software: you can redistribute it and/or modify" lines)
    (push ";; it under the terms of the GNU Affero General Public License as" lines)
    (push ";; published by the Free Software Foundation, either version 3 of the" lines)
    (push ";; License, or (at your option) any later version.  Distributed WITHOUT" lines)
    (push ";; ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>." lines)
    (push "" lines)
    (push ";;; DO NOT EDIT - Regenerate with: (skewed-generate-all-configs)" lines)
    (push "" lines)
    (push "(defvar skewed-generated-services nil)" lines)
    (push "(setq skewed-generated-services" lines)
    (push "  '(" lines)
    
    (dolist (svc services)
      (let* ((name (skewed--get-prop svc :name))
             (type (skewed--get-prop svc :type))
             (lisp-impl (skewed--lisp-impl svc))
             (mcp (skewed--get-prop svc :mcp))
             (ports (skewed--get-prop svc :ports))
             (http-port (cl-find-if (lambda (p) (equal (skewed--get-prop p :name) "http")) ports))
             (swank-port (cl-find-if (lambda (p) (equal (skewed--get-prop p :name) "swank")) ports)))
        (push (format "    (:name \"%s\"" name) lines)
        (when type
          (push (format "     :type \"%s\"" type) lines))
        (when lisp-impl
          (push (format "     :lisp-impl \"%s\"" lisp-impl) lines))
        (when mcp
          (push "     :mcp t" lines))
        (when http-port
          (push (format "     :http-host \"%s\"" name) lines)
          (push (format "     :http-port %s" (skewed--get-prop http-port :container)) lines)
          (when (skewed--get-prop http-port :host)
            (push (format "     :http-host-port %s" (skewed--get-prop http-port :host)) lines)))
        (when swank-port
          (push (format "     :swank-host \"%s\"" name) lines)
          (push (format "     :swank-port %s" (skewed--get-prop swank-port :container)) lines)
          (when (skewed--get-prop swank-port :host)
            (push (format "     :swank-host-port %s" (skewed--get-prop swank-port :host)) lines)))
        (push "    )" lines)))
    
    (push "   ))" lines)
    (push ";; Services configuration generated from services.sexp." lines)
    (push "" lines)
    (push "(provide 'services-generated)" lines)
    (push ";;; services-generated.el ends here" lines)
    
    (string-join (nreverse lines) "\n")))

;;; ============================================================================
;;; Main Entry Points
;;; ============================================================================
;;; Install Script Generation (for overlays only)
;;; ============================================================================

;; Ports generate-env.sh will arrive at on its own.  A pin equal to one of
;; these is worse than no pin: it would also defeat BASILISK_PORT_OFFSET,
;; which exists so several instances can run on one host.  Only a
;; DEVIATION from these is worth pinning.
(defconst skewed--generated-env-port-defaults
  '(("CYCLOPS_HOST_PORT" . "19069")
    ("CYCLOPS_UTILITY_HOST_PORT" . "19191"))
  "Host ports generate-env.sh writes into .env when it inherits nothing.")

(defun skewed--ingress-port-pins (config)
  "Return host.env pin lines for CONFIG's ingress, as KEY=VALUE strings.

A ship whose ingress fronts the public internet declares its own
published ports in services.sexp -- sally and shelly publish :80.  That
declaration reaches compose as `${CYCLOPS_HOST_PORT:-80}', and compose
reads .env FIRST, where generate-env.sh has written the dev port unless
it inherited a value.  So the overlay's own default never gets a chance:
the ingress moves to 19069 and every property behind it goes dark.  That
is the 2026-08-16 outage, and it happened because this generator emitted
an install script that wrote only the image variant into host.env -- the
one channel ./basilisk and basilisk.service both read before generating.

The ingress is found BY PROPERTY (:type \"reverse-proxy\"), never by its
service name: the name is a posting, postings get renamed (pilot ->
transporter-chief), and a name match here would silently drop the :80
pin on the next rename -- re-running the 2026-08-16 outage with a fresh
cause.

Ports matching `skewed--generated-env-port-defaults' yield no pin, so dev
hosts stay offsettable."
  (let ((ingress (cl-find-if (lambda (svc)
                               (equal (skewed--get-prop svc :type) "reverse-proxy"))
                             (skewed--get-prop config :services)))
        (pins '()))
    (dolist (port (skewed--get-prop ingress :ports))
      (let ((host (format "%s" (or (skewed--get-prop port :host) ""))))
        (when (string-match "\\`\\${\\([A-Z0-9_]+\\):-\\([0-9]+\\)}\\'" host)
          (let ((var (match-string 1 host))
                (val (match-string 2 host)))
            (unless (equal val (cdr (assoc var skewed--generated-env-port-defaults)))
              (push (format "%s=%s" var val) pins))))))
    (nreverse pins)))

(defun skewed--generate-install-script (prefix &optional has-mcp variant port-pins)
  "Generate install script for overlay or base repository with PREFIX.
When PREFIX is empty, generates a base install (copies docker-compose.yml).
When HAS-MCP is non-nil, include MCP config copy commands.
PORT-PINS is a list of KEY=VALUE strings (see `skewed--ingress-port-pins')
written into host.env alongside the image variant.
Returns the install script content as a string."
  (let ((lines '())
        (is-base (string-empty-p prefix))
        (label (if (string-empty-p prefix) "base config" 
                 (string-trim-right prefix "-"))))
    (push "#!/bin/bash" lines)
    (push "#" lines)
    (push (format "# Install script for %s" label) lines)
    (push "#" lines)
    (push "# This copies pre-generated configs into the Basilisk checkout." lines)
    (push "# Docker Compose will automatically merge the .yml files." lines)
    (push "# MCP configs are merged automatically by ./basilisk up." lines)
    (push "" lines)
    (push "set -e" lines)
    (push "" lines)
    ;; The yard moved out of skewed-emacs, so overlays install into
    ;; basilisk now.  BASILISK_DIR is overridable for the transition: a
    ;; box still running the stack from a skewed-emacs checkout can say
    ;; BASILISK_DIR=../skewed-emacs ./install without editing this
    ;; GENERATED file -- which is what hand-editing it amounts to, and
    ;; the edit is lost on the next regeneration.
    (push "SCRIPT_DIR=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\"" lines)
    (push "TARGET_DIR=\"${BASILISK_DIR:-$SCRIPT_DIR/../basilisk}\"" lines)
    (push "" lines)
    (push (format "echo \"Installing %s...\"" label) lines)
    (push "echo \"  from: $SCRIPT_DIR\"" lines)
    (push "echo \"  into: $TARGET_DIR\"" lines)
    (push "echo \"\"" lines)
    (push "" lines)
    (push "# Check if target directory exists" lines)
    (push "if [ ! -d \"$TARGET_DIR\" ]; then" lines)
    (push "    echo \"Error: Target directory $TARGET_DIR does not exist\"" lines)
    (push "    echo \"Clone basilisk beside this repo, or set BASILISK_DIR.\"" lines)
    (push "    exit 1" lines)
    (push "fi" lines)
    (push "" lines)

    ;; Compose file copy
    (if is-base
        (progn
          (push "# Copy base compose (replaces skewed-emacs default)" lines)
          (push "echo \"Installing docker-compose.yml (base with networks)...\"" lines)
          (push "cp \"$SCRIPT_DIR/docker-compose.yml\" \"$TARGET_DIR/docker-compose.yml\"" lines))
      (push "# Copy compose overlay" lines)
      (push (format "echo \"Installing %scompose.yml...\"" prefix) lines)
      (push (format "cp \"$SCRIPT_DIR/%scompose.yml\" \"$TARGET_DIR/\"" prefix) lines))
    (push "" lines)

    ;; MCP configs
    (when has-mcp
      (push "# Copy MCP configs" lines)
      (push "echo \"Installing MCP configs...\"" lines)
      (push "mkdir -p \"$TARGET_DIR/mcp\"" lines)
      (if is-base
          (progn
            (push "for f in \"$SCRIPT_DIR/mcp/\"*.json \"$SCRIPT_DIR/mcp/\"*.toml; do" lines)
            (push "    [ -f \"$f\" ] && cp \"$f\" \"$TARGET_DIR/mcp/\"" lines)
            (push "done" lines))
        (push (format "cp \"$SCRIPT_DIR/mcp/%smcp-container.json\" \"$TARGET_DIR/mcp/\"" prefix) lines)
        (push (format "cp \"$SCRIPT_DIR/mcp/%smcp-windows.json\" \"$TARGET_DIR/mcp/\"" prefix) lines)
        (push (format "cp \"$SCRIPT_DIR/mcp/%smcp.toml\" \"$TARGET_DIR/mcp/\"" prefix) lines))
      (push "" lines))

    ;; Services discovery
    (push "# Copy services discovery (dashboard + swank)" lines)
    ;; Services topology is YARD OUTPUT and travels in generated/, never in
    ;; the Captain's dot-files tree.
    (push "echo \"Installing services discovery...\"" lines)
    (push "mkdir -p \"$TARGET_DIR/generated\"" lines)
    (if is-base
        (progn
          (push "for f in \"$SCRIPT_DIR/generated/\"*services-generated.el; do" lines)
          (push "    [ -f \"$f\" ] && cp \"$f\" \"$TARGET_DIR/generated/\"" lines)
          (push "done" lines))
      (push "for svc_file in \"$SCRIPT_DIR/generated/\"*-services-generated.el; do" lines)
      (push "    if [ -f \"$svc_file\" ]; then" lines)
      (push "        cp \"$svc_file\" \"$TARGET_DIR/generated/\"" lines)
      (push "    fi" lines)
      (push "done" lines))
    (push "" lines)

    ;; SYSTEMD HOST INJECTION.  There is exactly ONE Basilisk unit, and it
    ;; lives in the Basilisk clone.  Until 2026-08-15 every *-stack repo
    ;; carried its own near-identical copy of the service file, and the whole
    ;; difference between all five was the image variant plus a description
    ;; string -- five sources of truth for one value, which is how they
    ;; drift.  So a stack contributes DATA, not a unit: it writes host.env
    ;; into the Basilisk clone and basilisk/systemd/install does the rest.
    ;;
    ;; host.env carries every host pin, not just the variant: an ingress
    ;; that publishes :80 rides here too, because .env would otherwise
    ;; hand it the dev port (see `skewed--ingress-port-pins').
    (unless is-base
      (progn
        (when (or variant port-pins)
          (push "# --- systemd host injection ------------------------------------" lines)
          (push (format "echo \"Injecting systemd host.env (%s)...\""
                        (string-join
                         (append (when variant (list (format "image variant: %s" variant)))
                                 (mapcar (lambda (pin) (format "pin %s" pin)) port-pins))
                         ", "))
                lines)
          (push "mkdir -p \"$TARGET_DIR/systemd\"" lines)
          (push "{" lines)
          (push (format "  echo \"# Generated by %s/install -- do not edit.\"" label) lines)
          (push "  echo \"# Read by basilisk.service via EnvironmentFile.\"" lines)
          (when variant
            (push (format "  echo \"EMACS_IMAGE_VARIANT=%s\"" variant) lines))
          (dolist (pin port-pins)
            (push (format "  echo \"%s\"" pin) lines))
          (push "} > \"$TARGET_DIR/systemd/host.env\"" lines)
          (push "echo \"  wrote $TARGET_DIR/systemd/host.env\"" lines)
          (push "echo \"  install/refresh the units with: (cd $TARGET_DIR && sh systemd/install)\"" lines)
          (push "" lines))))

    (push "echo \"\"" lines)
    (push "echo \"Installation complete!\"" lines)
    (push "echo \"\"" lines)

    (string-join (nreverse lines) "\n")))

;;; ============================================================================
;;; THE DICTIONARY (glossary.sexp): ship register -> machinery keys
;;;
;;; The articles (services.sexp) are written in the ship register.  The
;;; glossary.sexp sitting BESIDE each articles file is what makes that
;;; mechanical rather than inventive: a flat plist of TERM MACHINERY-KEY
;;; pairs, substituted on the config immediately after reading, so every
;;; downstream generator (compose yaml, MCP json, elisp discovery,
;;; install script) sees the machinery keys it always saw and needs no
;;; changes at all.
;;;
;;; No glossary means the identity translation: a file already written
;;; in machinery keys generates unchanged, which is exactly what a
;;; corporate fork wants -- it replaces the articles and the dictionary
;;; together, and most of its dictionary entries map a term to itself.
;;;
;;; The one structural (non-rename) translation is :provenance +
;;; :species -> :image, because docker wants the two halves reunited as
;;; one reference; see `skewed--join-species'.

(defun skewed--load-glossary (services-file)
  "The glossary.sexp beside SERVICES-FILE, as a flat plist, or nil.
nil means the identity translation."
  (let ((f (expand-file-name "glossary.sexp"
                             (file-name-directory services-file))))
    (when (file-exists-p f)
      (skewed--read-sexp-file f))))

(defun skewed--translate-register (form glossary)
  "Substitute every keyword in FORM that GLOSSARY maps.
GLOSSARY is a flat plist (TERM MACHINERY-KEY ...).  Substitution is
position-blind -- any keyword anywhere in the tree -- which is why the
glossary contract says its terms may be used only as KEYS in the
articles, never as values."
  (if (null glossary) form
    (cond ((keywordp form) (or (plist-get glossary form) form))
          ((consp form) (cons (skewed--translate-register (car form) glossary)
                              (skewed--translate-register (cdr form) glossary)))
          (t form))))

(defun skewed--join-species (config)
  "Fold each service's :provenance + :species pair into docker's :image.
Species is the image type, repo:tag; provenance is the registry and/or
namespace it hails from -- its home planet, stripped from the species
and reattached only here, where docker insists on one reference.  A
service already carrying :image passes through untouched."
  (dolist (svc (skewed--get-prop config :services))
    (let ((species (plist-get svc :species))
          (provenance (plist-get svc :provenance)))
      (when (and species (not (plist-get svc :image)))
        (plist-put svc :image
                   (if provenance (concat provenance "/" species) species)))))
  config)

(defun skewed--read-articles (services-file)
  "Read SERVICES-FILE translated through its own glossary, species joined."
  (let ((config (skewed--read-sexp-file services-file)))
    (when config
      (skewed--join-species
       (skewed--translate-register
        config (skewed--load-glossary services-file))))))

(defun skewed--resolve-compose-defaults (s)
  "Resolve ${VAR:-default} to default and ${VAR} to \"\" in S.
Good enough for image references, which never nest expansions."
  (let ((out (replace-regexp-in-string
              "\\${[A-Za-z0-9_]+:-\\([^}]*\\)}" "\\1" (or s ""))))
    (replace-regexp-in-string "\\${[A-Za-z0-9_]+}" "" out)))

(defun skewed--lisp-impl (svc)
  "SVC's lisp implementation: declared if present, else derived.
Derived from the species -- the strain (tag half) names the engine
\(devo-ccl, devo-sbcl, devo-enterprise-smp-licensed), so a declared
copy could only ever disagree with the image it describes.  Same
argument that removed the :species label (2026-08-17).  An overlay may
still declare :lisp-impl for a species whose strain says nothing.
Order matters below: non-smp must precede smp, which would otherwise
swallow it."
  (or (skewed--get-prop svc :lisp-impl)
      (let* ((image (skewed--resolve-compose-defaults
                     (or (skewed--get-prop svc :image) "")))
             (tag (if (string-match ":\\([^:/]+\\)\\'" image)
                      (match-string 1 image) ""))
             (type (skewed--get-prop svc :type)))
        (cond ((equal type "emacs-lisp") "Emacs")
              ((string-match-p "non-smp" tag) "AllegroCL-Enterprise")
              ((string-match-p "smp" tag) "AllegroCL-SMP-Enterprise")
              ((string-match-p "ccl" tag) "CCL")
              ((string-match-p "sbcl" tag) "SBCL")
              ((equal type "reverse-proxy") "AllegroCL-Runtime")))))

(defvar skewed-gen-base-articles
  (let ((beside (expand-file-name
                 "services.sexp"
                 (file-name-directory (or load-file-name buffer-file-name
                                          default-directory)))))
    (if (file-exists-p beside) beside "/projects/basilisk/services.sexp"))
  "The base ship's articles: the crew aboard every Basilisk-class ship.
Board probe generation reads these alongside each watched stack's own
overlay, because an overlay declares only its deviation -- the Captain
whose heap a board watches is defined here, not in sally-stack.
Resolved at LOAD TIME beside this file, for the same
two-copies-of-the-yard reason the old fittings path was (see git
history); setq it after loading to point elsewhere.")

(defun skewed--merge-service (base over)
  "Merge service plist OVER onto BASE; OVER's keys win."
  (let ((out (copy-sequence base)))
    (cl-loop for (k v) on over by #'cddr do (setq out (plist-put out k v)))
    out))

;;; EYES ONLY HEAP PROBES FROM THE ARTICLES (2026-08-15, reworked 2026-08-17)
;;;
;;; The articles are the SSoT for who is aboard, so they are also the
;;; authority on what can be PROBED.  eyes-only's *heap-probes* was
;;; hand-maintained per board, which meant a probe could name a crew
;;; member who was never aboard the ship it points at -- and an absent
;;; optional post then presents as a permanently red tile rather than as
;;; nothing at all.  That is exactly shelly's 2026-08-14 symptom.
;;; Deriving the list from each ship's actual crew makes the failure
;;; impossible: no post, no probe, no tile.
;;;
;;; A :probe rides ON the crew entry that publishes it (the fitting
;;; catalogue that used to group these by post retired 2026-08-17).  A
;;; watched ship's crew is its base articles merged with its own overlay
;;; articles, overlay keys winning -- the same key-wise discipline
;;; compose applies to the generated yml.

(defun skewed--stack-crew (stack-dir)
  "The full crew of the ship at STACK-DIR: base articles + its overlay.
Overlay entries restating a base :name merge key-wise over the base
entry (so a deviation cannot silently shed the base's :probe).  NIL
when no articles are found at STACK-DIR."
  (let* ((over-file (expand-file-name "services.sexp" stack-dir))
         (over-config (and (file-exists-p over-file)
                           (skewed--read-articles over-file)))
         (over (and over-config (skewed--get-prop over-config :services)))
         (base-config (skewed--read-articles skewed-gen-base-articles))
         (base (and base-config (skewed--get-prop base-config :services)))
         (out '()))
    (when over-config
      (dolist (svc base)
        (let ((dev (seq-find (lambda (o) (equal (plist-get o :name)
                                                (plist-get svc :name)))
                             over)))
          (push (if dev (skewed--merge-service svc dev) svc) out)))
      (setq out (nreverse out))
      (dolist (o over)
        (unless (seq-find (lambda (svc) (equal (plist-get svc :name)
                                               (plist-get o :name)))
                          out)
          (setq out (append out (list o)))))
      out)))

(defun skewed--heap-probe-entries (config dir)
  "Build the eyes-only *heap-probes* list for the board declared in CONFIG.
Returns nil unless CONFIG's :meta carries an :eyes-only-board.

Each watch entry names a :stack and either :in-stack t (this board's own
ship, sampled over the docker bridge) or an :edge URL prefix reaching that
ship's token-gated metrics.  An optional :watch narrows which posts this
board cares about; it can never widen past what the target's crew
actually carries, which is the guarantee that kills phantom tiles."
  (let* ((meta (skewed--get-prop config :meta))
         (board (plist-get meta :eyes-only-board)))
    (when board
      (let ((root (file-name-directory (directory-file-name dir)))
            (out '()))
        (dolist (w board)
          (let* ((stack (plist-get w :stack))
                 (in-stack (plist-get w :in-stack))
                 (edge (plist-get w :edge))
                 (watch (plist-get w :watch))
                 (sdir (expand-file-name (concat stack "-stack/") root))
                 (crew (skewed--stack-crew sdir)))
            (unless crew
              (error "Board watches %s, but no articles found at %s"
                     stack sdir))
            (dolist (svc crew)
              (let* ((post (plist-get svc :post))
                     (probe (plist-get svc :probe))
                     ;; A probe with no :in-stack form contributes nothing
                     ;; to its own board -- the board self-samples its own
                     ;; image for the heap gendl-ccl tile.
                     (spec (and probe (if in-stack
                                          (plist-get probe :in-stack)
                                        (plist-get probe :remote)))))
                (when (and spec (or (null watch) (memq post watch)))
                  (unless (or in-stack edge)
                    (error "Board watch for %s is off-ship but declares no :edge"
                           stack))
                  (push (list (format "%s %s" (plist-get probe :tile) stack)
                              (plist-get spec :kind)
                              (or (plist-get spec :url)
                                  (concat edge (plist-get spec :path)))
                              (plist-get spec :alert-mb))
                        out))))
            (dolist (post watch)
              (unless (seq-find (lambda (svc) (eq (plist-get svc :post) post))
                                crew)
                (message "  Note (%s): board asks for %s, which is not aboard -- no probe emitted"
                         stack post)))))
        (nreverse out)))))

(defun skewed--generate-heap-probes-file (config dir)
  "Write eyes-only-probes-generated.lisp for a board stack, if it is one."
  (let ((probes (skewed--heap-probe-entries config dir)))
    (when probes
      (let ((file (expand-file-name "eyes-only-probes-generated.lisp" dir)))
        (with-temp-file file
          (insert ";;; eyes-only-probes-generated.lisp -*- mode: lisp -*-\n")
          (insert ";;; DO NOT EDIT -- generated from the fleet's Basilisk articles by\n")
          (insert ";;; basilisk/generate-configs.el.  Regenerate with:\n")
          (insert (format ";;;   (skewed-generate-configs \"%s\")\n" dir))
          (insert ";;;\n")
          (insert ";;; Every entry here corresponds to a post actually aboard the target\n")
          (insert ";;; ship, so a crew member who is not aboard cannot show up\n")
          (insert ";;; as a permanently red tile.  Change the fleet by editing the\n")
          (insert ";;; ships' articles, or this board's :eyes-only-board, in services.sexp.\n\n")
          (insert "(in-package :gdl-user)\n\n")
          (insert "(setq eyes-only::*heap-probes*\n      '(")
          (let ((first t))
            (dolist (p probes)
              (if first (setq first nil) (insert "\n        "))
              (insert (format "(%S %s %S %d)"
                              (nth 0 p) (nth 1 p) (nth 2 p) (nth 3 p)))))
          (insert "))\n"))
        (message "Generated: %s (%d probe(s))" file (length probes))
        probes))))

;;; ============================================================================

(defun skewed-generate-configs (&optional dir services-file prefix)
  "Generate all configs for directory DIR using SERVICES-FILE.

Generated files:
  - Compose YAML (docker-compose.yml or PREFIX-compose.yml)
  - MCP configs (container, windows, codex)
  - Emacs services discovery
  - Install script (for overlays only, when prefix is non-empty)  SERVICES-FILE - Path to services.sexp (default: \"services.sexp\" in DIR)
  PREFIX        - Output filename prefix (default: auto-derived from DIR basename)
                  Auto-derived: empty for 'skewed-emacs', 'basename-' for others

Examples:
  (skewed-generate-configs)                          ; Current dir, services.sexp
  (skewed-generate-configs \"/projects/betatest/\")   ; Betatest dir, auto-prefix
  (skewed-generate-configs nil \"/tmp/custom.sexp\") ; Current dir, custom file
  (skewed-generate-configs \"/tmp/foo/\" nil \"bar-\") ; Foo dir, override prefix"
  (let* ((skewed-gen-output-dir (expand-file-name (or dir default-directory)))
         (default-services-file (expand-file-name "services.sexp" skewed-gen-output-dir))
         (skewed-gen-input-file (expand-file-name (or services-file default-services-file)))
         ;; Auto-derive prefix from directory name if not provided
         ;; The BASE stack generates unprefixed (docker-compose.yml); host
         ;; overlays get "<host>-".  "basilisk" joins "skewed-emacs" as a
         ;; base name for the duration of the move, and outlives it.
         (auto-prefix (let ((basename (file-name-nondirectory
                                       (directory-file-name skewed-gen-output-dir))))
                        (if (member basename '("basilisk" "skewed-emacs"))
                            ""
                          (concat basename "-"))))
         (skewed-gen-output-prefix (if prefix prefix auto-prefix))
         ;; Read through the register dictionary: the articles may be in
         ;; the ship register (glossary.sexp beside them), and everything
         ;; downstream sees machinery keys either way.
         (config (skewed--read-articles skewed-gen-input-file))
         (mcp-dir (expand-file-name "mcp/" skewed-gen-output-dir))
         (elisp-dir (expand-file-name "dot-files/emacs.d/etc/" skewed-gen-output-dir)))
    
    (unless config
      (error "Could not read services file: %s" skewed-gen-input-file))
    
    ;; Ensure directories exist
    (make-directory mcp-dir t)
    (make-directory elisp-dir t)
    
    ;; Generate docker-compose.yml (or overlay yml)
    (let* ((compose-name (if (string-empty-p skewed-gen-output-prefix)
                             "docker-compose.yml"
                           (format "%scompose.yml" skewed-gen-output-prefix)))
           (compose-file (expand-file-name compose-name skewed-gen-output-dir)))
      (with-temp-file compose-file
        (insert (skewed--generate-compose-yaml config)))
      (message "Generated: %s" compose-file))
    
    ;; Generate MCP configs (only when services declare :mcp t)
    (when (skewed--has-mcp-services-p config)
      (make-directory mcp-dir t)
      (let ((container-json (expand-file-name 
                             (format "%smcp-container.json" skewed-gen-output-prefix) mcp-dir)))
        (with-temp-file container-json
          (insert "// DO NOT EDIT - Generated from services.sexp\n")
          (insert (skewed--generate-mcp-json-container config)))
        (message "Generated: %s" container-json))
    
      (let ((windows-json (expand-file-name 
                           (format "%smcp-windows.json" skewed-gen-output-prefix) mcp-dir)))
        (with-temp-file windows-json
          (insert "// DO NOT EDIT - Generated from services.sexp\n")
          (insert "// For Windows: merge with base config or copy to %APPDATA%\\Claude\\\n")
          (insert (skewed--generate-mcp-json-windows config)))
        (message "Generated: %s" windows-json))
    
      (let ((codex-toml (expand-file-name 
                         (format "%smcp.toml" skewed-gen-output-prefix) mcp-dir)))
        (with-temp-file codex-toml
          (insert "# Copyright © 2026 Gornskew Enterprises\n")
          (insert "#\n")
          (insert "# This program is free software: you can redistribute it and/or modify\n")
          (insert "# it under the terms of the GNU Affero General Public License as\n")
          (insert "# published by the Free Software Foundation, either version 3 of the\n")
          (insert "# License, or (at your option) any later version.  Distributed WITHOUT\n")
          (insert "# ANY WARRANTY; see <https://www.gnu.org/licenses/agpl-3.0.html>.\n\n")
          (insert "# DO NOT EDIT - Generated from services.sexp\n\n")
          (insert (skewed--generate-mcp-toml config)))
        (message "Generated: %s" codex-toml))
    ) ;; end when has-mcp-services

    ;; Generate Elisp services file (base or overlay, using prefix).
    ;;
    ;; Lands in generated/ ONLY.  This is yard output: it describes what the
    ;; stack composes to, is derived entirely from services.sexp, and has no
    ;; business in dot-files/, which is the Captain's Emacs configuration and
    ;; belongs to the skewed-emacs repo.  Keeping the two apart is what let
    ;; the stack machinery be lifted out of that repo cleanly.
    ;;
    ;; It reaches a running container by compose-dev copying it in; the
    ;; consumer, services-discovery.el, is unchanged and still reads it from
    ;; the container's own dot-files tree.
    (let* ((elisp-name (if (string-empty-p skewed-gen-output-prefix)
                           "services-generated.el"
                         (format "%sservices-generated.el" skewed-gen-output-prefix)))
           (generated-dir (expand-file-name "generated/" skewed-gen-output-dir))
           (elisp-file (expand-file-name elisp-name generated-dir)))
      (make-directory generated-dir t)
      (with-temp-file elisp-file
        (insert (skewed--generate-elisp config)))
      (message "Generated: %s" elisp-file))

    ;; Generate install script -- for host OVERLAYS only.  A base repo is
    ;; the thing you run the stack FROM, not something you install into
    ;; another checkout, so basilisk is excluded alongside skewed-emacs.
    (unless (member (file-name-nondirectory (directory-file-name skewed-gen-output-dir))
                    '("basilisk" "skewed-emacs"))
      (let ((install-file (expand-file-name "install" skewed-gen-output-dir)))
        (with-temp-file install-file
          (insert (skewed--generate-install-script
                   skewed-gen-output-prefix
                   (skewed--has-mcp-services-p config)
                   (plist-get (skewed--get-prop config :meta) :image-variant)
                   (skewed--ingress-port-pins config))))
        (set-file-modes install-file #o755)
        (message "Generated: %s" install-file)))

    ;; Eyes Only heap probes, for a stack that declares itself a board.
    ;; Reads the OTHER ships' rosters, so it runs last.
    (skewed--generate-heap-probes-file config skewed-gen-output-dir)

    (message "=== Generation complete ===")))

(defun skewed-generate-all-configs ()
  "Generate all configs from services.sexp in current directory.
This is a convenience wrapper around skewed-generate-configs.
Automatically derives prefix from directory basename (empty for 'skewed-emacs').

For more control, use skewed-generate-configs directly."
  (interactive)
  (skewed-generate-configs))

(provide 'generate-configs)
;;; generate-configs.el ends here
