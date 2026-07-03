;;; resume.el --- Build the resume PDF -*- lexical-binding: t; -*-
;;
;; Exports resume/resume.org to PDF via LaTeX and places it at
;; static/resume/resume.pdf, so Hugo publishes it verbatim to
;; /resume/resume.pdf (the URL the old site served).
;;
;; Run from the repository root:  emacs --batch -Q -l build/resume.el

(require 'org)
(require 'ox-latex)

;; The resume is plain text with links. Trim Org's default LaTeX package
;; set to the minimum it needs (dropping graphicx, wrapfig, amsmath,
;; etc.) so CI needs only a tiny TeX Live install. The resume's own
;; helvet/parskip/geometry come from its #+LATEX_HEADER lines.
(setq org-latex-default-packages-alist
      '(("T1" "fontenc" t)
        ("" "hyperref" nil)))

(let* ((root default-directory)
       (src (expand-file-name "resume/resume.org" root))
       (out-dir (expand-file-name "static/resume" root))
       (dest (expand-file-name "resume.pdf" out-dir)))
  (make-directory out-dir t)
  (with-current-buffer (find-file-noselect src)
    (let ((pdf (org-latex-export-to-pdf)))
      (rename-file pdf dest t)
      (message "resume: built %s" (file-relative-name dest root)))))
