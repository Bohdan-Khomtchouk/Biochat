;;; Biochat work with GEO datasets
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)

(defparameter *histones*
  (split #\Newline (read-file (asdf:system-relative-pathname
                               :biochat "data/histones.txt"))
         :remove-empty-subseqs t))

(defparameter *pubdata-wordnet*
  (yason:parse (read-file (asdf:system-relative-pathname
                           :biochat "data/pubdata-wordnet.json"))))

(dotable (k _ *pubdata-wordnet*)
  (when (every 'digit-char-p k)
    (rem# k *pubdata-wordnet*)))


;;; grouping

(defgeneric geo-group (method &optional geo-db)
  (:documentation
   "Group records in a hash-table with keys being some strings."))

(defmethod geo-group ((method (eql :histones)) &optional (geo-db *geo-db*))
  (let ((rez #h(equal)))
    (dovec (rec geo-db)
      (dolist (histone *histones*)
        (when (search-rec histone rec)
          (push rec (? rez histone)))))
    rez))

(defmethod geo-group ((method (eql :organisms)) &optional (geo-db *geo-db*))
  (let ((rez #h(equal)))
    (dovec (rec geo-db)
      (push rec (? rez @rec.organism)))
    rez))

(defmethod geo-group ((method (eql :pubdata-wordnet)) &optional (geo-db *geo-db*))
  (let ((rez #h(equal)))
    (dovec (rec geo-db)
      (dotable (term synonyms *pubdata-wordnet*)
        (dolist (word (cons term synonyms))
          (when (search-rec word rec)
            (push rec (? rez term))))))
    rez))

(defun find-and-write-groups (out-dir &rest methods)
  "Find all groups according to METHODS and return them in the hash-table
   keyed by method name, as well as write in per-method files to OUT-DIR."
  (ensure-directories-exist out-dir)
  (let ((rez #h()))
    (dolist (method methods)
      (with-out-file (out (merge-pathnames (fmt "~(~A~).txt" method)
                                           out-dir))
        (let ((groups (geo-group method)))
          (:= (? rez method) groups)
          (dotable (term recs groups)
            (format out "# ~A~%~{~%~A~}~%~%~%" term
                    (mapcar ^(fmt "~A: ~A" @%.id @%.title)
                            recs))))))
    rez))


;;; utils

(defun search-rec (word rec)
  (or (search word @rec.title)
      (search word @rec.summary)))
