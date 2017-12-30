;;; Biochat property-based filtering
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)

;;; histone-based filtering

(defun group-by-histone (rec-type)
  (pairs->ht
   (remove nil
           (map 'list
                (lambda (rec)
                  (let ((similar-recs
                          (remove rec
                                  (reduce 'append
                                          (mapcar ^(? *geo-by-histone*
                                                      rec-type
                                                      (when (search-rec % rec)
                                                        %))
                                                  *histones*)))))
                    (when (rest similar-recs)
                      (pair rec (coerce similar-recs 'vector)))))
                *geo-db*))))

(defvar *geo-by-histone* #h(:gds (geo-group :histones *gds*)
                            :gse (geo-group :histones *gse*)))

(defvar *gds-same-histones* (group-by-histone :gds))
(defvar *gse-same-histones* (group-by-histone :gse))

(defvar *geo-same-histones* #h(:gds *gds-same-histones*
                               :gse *gse-same-histones*))


;;; organism-based filtering

(defparameter *geo-organisms*
  (pairs->ht
   (mapcar ^(pair % (mapcar 'lt
                            (sort (ht->pairs (nlp:uniq (map* 'gr-organism
                                                             %%)
                                                       :raw t))
                                  '> :key 'rt)))
           '(:gds :gse)
           (list *gds* *gse*))))
