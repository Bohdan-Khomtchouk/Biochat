;;; BIOCHAT2 system definition
;;; see LICENSE file for permissions

(asdf:defsystem #:biochat2
  :name "Biochat 2"
  :version (:read-file-line "version.txt")
  :author "Vsevolod Dyomkin <vseloved@gmail.com>"
  :maintainer "Vsevolod Dyomkin <vseloved@gmail.com>"
  :licence "3-clause MIT licence"
  :description
  "An system to pair, organize, and group together different biological datasets."
  :depends-on (#:rutilsx #:drakma #:cl-ppcre #:eager-future2
                         #:crawlik
                         #+dev #:should-test)
  :components
  ((:module #:src
    :serial t
    :components ((:file "package")
                 (:file "geo")))))
