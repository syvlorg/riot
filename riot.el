;;; riot.el --- a simple package                     -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Jeet Ray

;; Author: Jeet Ray <aiern@protonmail.com>
;; Keywords: lisp
;; Version: 0.0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Put a description of the package here

;;; Code:

(require 'meq)
(require 'dash)
(require 's)
(require 'ox-pandoc)

;; Adapted From:
;; Answer: https://emacs.stackexchange.com/a/3402/31428
;; User: https://emacs.stackexchange.com/users/105/drew
(add-to-list 'org-pandoc-extensions '(asciidoc . adoc))

(defvar meq/var/riot-list nil)
(defvar meq/var/riot-elist '(
    (asciidoc . adoc)
    (docbook5 . dbk)
    (dokuwiki . doku)
    (epub3 . epub)
    (gfm . md)
    (haddock . hs)
    (html5 . html)
    (latex . tex)
    (opendocument . xml)
    (plain . txt)
    (texinfo . texi)
    (zimwiki . zim)))
(defvar meq/var/riot-alist nil)

(defun meq/org-pandoc-export-advice (format a s v b e &optional buf-or-open)
  "General interface for Pandoc Export.
If BUF-OR-OPEN is nil, output to file.  0, then open the file.
t means output to buffer."
  (unless (derived-mode-p 'org-mode)
    (error "You must run this command in org-mode."))
  (unless (executable-find org-pandoc-command)
    (error "Pandoc (version 1.12.4 or later) can not be found."))
  (setq org-pandoc-format format)
  (org-export-to-file 'pandoc (org-export-output-file-name
                               (concat (make-temp-name ".tmp") ".org") s)
    a s v b e (lambda (f) (org-pandoc-run-to-buffer-or-file f format s buf-or-open))))

(advice-add #'org-pandoc-export :override #'meq/org-pandoc-export-advice)

;;;###autoload
(defun meq/update-elist (econs) (add-to-list 'meq/var/riot-elist econs))

;;;###autoload
(defun meq/get-ext-name-from-file nil (interactive) (cdr (assoc buffer-file-name meq/var/riot-list)))

;;;###autoload
(defun meq/get-ext-name-from-ext (&optional ext) (interactive) (car (rassoc (or ext (meq/get-ext)) meq/var/riot-elist)))

(defun meq/after-shave nil
    (let* ((ext-name (meq/get-ext-name-from-file))
	    ;; (ext (symbol-name (cdr (assoc ext-name meq/var/riot-elist))))
	    ;; (split-bfn (split-string buffer-file-name "\\."))
            ;; (input (s-chop-suffix "." (string-join (append (butlast split-bfn 2) (list (meq/timestamp) ext)) ".")))
            ;; (output (s-chop-suffix "." (string-join (append (butlast split-bfn 2) (list ext)) ".")))
)
        (when ext-name
            (funcall (meq/inconcat "org-pandoc-export-to-" (symbol-name ext-name)))
	    ;; (rename-file input output t)
            (while (equal (process-status (car (last (process-list)))) 'run)))))
(add-hook 'after-save-hook #'meq/after-shave)

(defun meq/before-kill-buffer nil (interactive) (when (meq/get-ext-name-from-file) (delete-file buffer-file-name)))
(add-hook 'kill-buffer-hook #'meq/before-kill-buffer)

(defun meq/before-kill-emacs nil (interactive)
    (mapc #'(lambda (fcons) (interactive) (kill-buffer (get-file-buffer (car fcons)))) meq/var/riot-list))
(add-hook 'kill-emacs-hook #'meq/before-kill-emacs)

(defun meq/ffns-advice (func &rest args)
    (let* ((input-buffer (apply func args))
            (input (pop args))
            (split-input (split-string input "\\."))
            (ext (car (last split-input)))
            (ext-name (meq/get-ext-name-from-ext (intern ext)))
            ;; (output (s-chop-suffix "." (string-join (append (butlast split-input) (list (meq/timestamp) "org")) "."))))
            (output (s-chop-suffix "." (string-join (append (butlast split-input) (list "org")) "."))))
	(if (not (and (rassoc (intern ext) meq/var/riot-elist) (not (string= ext "org"))))
            input-buffer
            (apply #'call-process "pandoc" nil nil nil input "-f" (symbol-name ext-name) "-t" "org" "-so" output meq/var/riot-alist)
            (add-to-list 'meq/var/riot-list `(,output . ,ext-name))
            (apply func `(,output ,@args)))))

;; (add-hook 'emacs-startup-hook (lambda nil (interactive) (advice-add #'find-file-noselect :around #'meq/ffns-advice)))
(advice-add #'find-file-noselect :around #'meq/ffns-advice)

(provide 'riot)
;;; riot.el ends here
