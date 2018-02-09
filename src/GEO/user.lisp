;;; Biochat data loading and updating
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


(:= lparallel:*kernel* (lparallel:make-kernel 2))
(push '("application" . "xml") drakma:*text-content-types*)


(defvar *gds* (load-geo-dir :gds (local-file "data/GEO/GEO_records/GDS/")))
(defvar *gse* (load-geo-dir :gse (local-file "data/GEO/GEO_records/GSE/")))
(defvar *geo-db* (concatenate 'vector *gds* *gse*))


(format *debug-io* "Starting vecs calculation for GDS: ")
(defvar *gds-vecs* (make-array (length *gds*) :adjustable t :fill-pointer t
                                              :initial-contents
                                              (map* 'geo-vec *gds*)))
(format *debug-io* "done.~%")

(format *debug-io* "Starting vecs calculation for GSE: ")
(defvar *gse-vecs* (make-array (length *gse*) :adjustable t :fill-pointer t
                                              :initial-contents
                                              (map* 'geo-vec *gse*)))
(format *debug-io* "done.~%")
(defvar *geo-vecs* (concatenate 'vector *gds-vecs* *gse-vecs*))

(unless (boundp '*tf*)
  (with ((tf idf (calc-tfidf (mapcar 'lemmas
                                     (map 'list 'geo-toks
                                          (concatenate 'vector *gds* *gse*))))))
    (defvar *tf* tf)
    (defvar *idf* idf)))

(defvar *geo-libstrats* (cons :microarray (keys (all-libstrats))))

;;; auto-update

(defvar *geo-updater-thread*
  (bt:make-thread
   ^(let ((dir (local-file "data/GEO/GEO_records/")))
      (format *debug-io* "Starting auto-update:~%")
      (flet ((max-id (rec-type)
               (reduce 'max (mapcar (=> parse-integer pathname-name)
                                    (directory (strcat dir rec-type "/*.txt")))
                       :initial-value 0)))
        (loop (scrape-geo dir
                          :gds-id (max-id "GDS")
                          :gse-id (max-id "GSE"))
              (format *debug-io* "Finished auto-update run.~%")
              (sleep #.(* 1 60 60 24))))) ; 1 day
   :name "GEO updater"))
