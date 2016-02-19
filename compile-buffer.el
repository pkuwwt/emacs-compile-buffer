;;; compile-buffer.el --- compile and run current buffer 

;; Copyright (C) 2016  Wentao Wang

;; Author: Wentao Wang <wwthunan@gmail.com>
;; Version: 1.0
;; Keywords: unix, compile, programming

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

;; For a single source code file, if you want to compile it and run it
;; with a single short-cut to check if there are errors, you can use this tool.

;; When I used vim, I write a similar tool to assist my programming.
;; In specific, I press <F5> to compile my code, and <F6> to run the
;; result, so that I need not to switch to shell to type command line,
;; which is specially useful for TESTing a single source file.
;;

;;
;; The main features for c/cpp are :
;;   * add main function by macro "#ifdef COMPILE_DEBUG"
;;   * add compiling flags as comments like "// COMPILE_DEPENDS: -lm other.cpp"
;;

;;
;; Applicable source types: .c, .cpp, .cxx, .h, .hxx, .hpp, .py, .java
;;

;;
;; C/CPP example 1
;; 
;; #include <iostream>
;; int main(int argc, char* argv[]) {
;;     std::cout << "hello world" << std::endl;
;;     return 0;
;; }
;;

;;
;; C/CPP example 2 (a test main function)
;;
;; // other_source.cpp
;; int func1() { return 1; }
;; 
;; // current_source.cpp
;; #include <iostream>
;; #include <cmath>
;; extern int func1();
;; int func2() { return 1; }
;; // COMPILE_DEPENDS: -lm other_source.cpp
;; #ifdef COMPILE_DEBUG
;; int main(int argc, char* argv[]) {
;;     std::cout << "hello world, " << func1() << func2() << std::endl;
;;     return 0;
;; }
;; #endif
;;

;; 
;; Basic configuration in .emacs
;;
;;   (load "compile-buffer.el")
;;

;; Other configurations
;;   (CB-clear-lib-pattern-flags)
;;   (CB-add-lib-pattern-flags "GL" " -lGL -lGLU -lglut ")
;;
;; Usage:
;;
;; | <F5>  | Compile current buffer  |
;; | <F6>  | Run the result          |
;;

;;; Code:

(defvar CB-compiling-buffer "**Compiling Buffer**")
(defvar CB-running-buffer "**Running Buffer**")
(defvar CB-libs-pattern-flags '(
								("osg" " -losgDB -losgGA -losgViewer -losg -losgUtil -losgText -losgSim -losgFX -lOpenThreads  -losgAnimation -losgManipulator ")
								("vtk" " -lvtkHybrid -lvtkRendering -lvtkIO -lvtkGraphics -lvtkFiltering -lvtkCommon -lvtkVolumeRendering -lvtkImaging -lvtkWidgets -lvtkCharts -lvtksys ")
								("CGAL" " -lCGAL -lCGAL_Core -lCGAL_ImageIO -lCGAL_PDB -lgmp ")
								("Qt" " -lQtGui -lQtCore -lQtOpenGL ")
								("GL" " -lGL -lGLU -lglut ")
								)
  "A list of pairs (pattern, flags), where the pattern is used to search,
and the flags is used in complilation."
  )
(defvar CB-script-ext-program-map '(
									("py" "python")
									("sh" "bash")
									("r" "Rscript")
									("pl" "perl")
									("rb" "ruby")
									("tcl" "tcl")
									("lua" "lua")
									)
  "The map from extensions to the interpretation program"
  )
(defvar CB-pdf-viewer "evince")
(defvar CB-running-window-height 7)
(defvar CB-compiling-window-height 7)

