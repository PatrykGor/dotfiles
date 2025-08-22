;; -*- lexical-binding: t -*-
(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

(use-package compile-angel
  :ensure t
  :demand t
  :config
  ;; Set `compile-angel-verbose' to nil to disable compile-angel messages.
  ;; (When set to nil, compile-angel won't show which file is being compiled.)
  (setq compile-angel-verbose nil)

  ;; A global mode that compiles .el files before they are loaded
  ;; using `load' or `require'.
  (compile-angel-on-load-mode 1))

(use-package exwm
  :ensure nil
  :custom
  (exwm-workspace-number 3)
  (exwm-workspace-warp-cursor t)
  (mouse-autoselect-window t)
  (focus-follows-mouse t)
  (exwm-workspace-number 3)
  (exwm-manage-configurations '((t char-mode t)))
  (exwm-input-global-keys
   `(([?\s-r] . exwm-reset)
     ([?\s-1] . (lambda () (interactive) (exwm-workspace-switch 0)))
     ([?\s-2] . (lambda () (interactive) (exwm-workspace-switch 1)))
     ([?\s-3] . (lambda () (interactive) (exwm-workspace-switch 2)))
     ([?\s-h] . windmove-left)
     ([?\s-j] . windmove-down)
     ([?\s-k] . windmove-up)
     ([?\s-l] . windmove-right)
     ([?\s-q] . kill-buffer-and-window)
     ([?\s-w] . consult-omni-knowledge)
     ([?\s-f] . consult-omni-local)
     (, (kbd "s-SPC") . meow-keypad)
     ([?\s-e] . consult-omni-app)))
  (exwm-layout-show-all-buffers t)
  (exwm-workspace-show-all-buffers t)
    :init
  (defun +exwm-rename-buffer ()
    (interactive)
    (exwm-workspace-rename-buffer
     (concat exwm-class-name ":"
  	   (if (<= (length exwm-title) 50) exwm-title
  	     (concat (substring exwm-title 0 49) "...")))))
    
  (add-hook 'exwm-update-class-hook #'+exwm-rename-buffer)
  (add-hook 'exwm-update-title-hook #'+exwm-rename-buffer)
  :config
  (exwm-wm-mode))

(use-package exwm-randr
  :ensure nil
  :after exwm
  :custom
  (exwm-randr-workspace-monitor-plist
   '(0 "eDP-1" 1 "DP-2-1" 2 "DP-2-3"))
  :config
  (exwm-randr-mode))

(use-package meow
  :ensure t
  :custom
  (meow-goto-line-function #'consult-goto-line)
  :init
  (defun meow-setup ()
    (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
    (meow-motion-define-key
     '("j" . meow-next)
     '("k" . meow-prev)
     '("<Escape>" . ignore))
    (meow-leader-define-key
     ;; Use SPC (0-9) for digit arguments.
     '("1" . meow-digit-argument)
     '("2" . meow-digit-argument)
     '("3" . meow-digit-argument)
     '("4" . meow-digit-argument)
     '("5" . meow-digit-argument)
     '("6" . meow-digit-argument)
     '("7" . meow-digit-argument)
     '("8" . meow-digit-argument)
     '("9" . meow-digit-argument)
     '("0" . meow-digit-argument)
     '(":" . "M-x")
     '("RET" . embark-act)
     '("/" . meow-keypad-describe-key)
     '("?" . meow-cheatsheet))
    (meow-normal-define-key
     '(":" . "M-x")
     '("<return>" . embark-dwim)
     '("9" . meow-expand-9)
     '("8" . meow-expand-8)		;
     '("7" . meow-expand-7)
     '("6" . meow-expand-6)
     '("5" . meow-expand-5)
     '("4" . meow-expand-4)
     '("3" . meow-expand-3)
     '("2" . meow-expand-2)
     '("1" . meow-expand-1)
     '("-" . negative-argument)
     '(";" . meow-reverse)
     '("#" . comment-dwim)
     '("C-e" . meow-inner-of-thing)
     '("C-a" . meow-bounds-of-thing)
     '("[" . meow-beginning-of-thing)
     '("]" . meow-end-of-thing)
     '("a" . meow-append)
     '("o" . meow-open-below)
     '("b" . meow-back-word)
     '("B" . meow-back-symbol)
     '("c" . meow-change)
     '("x" . meow-delete)
     '("X" . meow-backward-delete)
     '("w" . meow-next-word)
     '("W" . meow-next-symbol)
     '("f" . meow-find)
     '("<escape>" . meow-cancel-selection)
     '("g" . meow-grab)
     '("h" . meow-left)
     '("H" . meow-left-expand)
     '("i" . meow-insert)
     '("O" . meow-open-above)
     '("j" . meow-next)
     '("J" . meow-next-expand)
     '("k" . meow-prev)
     '("K" . meow-prev-expand)
     '("l" . meow-right)
     '("L" . meow-right-expand)
     '("m" . meow-join)
     '("n" . meow-search)
     '("e" . meow-block)
     '("E" . meow-to-block)
     '("p" . meow-yank)
     '("q" . meow-quit)
     '("g" . meow-goto-line)
     '("r" . meow-replace)
     '("R" . meow-swap-grab)
     '("d" . meow-kill)
     '("F" . meow-till)
     '("u" . meow-undo)
     '("U" . meow-undo-in-selection)
     '("/" . meow-visit)
     '("v" . meow-mark-symbol)
     '("V" . meow-line)
     '("y" . meow-save)
     '("I" . (lambda () (interactive) (meow-beginning-of-thing ?l) (meow-insert-mode)))
     '("A" . (lambda () (interactive) (meow-end-of-thing ?l) (meow-insert-mode)))
     '("G" . (lambda () (interactive) (meow-end-of-thing ?b)))
     '("0" . (lambda () (interactive) (meow-beginning-of-thing ?l)))
     '("$" . (lambda () (interactive) (meow-end-of-thing ?l)))
     '(">" . meow-indent)
     '("Y" . meow-sync-grab)
     '("z" . meow-pop-selection)
     '("." . repeat)))
  :config
  (meow-setup)
  (meow-global-mode 1)
  (add-hook 'meow-keypad-mode-hook (lambda ()
				     (when (derived-mode-p 'exwm-mode)
				       (if meow-keypad-mode
					   (exwm-input-grab-keyboard exwm--id)
					 (exwm-input-release-keyboard exwm--id))))))

(use-package nix-mode
  :ensure t
  :mode ("\\.nix\\'" "\\.nix.in\\'"))
(use-package nix-drv-mode
  :ensure nil
  :mode "\\.drv\\'")
(use-package nix-shell
  :ensure nil
  :commands (nix-shell-unpack nix-shell-configure nix-shell-build))
(use-package nix-repl
  :ensure nil
  :commands (nix-repl))
(use-package nix-search
  :ensure nil
  :commands (nix-search))
  
(use-package lsp-mode
  :ensure t
  :custom
  (lsp-keymap-prefix "C-c l")
  (lsp-completion-provider :none) ;; we use Corfu!
  (lsp-nix-nixd-server-path "nixd")
  (lsp-nix-nixd-formatting-command [ "nixfmt" ])
  (lsp-nix-nixd-nixpkgs-expr "import <nixpkgs> { }")
  (lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/home/patryk/.config/nixos\").nixosConfigurations.patryk-laptop.options")
  (lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/home/patryk/.config/nixos\").nixosConfigurations.patryk-laptop.options.home-manager.users.type.getSubOptions []")
  (lsp-headerline-breadcrumb-enable nil)
  :init
  (defun +orderless-dispatch-flex-first (_pattern index _total)
    (and (eq index 0) 'orderless-flex))

  (defun +lsp-mode-setup-completion ()
    (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
          '(orderless))
    (add-hook 'orderless-style-dispatchers #'+orderless-dispatch-flex-first nil 'local)
    (setq-local completion-at-point-functions (list (cape-capf-buster #'lsp-completion-at-point))))
  :hook (
         (nix-mode . lsp-deferred)
	 (lsp-completion-mode . +lsp-mode-setup-completion)
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp)

(use-package lsp-ui
  :ensure t
  :custom
  (lsp-ui-doc-show-with-cursor t)
  (lsp-ui-doc-position 'at-point)
  :commands lsp-ui-mode)

;; optionally if you want to use debugger
;; (use-package dap-mode)
;;   (use-package dap-LANGUAGE) to load the dap adapter for your language

;; optional if you want which-key integration
(use-package which-key
  :ensure nil
  :config
  (which-key-mode))

(use-package cape
  :ensure t)

(use-package orderless
  :ensure t
  :init
  ;; Tune the global completion style settings to your liking!
  ;; This affects the minibuffer and non-lsp completion at point.
  (setq completion-styles '(orderless partial-completion basic)
        completion-category-defaults nil
        completion-category-overrides nil))

(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)          ;; Enable auto completion
  :bind
  (:map corfu-map
	("C-j" . corfu-next)
	("C-k" . corfu-previous)
	("C-SPC" . corfu-insert-separator))
  :init
  (defun +advise-corfu-make-frame-with-monitor-awareness (orig-fun frame x y width height)
    "Advise `corfu--make-frame` to be monitor-aware, adjusting X and Y according to the focused monitor."
    ;; Get the geometry of the currently focused monior
    (let* ((selected-frame-position (frame-position))
           (selected-frame-x (car selected-frame-position))
           (selected-frame-y (cdr selected-frame-position))
           (new-x (+ selected-frame-x x))
           (new-y (+ 30 selected-frame-y y)))

      (funcall orig-fun frame new-x new-y width height)))
  (global-corfu-mode)
  :config
  (advice-add 'corfu--make-frame :around #'+advise-corfu-make-frame-with-monitor-awareness))

(use-package vertico
  :ensure t
  :custom
  (vertico-resize t)
  (context-menu-mode t)
  (enable-recursive-minibuffers t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt))
  (vertico-cycle t)
  :bind
  (:map vertico-map
	("C-j" . vertico-previous)
	("C-k" . vertico-next)
  	("C-n" . vertico-previous-group)
	("C-p" . vertico-next-group))

  :init
  (vertico-mode)
  :config
  (vertico-reverse-mode)
  (vertico-multiform-mode)
  (add-to-list 'vertico-multiform-categories '(embark-keybinding grid)))

(use-package savehist
  :ensure nil
  :init
  (savehist-mode))

(use-package marginalia
  :ensure t
  :bind (:map minibuffer-local-map
         ("C-a" . marginalia-cycle))
  :init
  (marginalia-mode))

(use-package embark
  :ensure t
  :commands
  (embark-act
   embark-dwim
   embark-export)
  :bind
  (:map minibuffer-local-map
              ("C-<return>" . embark-act)
	      ("C-e" . embark-export))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  (context-menu-mode 1)
  (add-hook 'context-menu-functions #'embark-context-menu 100)
  :custom
  (embark-indicators
      '(embark-minimal-indicator  ; default is embark-mixed-indicator
        embark-highlight-indicator
        embark-isearch-highlight-indicator))
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :ensure t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package consult
  :ensure t
  :demand t
  :bind (([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)                  ;; Alternative: consult-fd
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
	 :map mode-specific-map
	 ("f x" . consult-mode-command)
         ("f h" . consult-history)
         ("f k" . consult-kmacro)
         ("f m" . consult-man)
         ("f i" . consult-info)
	 ("f f" . find-file)
	 ("f b" . consult-buffer)                ;; orig. switch-to-buffer
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history))                ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :custom
  (register-preview-delay 0.5)
  (consult-narrow-key "<") ;; "C-+"
  (consult-preview-excluded-buffers '(major-mode . exwm-mode))
  ;; Use Consult to select xref locations with preview
  (xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :init
  (advice-add #'register-preview :override #'consult-register-window)
  (defun +consult-find-file-with-preview (prompt &optional dir default mustmatch initial pred)
    (interactive)
    (let ((default-directory (or dir default-directory))
          (minibuffer-completing-file-name t))
      (consult--read #'read-file-name-internal :state (consult--file-preview)
                     :prompt prompt
                     :initial initial
                     :require-match mustmatch
                     :predicate pred)))
  (setq read-file-name-function #'+consult-find-file-with-preview))

(use-package helpful
  :ensure t
  :bind
  (("C-h C-f" . helpful-callable)
   ("C-h C-v" . helpful-variable)
   ("C-h C-k" . helpful-key)
   ("C-h C-p" . elpaca-visit)
   ("C-h C-x" . helpful-command)
   :map emacs-lisp-mode-map
   ([remap describe-symbol] . helpful-at-point)))
  
(use-package dired-auto-readme
  :ensure (:host github :repo "amno1/dired-auto-readme")
  :hook (dired-mode . dired-auto-readme-mode))

(use-package nerd-icons
  :ensure t)

(use-package doom-modeline
  :ensure t
  :after nerd-icons
  :init (doom-modeline-mode 1))

(use-package bitwarden
  :ensure (:host github :repo "seanfarley/emacs-bitwarden")
  :after exwm-randr
  :custom
  (bitwarden-user "patryk@gorscy.net")
  :init
  (defun pinentry-emacs (desc prompt ok error)
    (let ((str (read-passwd (concat (replace-regexp-in-string "%22" "\"" (replace-regexp-in-string "%0A" "\n" desc)) prompt ": "))))
      str))
  (setq bitwarden-automatic-unlock
        (let* ((matches (auth-source-search :host "vault.bitwarden.com"
                                            :require '(:secret)
                                            :max 1))
               (entry (nth 0 matches)))
          (plist-get entry :secret)))
  (setq bitwarden-api-secret-key
        (plist-get (car (auth-source-search :host "bitwarden.key"))
                   :secret))
  (setq bitwarden-api-client-id
        (plist-get (car (auth-source-search :host "bitwarden.id"))
                   :secret))
  :config
  (bitwarden-auth-source-enable)
  (bitwarden-login)
  (bitwarden-unlock))

(use-package password-menu
  :ensure t
  :demand t
  :bind (:map mode-specific-map
	      ("f p" . password-menu-completing-read)))

(use-package transient :ensure t)

(use-package gptel
  :ensure t
  :after password-menu
  :custom
  (gptel-default-mode #'org-mode)
  (gptel-include-reasoning nil)
  :bind
  (:map mode-specific-map
	("a s" . gptel-send)
	("a m" . gptel-menu)
	("a r" . gptel-rewrite)
	("a c" . gptel))
  :config
  (setq
   gptel-model 'gemini-2.5-pro
   gptel-backend (gptel-make-gemini "Gemini"
		   :key (password-menu-fetch-password :host "api.aistudio.google.com"))))

(use-package catppuccin-theme
  :ensure t
  :custom
  (catppuccin-flavor 'macchiato)
  :config
  (load-theme 'catppuccin :no-confirm))

(use-package magit
  :ensure t
  :bind (:map mode-specific-map
	      ("g g" . magit-status)
	      ("g d" . magit-dispatch)
	      ("g f" . magit-file-dispatch)))

(use-package consult-omni
  :ensure (:host github :repo "armindarvish/consult-omni" :files (:defaults "sources/*.el"))
  :after (consult password-menu)
  :commands
  (consult-omni-knowledge
   consult-omni-app
   consult-omni-local)
  :bind
  (:map mode-specific-map
	("f p" . consult-omni-projects)
	("f f" . consult-omni-project))
  :custom
  ;;; General settings that apply to all sources
  (consult-omni-show-preview t) ;;; show previews
  (consult-omni-preview-key "C-o") ;;; set the preview key to C-o
  (consult-omni-highlight-matches-in-minibuffer t) ;;; highlight matches in minibuffer
  (consult-omni-gptel-model 'gemini-2.5-flash)
  (consult-omni-projects-vc-backend 'magit)
  (consult-omni-projects-default-project-folder "~/Projects")
  :config
  (setq consult-omni-stackexchange-api-key (password-menu-fetch-password :host "api.stackexchange.com"))
  (setq consult-omni-scopus-api-key (password-menu-fetch-password :host "api.elsevier.com"))
  (setq consult-omni-google-customsearch-key (password-menu-fetch-password :host "api.customsearch.google.com"))
  (setq consult-omni-google-customsearch-cx (password-menu-fetch-password :host "cx.customsearch.google.com"))
  (setq consult-omni-sources-modules-to-load (list
					      'consult-omni-apps
					      'consult-omni-google
					      'consult-omni-google-autosuggest
					      'consult-omni-buffer
					      'consult-omni-calc
					      ;; 'consult-omni-consult-notes
					      'consult-omni-dict
					      ;; 'consult-omni-gh
					      'consult-omni-gptel
					      'consult-omni-git-grep
					      'consult-omni-ripgrep-all
					      'consult-omni-find
					      'consult-omni-locate
					      'consult-omni-line-multi
					      'consult-omni-man
					      'consult-omni-projects
					      'consult-omni-scopus
					      'consult-omni-stackoverflow
					      'consult-omni-wikipedia))
  (require 'consult-omni-sources)
  ;;; Load Sources Core code
  (consult-omni-sources-load-modules)
  ;;; Load Embark Actions
  (require 'consult-omni-embark)
  ;; consult-omni-web
  (defvar consult-omni-knowledge-sources (list
					  "gptel"
					  "calc"
					  ;; "man"
                                          "Dictionary"
					  "Google"
					  "Google AutoSuggest"
					  ;; "consult-notes"
					  "StackOverflow"
                                          "Wikipedia"
                                          ;; "GitHub"
					  "Scopus"
                                          ;; "Invidious"
                                          ))
  (defun consult-omni-knowledge (&optional initial prompt sources no-callback &rest args)
    "Interactive knowledge search”

This is similar to `consult-omni-multi', but runs the search on
sources defined in `consult-omni-knowledge-sources'.
See `consult-omni-multi' for more details.
"
    (interactive "P")
    (let ((prompt (or prompt (concat "[" (propertize "Knowledge" 'face 'consult-omni-prompt-face) "]" " Search:  ")))
          (sources (or sources consult-omni-knowledge-sources)))
      (consult-omni-multi initial prompt sources no-callback args)))

  (defun +consult-omni--find-project-builder (input &rest args &key callback &allow-other-keys)
    (pcase-let* ((`(,query . ,opts) (consult-omni--split-command input (seq-difference args (list :callback callback))))
               (opts (car-safe opts))
               (count (plist-get opts :count))
               (hidden (if (plist-member opts :hidden) (plist-get opts :hidden) consult-omni-find-show-hidden-files))
               (ignore (plist-get opts :ignore))
               (ignore (if ignore (format "%s" ignore)))
               (dir (project-root (project-current)))
               (dir (if dir (file-truename (format "%s" dir))))
               (count (or (and count (integerp (read count)) (string-to-number count))
                          consult-omni-default-count))
               (default-directory (or dir default-directory))
               (`(_ ,paths _) (consult--directory-prompt "" dir))
               (paths (if dir
                          (mapcar (lambda (path) (file-truename (concat dir path))) paths)
                        paths))
               (consult-find-args (concat consult-omni-find-args
                                          (if (not hidden) " -not -iwholename *./[a-z]*")
                                          (if ignore (concat " -not -iwholename *" ignore "*")))))
    (funcall (consult--find-make-builder paths) query)))

  (consult-omni-define-source "find-project"
                            :narrow-char ?f
                            :category 'file
                            :type 'async
                            :require-match t
                            :face 'consult-omni-engine-title-face
                            :request #'+consult-omni--find-project-builder
                            :transform #'consult-omni--find-transform
                            :filter #'consult-omni--find-filter
                            :on-preview #'consult-omni--find-preview
                            :on-return #'identity
                            :on-callback #'consult-omni--find-callback
                            :preview-key consult-omni-preview-key
                            :search-hist 'consult-omni--search-history
                            :select-hist 'consult-omni--selection-history
                            :group #'consult-omni--group-function
                            :sort t
                            :interactive consult-omni-intereactive-commands-type
                            :enabled (lambda () (executable-find "find"))
                            :annotate nil)
  
  (defvar consult-omni-project-sources (list
				      "Project Buffer"
				      "Project File"
				      "git-grep"
				      "find-project"
                                      ))
  (defun consult-omni-project (&optional initial prompt sources no-callback &rest args)
    "Interactive in-project search”

This is similar to `consult-omni-multi', but runs the search on
sources defined in `consult-omni-project-sources'.
See `consult-omni-multi' for more details.
"
    (interactive "P")
    (let ((prompt (or prompt (concat "[" (propertize "Project" 'face 'consult-omni-prompt-face) "]" " Search:  ")))
          (sources (or sources consult-omni-project-sources)))
      (consult-omni-multi initial prompt sources no-callback args)))

    (defvar consult-omni-local-sources (list
					"Buffer"
					"buffers text search"
					"Bookmark"
					"File"
					"locate"
					"ripgrep-all"
                                      ))
  (defun consult-omni-local (&optional initial prompt sources no-callback &rest args)
    "Interactive local sources search”

This is similar to `consult-omni-multi', but runs the search on
sources defined in `consult-omni-local-sources'.
See `consult-omni-multi' for more details.
"
    (interactive "P")
    (let ((prompt (or prompt (concat "[" (propertize "System" 'face 'consult-omni-prompt-face) "]" " Search:  ")))
          (sources (or sources consult-omni-local-sources)))
      (consult-omni-multi initial prompt sources no-callback args)))

  (defun +consult-omni--nixpkgs-builder (input &rest args &key callback &allow-other-keys)
    (pcase-let* ((`(,query . ,opts) (consult-omni--split-command input (seq-difference args (list :callback callback)))))
      (list "nix-search" "--json" query)))

  (defun +consult-omni--nixpkgs-pre-transform (lines)
    (json-read-from-string (mapconcat 'identity lines)))
		     
  (defun +consult-omni--nixpkgs-transform (candidates &optional query)
    (mapcar (lambda (item)
              (let*
                  ((source "nixpkgs")
                   (path (alist-get 'path item))
		   (title (alist-get 'name item))
                   (snippet (alist-get 'description item))
		   (exec (alist-get 'mainProgram item))
		   (visible t)
                   (decorated (funcall #'consult-omni--apps-format-candidates :source source :query query :title title :path path :snippet snippet :visible visible)))
                (propertize decorated
                            :source source
                            :title title
                            :url nil
                            :search-url nil
                            :query query
			    :path path
			    :exec exec
			    :app title
                            :snippet snippet)))
	    (+consult-omni--nixpkgs-pre-transform candidates)))

  (defun +consult-omni--nixpkgs-callback (cand)
    (let ((app (get-text-property 0 :app cand)))
      (nix-eshell-with-packages (list (format "%s" app)))))
      
  (consult-omni-define-source "Nixpkgs"
			      :narrow-char ?n
			      :type 'async
			      :request #'+consult-omni--nixpkgs-builder
			      :transform #'+consult-omni--nixpkgs-transform
			      :on-preview #'ignore
                              :on-return #'+consult-omni--nixpkgs-callback
			      :min-input 3
			      :annotate nil
			      :require-match t
			      :enabled t
			      :sort t
			      :group #'consult-omni--group-function
			      :preview-key consult-omni-preview-key
			      :search-hist 'consult-omni--search-history
			      :select-hist 'consult-omni--apps-select-history
			      :interactive consult-omni-intereactive-commands-type)
			      
  (defvar consult-omni-app-sources (list
				    "Nixpkgs"
				    "Apps"
                                    ))
  (defun consult-omni-app (&optional initial prompt sources no-callback &rest args)
    "Interactive apps and packages search”

This is similar to `consult-omni-multi', but runs the search on
sources defined in `consult-omni-app-sources'.
See `consult-omni-multi' for more details.
"
    (interactive "P")
    (let ((prompt (or prompt (concat "[" (propertize "App" 'face 'consult-omni-prompt-face) "]" " Search:  ")))
          (sources (or sources consult-omni-app-sources)))
      (consult-omni-multi initial prompt sources no-callback args))))

(use-package emacs
  :ensure nil
  :init
  (setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
  (setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t))))
