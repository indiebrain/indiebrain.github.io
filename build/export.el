;;; export.el --- Batch ox-hugo export -*- lexical-binding: t; -*-
;;
;; Exports the Org sources to Hugo-flavored Markdown under content/.
;; Run from the repository root:  emacs --batch -Q -l build/export.el
;;
;; ox-hugo (and its dependency tomelr) are installed into a
;; project-local .elpa/ directory so this never touches a developer's
;; global Emacs configuration and runs identically in CI.

(require 'package)
(setq package-user-dir (expand-file-name ".elpa" default-directory))
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)
(unless (package-installed-p 'ox-hugo)
  (package-refresh-contents)
  (package-install 'ox-hugo))
(require 'ox-hugo)

;; Copy referenced images into static/images/ (public URL /images/...)
;; rather than the default static/ox-hugo/, so the build tool never
;; leaks into public URLs.
(setq org-hugo-default-static-subdirectory-for-externals "images")

(defun ib/export-file (path)
  "Export a single Org file at PATH to Markdown via ox-hugo."
  (message "ox-hugo: exporting %s" (file-relative-name path default-directory))
  (with-current-buffer (find-file-noselect path)
    (org-hugo-export-to-md)))

;; Homepage / about page.
(ib/export-file (expand-file-name "index.org" default-directory))

;; Blog posts.
(dolist (f (sort (directory-files
                  (expand-file-name "blog" default-directory) t "\\.org\\'")
                 #'string<))
  (ib/export-file f))

(message "ox-hugo: export complete")