(defun CB-clear-lib-pattern-flags()
  "Clear CB-libs-pattern-flags, which is used to parse C/CPP libs"
  (setq CB-libs-pattern-flags '())
  )
(defun CB-add-lib-pattern-flags(pattern  flags)
  "Add the pair (pattern,flags) to the CB-libs-pattern-flags, 
which is used to parse C/CPP libs"
  (setq CB-libs-pattern-flags
		(cons (list pattern flags)
			  CB-libs-pattern-flags)
		)
  )
(defun CB-get-buffer-filetype()
  "Get the type of a source code file"
  (let* ((ext (file-name-extension (buffer-file-name))))
	(cond ((string= ext "c") "c")
		  ((string= ext "cxx") "cpp")
		  ((string= ext "cpp") "cpp")
		  ((string= ext "py") "python")
		  ((string= ext "java") "java")
		  ((string= ext "h") "c-header")
		  ((string= ext "hpp") "cpp-header")
		  ((string= ext "hxx") "cpp-header")
		  (t ext)
		  )
	)
  )
(defun CB-show-and-set-buffer-height(buffername height)
  (progn
	(switch-to-buffer-other-window buffername)
										;(message (format "%d"(window-height)))
	(enlarge-window (- height (window-height)))
										;(enlarge-window -1)
	(other-window 1)
	)
  )

(defun CB-shell-command-to-buffer(buffername command)
  "Execute command, and display output in a buffer"
  (progn
	(switch-to-buffer-other-window buffername)
										;(erase-buffer)
	(other-window 1)
	(start-process-shell-command command buffername command)
	)
  )

(defun CB-show-and-clear-buffer(buffer)
  "show a buffer and clear it"
  (progn
	(switch-to-buffer-other-window buffer)
	(erase-buffer)
	(other-window 1)
	)
  )
(defun CB-message-list-to-buffer(buffer s &rest strs)
  "output a list of strings to buffer"
  (let* ((result (format "%s" s)))
	(while strs
	  (setq result (format "%s\n%s" result (car strs)))
	  (setq strs (cdr strs)))
	(switch-to-buffer-other-window buffer)
	(insert (format "%s\n" result))
	(other-window 1)
	)
  )
(defun CB-message-list(s &rest strs)
  "output a list of strings to minibuffer"
  (let* ((result (format "%s" s)))
	(while strs
	  (setq result (format "%s\n%s" result (car strs)))
	  (setq strs (cdr strs)))
	(message result)
	)
  )
(defun CB-buffer-contains-substring (string)
  "check if a string contained in current buffer,
but current position is not changed"
  (save-excursion
	(save-match-data
	  (goto-char (point-min))
	  (search-forward string nil t))))
(defun CB-buffer-contains-regexp(re)
  "check if a regexp contained in current buffer,
but current position is not changed"
  (save-excursion
	(save-match-data
	  (goto-char (point-min))
	  (search-forward-regexp re nil t))))
(defun CB-buffer-contains-regexp-or-group(re &rest res)
  "RETURN t if any argument is contained in buffer"
  (let* ((result (CB-buffer-contains-regexp re)))
	(while res
	  (setq result
			(or result
				(CB-buffer-contains-regexp (car res))))
	  (setq res (cdr res))
	  )
	result
	)
  )
(defun CB-buffer-contains-regexp-and-group(re &rest res)
  "RETURN t if all arguments are contained in buffer"
  (let* (
		 (result (CB-buffer-contains-regexp re))
		 )
	(while (and result res)
	  (setq result
			(and result
				 (CB-buffer-contains-regexp (car res))))
	  (setq res (cdr res))
	  )
	result
	)
  )
(defun CB-matching-lines-as-list(re)
  "Get all matched lines as a list"
  (let* ((result-list '())
		 (last-line "")
		 (last-line-begin -1)
		 )
	(save-match-data
	  (save-excursion
		(goto-char (point-min))
		(while (re-search-forward re nil t)
		  (let* (
				 (cur-line-begin (line-beginning-position))
				 (cur-line-end (- (line-beginning-position 2) 1))
				 (cur-line (buffer-substring-no-properties cur-line-begin cur-line-end))
				 )
			;; in order to avoid count the same line multiple times
			(if (not (equal last-line-begin cur-line-begin))
				(setq result-list (cons cur-line result-list))
			  )
			(setq last-line-begin cur-line-begin)
			)
		  )
		(reverse result-list)))))

(defun CB-parse-ccpp-compile-depends()
  (let* (
		 (strs (CB-matching-lines-as-list "COMPILE_DEPENDS"))
		 (result-flags ""))
	(while strs
	  (setq result-flags
			(format "%s %s" result-flags
					(replace-regexp-in-string ".*COMPILE_DEPENDS *:" "" (car strs))))
	  (setq strs (cdr strs))
	  )
	(if (CB-buffer-contains-regexp "# *ifdef.*COMPILE_DEBUG")
		(format " -DCOMPILE_DEBUG %s " result-flags)
	  result-flags
	  )
	)
  )

(defun CB-parse-ccpp-compile-flags()
  (let* (
		 (libs-flag CB-libs-pattern-flags)
		 (result-flags " -I/usr/include -L/usr/lib ")
		 (append-flags (function (lambda (flags) (setq result-flags (format "%s %s " result-flags flags)))))
		 )
	(while libs-flag
	  (let* ((lib-flag (car libs-flag)))
		(if (CB-buffer-contains-regexp (car lib-flag))
			(funcall append-flags (nth 1 lib-flag)))
		)
	  (setq libs-flag (cdr libs-flag))
	  )
	result-flags
										;(message result-flags)
	)
  )
(defun CB-parse-ccpp-compile-command()
  (let* (
		 (ext (file-name-extension (buffer-file-name)))
		 (command (cond ((string= ext "c") "gcc")
						((string= ext "cxx") "g++")
						((string= ext "cpp") "g++")
						((string= ext "h") "gcc")
						((string= ext "hpp") "g++"))))
	(if (CB-buffer-contains-regexp "\\_<class\\_>")
		(setq command "g++"))
	command
	)
  )
(defun CB-parse-ccpp-compile-output()
  (let* ((src (buffer-file-name))
		 (out (format "%s%s"
					  (file-name-directory src)
					  (file-name-base src)))
		 (ext (file-name-extension src))
		 (outext "")
		 )
	(if (or (string= ext "h")
			(string= ext "hpp")
			(string= ext "hxx")
			)
		(setq outext "gch")
	  )
	(if (CB-buffer-contains-regexp "main.*(.*)")
		(setq outext "out")
	  )
	(if (or (string= outext "out")
			(string= outext "gch")
			)
		(format "%s.%s " out outext)
	  "-c"
	  )
	)
  )
(defun CB-parse-ccpp-compile-command-line()
  (let* ((src (buffer-file-name))
		 (flags (CB-parse-ccpp-compile-flags))
		 (depends (CB-parse-ccpp-compile-depends))
		 (command (CB-parse-ccpp-compile-command))
		 (out (CB-parse-ccpp-compile-output))
		 )
	(if (not (string= out "-c")) (setq out (format "-o %s" out)))
	(format "%s %s %s %s %s" command src depends flags out)
										;(message (format "%s %s %s %s" command src depends out))
	)
  )
(defun CB-compile-buffer-as-ccpp-header()
  (let* ((src (buffer-file-name))
		 (out (format "%s%s.gch"
					  (file-name-directory src)
					  (file-name-base src)))
		 (command (CB-parse-ccpp-compile-command-line))
		 (buffer CB-compiling-buffer)
		 )
	(CB-show-and-set-buffer-height buffer CB-compiling-window-height)
	(CB-show-and-clear-buffer buffer)
	(CB-message-list-to-buffer buffer (format "Compiling %s" src))
	(if (CB-buffer-contains-regexp "Q_OBJECT")
		(CB-shell-command-to-buffer buffer (format "moc-qt4 %s" src))
	  )
	(CB-shell-command-to-buffer buffer (format "%s;rm -f %s" command out))
	))
(defun CB-compile-buffer-as-ccpp()
  (let* ((src (buffer-file-name))
		 (command (CB-parse-ccpp-compile-command-line))
		 (buffer CB-compiling-buffer)
		 )
	(CB-show-and-set-buffer-height buffer CB-compiling-window-height)
	(CB-show-and-clear-buffer buffer)
	(CB-message-list-to-buffer buffer (format "Compiling %s" src))
	(CB-shell-command-to-buffer buffer (format "%s" command))
	))
(defun CB-run-buffer-as-cpp()
  (let* ((src (buffer-file-name))
		 (out (CB-parse-ccpp-compile-output))
		 (buffer CB-running-buffer)
		 )
	(if (not (string= out "-c"))
		(progn 
		  (CB-show-and-set-buffer-height buffer CB-running-window-height)
		  (CB-show-and-clear-buffer buffer)
		  (CB-message-list-to-buffer buffer (format "Running %s" out))
		  (CB-shell-command-to-buffer buffer out)
		  ;;(message-list-to-buffer buffer (format "Running %s finished." out))
		  )
	  )
	)
  )
(defun CB-compile-buffer-as-java()
  (let* ((src (buffer-file-name))
		 (buffer CB-compiling-buffer)
		 )
	(CB-show-and-set-buffer-height buffer CB-compiling-window-height)
	(CB-show-and-clear-buffer buffer)
	(CB-message-list-to-buffer buffer (format "Compiling %s" src))
	(CB-shell-command-to-buffer buffer (format "javac %s" src ))
	))
(defun CB-run-buffer-as-java()
  (let* ((class (file-name-base (buffer-file-name)))
		 (buffer CB-running-buffer)
		 )
	(CB-show-and-set-buffer-height buffer CB-running-window-height)
	(CB-show-and-clear-buffer buffer)
	(CB-message-list-to-buffer buffer (format "Running %s" src))
	(CB-shell-command-to-buffer buffer (format "java %s" class))
	))
(defun CB-run-buffer-as-python()
  (let* ((src (buffer-file-name))
		 (buffer CB-running-buffer)
		 )
	(CB-show-and-set-buffer-height buffer CB-running-window-height)
	(CB-show-and-clear-buffer buffer)
	(CB-message-list-to-buffer buffer (format "Running %s" src))
	(CB-shell-command-to-buffer buffer (format "python %s" src))
	)
  )
(defun CB-run-buffer-as-elisp()
  (eval-buffer)
  )
(defun CB-run-buffer-as-script()
  (let* ((src (buffer-file-name))
		 (ext (file-name-extension src))
		 (buffer CB-running-buffer)
		 (ext-prog-map CB-script-ext-program-map)
		 )
	(CB-show-and-set-buffer-height buffer CB-running-window-height)
	(CB-show-and-clear-buffer buffer)
	(CB-message-list-to-buffer buffer (format "Running %s" src))
	(while ext-prog-map
	  (if (string= ext (nth 0 (car ext-prog-map)))
		  (CB-shell-command-to-buffer
		   buffer
		   (format "%s %s" (nth 1 (car ext-prog-map)) src))
		)
	  (setq ext-prog-map (cdr ext-prog-map))
	  )
	)
  )
(defun CB-dir-contain-file(dir filename)
  "if the list of files in dir contains filename"
  (let* ( (file-list (directory-files dir)) )
	(member filename file-list)
	)
  )
(defun CB-compile-buffer-as-latex()
  (let* ((latex "pdflatex")
		 (src (buffer-file-name))
		 (base (file-name-base src))
		 (dir (file-name-directory src))
		 (buffer CB-compiling-buffer)
		 (command (format "%s %s" latex src))
		 )
	(if (CB-buffer-contains-regexp-or-group "xeCJK" "xelatex")
		(progn
		  (setq latex "xelatex")
		  (setq command (format "%s %s" latex src))
		  )
	  )
	(if (CB-buffer-contains-regexp "cite")
		(setq command (format "%s;bibtex %s.aux;%s;%s" command base command command))
	  (setq command (format "%s;%s;%s" command command command))
	  )
	(if (or
		 (CB-dir-contain-file dir "makefile")
		 (CB-dir-contain-file dir "Makefile")
		 )
		(progn
		  (CB-show-and-set-buffer-height buffer CB-compiling-window-height)
		  (CB-show-and-clear-buffer buffer)
		  (CB-shell-command-to-buffer buffer "make -k")
		  )
	  (if (CB-buffer-contains-regexp-or-group "\\begin.*document" "\\end.*document")
		  (progn
			(CB-show-and-set-buffer-height buffer CB-compiling-window-height)
			(CB-show-and-clear-buffer buffer)
			(CB-message-list-to-buffer buffer (format "Compiling %s" src))
			(CB-shell-command-to-buffer buffer command)
			)
		))))
(defun CB-run-buffer-as-latex()
  "open pdf with CB-pdf-viewer"
  (let* (
		 (src (buffer-file-name))
		 (base (file-name-base src))
		 )
	(CB-show-and-set-buffer-height buffer CB-running-window-height)
	(shell-command (format "%s %s.pdf >/dev/null 2>&1 &" CB-pdf-viewer base))
	)
  )
(defun CB-compile-buffer()
  "compile current source file according to the postfix."
  (interactive)
  (save-buffer)
  (let* ((filetype (CB-get-buffer-filetype))
		 (buffer CB-compiling-buffer)
		 )
	(cond ((string= filetype "cpp") (CB-compile-buffer-as-ccpp))
		  ((string= filetype "cpp-header") (CB-compile-buffer-as-ccpp-header))
		  ((string= filetype "c") (CB-compile-buffer-as-ccpp))
		  ((string= filetype "c-header") (CB-compile-buffer-as-ccpp-header))
		  ((string= filetype "java") (CB-compile-buffer-as-java))
		  ((string= filetype "tex") (CB-compile-buffer-as-latex))
		  (t (CB-run-buffer-as-script))
		  )
	)
  )
(defun CB-run-buffer()
  "run current source file according to the postfix.
If the source file need to be compiled, you should use
CB-compile-buffer first."
  (interactive)
  (let* (
		 (filetype (CB-get-buffer-filetype))
		 (ext (file-name-extension (buffer-file-name)))
		 )
	(cond ((string= filetype "cpp") (CB-run-buffer-as-cpp))
		  ((string= filetype "c") (CB-run-buffer-as-cpp))
		  ((string= filetype "java") (CB-run-buffer-as-java))
		  ((string= filetype "el") (CB-run-buffer-as-elisp))
		  ((string= filetype "tex") (CB-run-buffer-as-latex))
		  (t (CB-run-buffer-as-script))
		  )
    )
  )

(global-set-key (kbd "<f5>") 'CB-compile-buffer)
(global-set-key (kbd "<f6>") 'CB-run-buffer)

;;; compile-buffer.el ends here
