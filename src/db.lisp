;;; Biochat work with GEO datasets
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


(defparameter *psql* '("biochats" "biochats" "qwerty123" "localhost"))

(defclass interest ()
  ((tid :accessor interest-tid :col-type string :initarg :tid)
   (oid :accessor interest-oid :col-type string :initarg :oid)
   (ts :accessor interest-ts :col-type timestamptz :initarg :ts
       :col-default 'current-timestamp)
   (ip :accessor interest-ip :col-type string :initarg :ip)
   (params :accessor interest-params :col-type jsonb :initarg :params))
  (:documentation "Dao class for interest records.")
  (:metaclass postmodern:dao-class))

(defun decode-interest (obj)
  (list @obj.tid
        @obj.oid
        (local-time:universal-to-timestamp @obj.ts)
        @obj.ip
        (yason:parse @obj.params :object-key-fn 'mkeyw)))

(defmethod print-object ((obj interest) stream)
  (with (((tid oid ts ip params) (decode-interest obj)))
    (format stream "#<DAO:INTEREST TID=~A OID=~A TS=~A IP=~A PARAMS=~{~A~^|~}>"
            tid oid ts ip (mapcar ^(strjoin #\: %)
                                  (ht->pairs params)))))


#+initially
(psql:with-connection *psql*
  (psql:execute (psql:dao-table-definition 'interest)))
