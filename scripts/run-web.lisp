(defparameter *dir* (uiop:get-pathname-defaults)) 

(push (merge-pathnames "../" *dir*) asdf:*central-registry*)
(push (merge-pathnames "../../rutils/" *dir*) asdf:*central-registry*)
(push (merge-pathnames "../../cl-nlp/" *dir*) asdf:*central-registry*)
(push (merge-pathnames "../../crawlik/" *dir*) asdf:*central-registry*)

(defparameter cl-user::*lla-configuration* '(:libraries ("libopenblas.so")))

(ql:quickload :biochat)
