;;; Biochat work with GEO datasets
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


(defparameter *psql* '("biochats" "biochats" "qwerty123" "localhost"))

(defclass interest ()
  ((tid :accessor interest-tid :col-type string :initarg :tid :initform nil)
   (oid :accessor interest-oid :col-type string :initarg :oid :initform nil)
   (ts :accessor interest-ts :col-type timestamp :initarg :ts :initform nil)
   (ip :accessor interest-ip :col-type string :initarg :ip :initform nil))
  (:documentation "Dao class for interest records.")
  (:metaclass postmodern:dao-class))

(defmethod print-object ((obj interest) stream)
  (format stream "#<DAO:INTEREST TID=~A OID=~A TS=~A IP=~A>"
          @obj.tid @obj.oid @obj.ts @obj.ip))

#+initially
(psql:with-connection *psql*
  (psql:execute (psql:dao-table-definition 'interest)))
