;;; Biochat work with GEO datasets
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


(defparameter *psql* '("biochats" "biochats" "qwerty123" "localhost"))

(defclass interest ()
  ((id :accessor id :col-type string :initarg :id :initform nil)
   (oid :accessor oid :col-type string :initarg :oid :initform nil))
  (:documentation "Dao class for interest records.")
  (:metaclass postmodern:dao-class)
  (:keys id oid))

#+initially
(psql:with-connection *psql*
  (psql:execute (psql:dao-table-definition 'interest)))
