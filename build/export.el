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

(defvar ib/export-failures nil)

(defun ib/export-file (path)
  "Export a single Org file at PATH to Markdown via ox-hugo.
A failure is logged but does not abort the whole run; the batch exits
non-zero at the end if any file failed."
  (message "ox-hugo: exporting %s" (file-relative-name path default-directory))
  (condition-case err
      (with-current-buffer (find-file-noselect path)
        (org-hugo-export-to-md))
    (error
     (push (file-relative-name path default-directory) ib/export-failures)
     (message "ox-hugo: FAILED %s: %S" (file-relative-name path default-directory) err))))

;; Homepage / about page.
(ib/export-file (expand-file-name "index.org" default-directory))

;; Resume (HTML version; the PDF is built separately by resume.el).
(ib/export-file (expand-file-name "resume/resume.org" default-directory))

;; Blog posts.
(dolist (f (sort (directory-files
                  (expand-file-name "blog" default-directory) t "\\.org\\'")
                 #'string<))
  (ib/export-file f))

(when ib/export-failures
  (message "ox-hugo: %d file(s) failed: %s"
           (length ib/export-failures)
           (string-join ib/export-failures ", "))
  (kill-emacs 1))
(message "ox-hugo: export complete")
