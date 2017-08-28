(defparameter *dir* (uiop:get-pathname-defaults)) 

(push (merge-pathnames "../" *dir*) asdf:*central-registry*)
(push (merge-pathnames "../../rutils/" *dir*) asdf:*central-registry*)
(push (merge-pathnames "../../cl-nlp/" *dir*) asdf:*central-registry*)

(ql:quickload :biochat)
