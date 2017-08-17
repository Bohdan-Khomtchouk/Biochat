;;; Biochat utilities
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)

(eval-always
  (:= drakma:*drakma-default-external-format* :utf-8)
  (:= mat:*default-mat-ctype* :float))


(defmacro defvar-lazy (name init &optional docstring)
  (let ((var-name (mksym name :format "VAR-~A"))
        (access-name (mksym name :format "ACCESS-~A")))
    `(progn
       (defvar ,var-name nil ,docstring)
       (defun ,access-name ()
         ,docstring
         (or ,var-name
             (:= ,var-name ,init)))
       (define-symbol-macro ,name (,access-name)))))
