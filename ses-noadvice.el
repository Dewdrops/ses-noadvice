;;; ses-noadvice.el --- use ses with less trouble

;; Copyright (C) 2014 by Dewdrops

;; Author: Dewdrops <v_v_4474@126.com>
;; URL: http://github.com/Dewdrops/ses-noadvice
;; Version: 0.1
;; Keywords: ses advice
;; Package-Requires: ((ses "21.1"))

;; This file is NOT part of GNU Emacs.

;;; License:
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'ses)

(defgroup ses-noadvice nil
  "Use ses with less trouble"
  :prefix "ses-noadvice"
  :group 'ses)

(defcustom ses-noadvice-vi-like-binding nil
  "Whether to add vi-like key binding to ses buffer."
  :type 'boolean
  :group 'ses-noadvice)


(ses-unload-function)

(define-key ses-mode-print-map (kbd "C-w") 'ses-kill-override)
(define-key ses-mode-print-map (kbd "M-w") 'ses-noadvice-copy-region-as-kill)
(define-key ses-mode-print-map (kbd "C-y") 'ses-noadvice-yank)
(define-key ses-mode-edit-map (kbd "TAB") 'lisp-complete-symbol)

(when ses-noadvice-vi-like-binding
  (define-key ses-mode-print-map (kbd "g") 'ses-jump)
  (define-key ses-mode-print-map (kbd "j") 'next-line)
  (define-key ses-mode-print-map (kbd "k") 'previous-line)
  (define-key ses-mode-print-map (kbd "h") 'backward-char)
  (define-key ses-mode-print-map (kbd "l") 'forward-char)
  (define-key ses-mode-print-map (kbd "o") 'ses-insert-row)
  (define-key ses-mode-print-map (kbd "O") 'ses-insert-column)
  (define-key ses-mode-print-map (kbd "u") 'undo)
  (define-key ses-mode-print-map (kbd "d") 'ses-clear-cell-forward)
  (define-key ses-mode-print-map (kbd "v") 'set-mark-command)
  (define-key ses-mode-print-map (kbd "s") 'ses-kill-override)
  (define-key ses-mode-print-map (kbd "y") 'ses-noadvice-copy-region-as-kill)
  (define-key ses-mode-print-map (kbd "p") 'ses-noadvice-yank)
  (define-key ses-mode-print-map (kbd "P") 'ses-read-cell-printer))

(defun ses-noadvice-copy-region-as-kill (beg end)
  "Reimplement ses' `copy-region-as-kill' advice use function."
  (interactive "r")
  (when (> beg end)
    (let ((temp beg))
      (setq beg end
            end temp)))
  (if (not (and (eq (get-text-property beg 'read-only) 'ses)
                (eq (get-text-property (1- end) 'read-only) 'ses)))
      (copy-region-as-kill beg end)
    (kill-new (ses-copy-region beg end))
    (if transient-mark-mode
        (setq deactivate-mark t))
    nil))

(defun ses-kill-override (beg end)
  "Reimplement `ses-kill-override' using `ses-noadvice-copy-region-as-kill'."
  (interactive "r")
  (if (not (eq (get-text-property (point) 'keymap) 'ses-mode-print-map))
      (kill-region beg end)
    (ses-noadvice-copy-region-as-kill beg end)
    (barf-if-buffer-read-only)
    (ses-begin-change)
    (ses-dorange ses--curcell
                 (ses-clear-cell row col))
    (ses-jump (car ses--curcell))))

(defun ses-noadvice-yank (&optional arg)
  "Reimplement ses' yank advice use function."
  (interactive "*P")
  (let ((x-select-enable-primary nil))
    (if (not (eq (get-text-property (point) 'keymap) 'ses-mode-print-map))
        (yank arg)
      (ses-check-curcell 'end)
      (push-mark (point))
      (let ((text (current-kill (cond
                                 ((listp arg) 0)
                                 ((eq arg '-) -1)
                                 (t (1- arg))))))
        (or (ses-yank-cells text arg)
            (ses-yank-tsf text arg)
            (ses-yank-one (ses-yank-resize 1 1)
                          text
                          0
                          (if (memq (aref text (1- (length text))) '(?\t ?\n))
                              ;; Just one cell --- delete final tab or newline.
                              (1- (length text)))
                          arg)))
      (if (consp arg)
          (exchange-point-and-mark)))))


(provide 'ses-noadvice)
;;; ses-noadvice.el ends here
