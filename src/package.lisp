;;; Biochat package definition
;;; see LICENSE file for permissions


(defpackage :biochat
  (:nicknames :b42)
  (:use :cl :rutilsx)
  (:local-nicknames (#:re #:cl-ppcre)
                    (#:fut #:eager-future2)
                    (#:mat #:mgl-mat))
  (:export ))

(in-package :b42)

(defparameter *dir* (uiop:pathname-directory-pathname
                     (asdf:component-pathname
                      (asdf:find-system :biochat))))

(defun local-file (file)
  (merge-pathnames file *dir*))

(rutil:eval-always
  (:= drakma:*drakma-default-external-format* :utf-8)
  (:= mat:*default-mat-ctype* :float))
