;;; Biochat system definition
;;; see LICENSE file for permissions

(asdf:defsystem #:biochat
  :name "Biochat"
  :version (:read-file-line "version.txt")
  :author "Bohdan Khomtchouk <bohdan@stanford.edu>", "Vsevolod Dyomkin <vseloved@gmail.com>"
  :maintainer "Bohdan Khomtchouk <bohdan@stanford.edu>", "Vsevolod Dyomkin <vseloved@gmail.com>"
  :license "MIT license"
  :description
  "A system to pair, organize, and group together different biological datasets."
  :depends-on (#:rutilsx #:drakma #:cl-ppcre #:eager-future2 #:yason
               #:mgl-mat #:cl-nlp #:cl-nlp-contrib #:crawlik
               #+dev #:should-test)
  :components
  ((:module #:src
    :serial t
    :components ((:file "package")
                 (:file "util")
                 (:file "geo")
                 (:file "search")
                 (:file "doc2vec")))))
