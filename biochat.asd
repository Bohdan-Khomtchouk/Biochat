;;; Biochat system definition
;;; see LICENSE file for permissions

(asdf:defsystem #:biochat
  :name "Biochat"
  :version (:read-file-line "version.txt")
  :author "Bohdan Khomtchouk <bohdan@stanford.edu>, Vsevolod Dyomkin <vseloved@gmail.com>"
  :maintainer "Bohdan Khomtchouk <bohdan@stanford.edu>, Vsevolod Dyomkin <vseloved@gmail.com>"
  :license "MIT license"
  :description
  "A system to pair, organize, and group together different biological datasets."
  :depends-on (#:rutilsx #:drakma #:cl-ppcre #:eager-future2
                         #:yason #:crawlik #:hunchentoot #:cl-who
                         #:mgl-mat #:cl-nlp #:cl-nlp-contrib
                         #:lparallel
                         #+dev #:should-test)
  :components
  ((:module #:src
    :serial t
    :components
    ((:file "hunch")
     (:file "package")
     (:module "GEO"
      :serial t
      :components ((:file "util")
                   (:file "geo")
                   (:file "search")
                   (:file "bow")
                   (:file "doc2vec")
                   (:file "user")
                   (:file "filter")))
     (:file "web")))))
