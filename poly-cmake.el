;;; poly-cmake.el --- Polymode for cmake -*- lexical-binding: t -*-
;;
;; Author: Chris Green
;; Maintainer: Chris Green
;; Copyright (C) 2021 Fermi Research Alliance, LLC.
;; Version: 0.1
;; Package-Requires: ((emacs "25") (polymode "0.2.2"))
;; URL: https://github.com/FNALssi/poly-cmake
;; Keywords: languages, multi-modes
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This file is *NOT* part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; Polymode for allowing mode-specific editing of embedded regions in
;; the comments of a CMake file, the canonical example being
;; ReStructured Text blocks for documentation with Sphinx.
;;
;;; Known Bugs:
;;
;; * I have so far been unable to evoke desired indenting behavior with
;;   respect to an embedded chunk of documentation when the enclosing
;;   comment block is itself indented, viz:
;;
;;     |function(my_cmake_function)
;;     |  # Do stuff
;;     |
;;     |  #[============================================================[.rst:
;;     |My documentation block should be flush-left unless I add spaces
;;     |myself and <tab> should do the same thing it does in rst-mode.
;;     |  #]============================================================]
;;     |
;;     |  # Moar stuff
;;     |
;;     |endfunction()
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'polymode)

(defun poly-cmake-mode-matcher ()
  "Match mode for the code embedded in a CMake comment (#[=...[<x>:
1. Extension (e.g. x=`.rst') is looked-up in `auto-mode-alist'
2. Local value of `polymode-default-inner-mode'
3. `poly-fallback-mode'"
  (let ((eol (point-at-eol)))
    (save-excursion
      (when (re-search-forward "\\[\\(\\.[[:alpha:]]+\\):" eol t)
        (let ((str (match-string 1)))
          (pm-get-mode-symbol-from-name str))))))

(define-auto-innermode poly-cmake-auto-innermode nil
  "CMake auto-innermode to identify inner mode.
See `poly-cmake-mode-matcher' for how the mode of the chunk is
identified."
  :head-matcher "^[ \t]*#\\[=*\\[\\.[[:alpha:]]+:\n"
  :tail-matcher "^[ \t]*#\\]=*\\]$"
  :fallback-mode 'text-mode
  :head-mode 'host
  :tail-mode 'host
  :mode-matcher #'poly-cmake-mode-matcher)

(define-obsolete-variable-alias 'pm-host/cmake 'poly-cmake-hostmode "v0.2")

(define-hostmode poly-cmake-hostmode :mode 'cmake-mode)

;;;###autoload (autoload 'poly-cmake-mode "poly-cmake")
(define-polymode poly-cmake-mode
  :hostmode 'poly-cmake-hostmode
  :innermodes '(poly-cmake-auto-innermode)
  :keymap '(("=" . poly-cmake-electric-eq)))

(defun poly-cmake-electric-eq (arg)
  "Auto-insert an embedded chunk at ARG."
  (interactive "P")
  (if (or arg (car (pm-innermost-span)))
      (self-insert-command (if (numberp arg) arg 1))
    (if (not (looking-back "^\\([ \t]*\\)#\\["))
        (self-insert-command 1)
      (let ((str (match-string 1)))
        (insert "============================================================[.")
        (save-excursion
          (insert (concat ":\n\n" str "#]============================================================]")
                  (unless(looking-at "\\s *$")
                    (newline))))))))

;;;###autoload
(setq auto-mode-alist
      (append
       '(("CMakeLists\\.txt\\'" . poly-cmake-mode))
       '(("\\.cmake\\'" . poly-cmake-mode))
       auto-mode-alist))

(provide 'poly-cmake)
;;; poly-cmake.el ends here
