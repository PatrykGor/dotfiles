;; -*- lexical-binding: t -*-
;; Ensure Emacs loads the most recent byte-compiled files.
(setq load-prefer-newer t)

;; Make Emacs Native-compile .elc files asynchronously by setting
;; `native-comp-jit-compilation' to t.
(setq native-comp-jit-compilation t)

(setq package-enable-at-startup nil)

(tool-bar-mode -1)
(scroll-bar-mode -1)
