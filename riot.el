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

(require 'a)
(require 'dash)
(require 's)
(require 'f)

;; Adapted From:
;; Answer: https://emacs.stackexchange.com/a/3402/31428
;; User: https://emacs.stackexchange.com/users/105/drew
(with-eval-after-load 'ox-pandoc (add-to-list 'org-pandoc-extensions '(asciidoc . adoc)))

;;;###autoload
(defun meq/timestamp nil (interactive) (format-time-string "%Y%m%d%H%M%S%N"))

(defvar meq/var/riot-list nil)
(defvar meq/var/riot-elist '(
    (asciidoc . adoc)
    (creole . creole)
    (csv . csv)
    (docbook5 . dbk)
    (docx . docx)
    (dokuwiki . doku)
    (epub3 . epub)
    (fb2 . fb2)
    (gfm . md)
    (haddock . hs)
    (html5 . html)
    (icml . icml)
    (ipynb . ipynb)
    (jira . jira)
    (json . json)
    (latex . tex)
    (mediawiki . mediawiki)
    (man . roff)
    (muse . muse)
    (native . ihs)
    (odt . odt)
    (opml . opml)
    (opendocument . xml)
    (org . org)
    (plain . txt)
    (rtf . rtf)
    (rst . rst)
    (t2t . t2t)
    (tei . tei)
    (texinfo . texi)
    (textile . textile)
    (twiki . twiki)
    (zimwiki . zim)))
(defvar meq/var/riot-alists (mapcar #'(lambda (econs) (interactive) (cons (car econs) nil)) meq/var/riot-elist))

;;;###autoload
(defun meq/update-elist (&rest econs) (apply #'a-assoc 'meq/var/riot-elist econs))

;;;###autoload
(defun meq/get-ext-name-from-file nil (interactive) (a-get meq/var/riot-list buffer-file-name))

;;;###autoload
(defun meq/get-ext-name-from-ext (&optional ext) (interactive)
  (car (rassoc (or ext (meq/get-ext-name-from-file)) meq/var/riot-elist)))

(defun meq/riot-naming-input (split-input ext)
  (s-chop-suffix "." (string-join (append (butlast split-input) (list ext)) ".")))

(defun meq/riot-naming-output (split-output file)
  (apply #'f-join (append (butlast split-output) (list file))))

(defun meq/convert-outgoing (ext-name)
  (let* ((ext (symbol-name (cdr (assoc ext-name meq/var/riot-elist))))
          (split-bfn (split-string buffer-file-name "\\."))
          (split-output (f-split (meq/riot-naming-input split-bfn ext))))
    (meq/riot-naming-output split-output (s-chop-suffix "." (string-join
                                          (cdr (split-string (car (last split-output)) "\\."))
                                          ".")))))

(defun meq/after-shave nil
    (let* ((ext-name (meq/get-ext-name-from-file)))
        (when ext-name
            (apply #'call-process
              "pandoc"
              nil
              (generate-new-buffer "*pandoc-outgoing*")
              nil
              buffer-file-name
              "-f"
              "org"
              "-t"
              (symbol-name ext-name)
              "-so"
              (meq/convert-outgoing ext-name)
              (cdr (assoc ext-name meq/var/riot-alists))))))
(add-hook 'after-save-hook #'meq/after-shave)

(defun meq/before-kill-buffer nil (interactive) (when (meq/get-ext-name-from-file) (delete-file buffer-file-name)))
(add-hook 'kill-buffer-hook #'meq/before-kill-buffer)

(defun meq/before-kill-emacs nil (interactive)
    (mapc #'(lambda (fcons) (interactive) (kill-buffer (get-file-buffer (car fcons)))) meq/var/riot-list))
(add-hook 'kill-emacs-hook #'meq/before-kill-emacs)

(defun meq/convert-incoming (input)
  (let* ((split-input (split-string input "\\."))
          (ext (car (last split-input)))
          (ext-name (meq/get-ext-name-from-ext (intern ext)))
          (split-output (f-split (meq/riot-naming-input split-input "org"))))
    `(:ext ,ext
      :ext-name ,ext-name
      :output ,(meq/riot-naming-output split-output (concat (meq/timestamp) "." (car (last split-output)))))))

(defun meq/ffns-advice (func &rest args)
    (let* ((input-buffer (apply func args))
            (input (expand-file-name (pop args)))
            (output* (meq/convert-incoming input))
            (ext (cl-getf output* :ext))
            (ext-name (cl-getf output* :ext-name))
            (output (cl-getf output* :output)))
	(if (not (and (rassoc (intern ext) meq/var/riot-elist) (not (string= ext "org"))))
            input-buffer
            (when (f-exists? input)
              (apply #'call-process
                "pandoc"
                nil
                (generate-new-buffer "*pandoc-incoming*")
                nil
                input
                "-f"
                (symbol-name ext-name)
                "-t"
                "org"
                "-so"
                output
                (a-get meq/var/riot-alists 'org)))
            (add-to-list 'meq/var/riot-list `(,output . ,ext-name))
            (unwind-protect (apply func `(,output ,@args)) (kill-buffer (get-file-buffer input))))))
(advice-add #'find-file-noselect :around #'meq/ffns-advice)

(provide 'riot)
;;; riot.el ends here
