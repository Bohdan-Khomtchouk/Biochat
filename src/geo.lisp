;;; BIOCHAT2 work with GEO datasets
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)

(defparameter *max-geo-id* 6248)

(defclass geo ()
  ((id :initform 5 :initarg :id :accessor geo-id)))

(defmethod crawlik:scrape ((site geo) source)
  (crawlik:match-html
   source
   '(>> (table :id "gds_details")
        (tr)
        (tr (th) (td ($ title)))
        (tr (th) (td ($ summary)))
        (tr (th) (td (a ($ organism)))))))

(defmethod crawlik:crawl ((site geo) &optional url next-fn)
  (loop :with rez :do
    (when-it (crawlik:scrape
              site
              (crawlik:parse-dirty-xml
               (drakma:http-request
                (fmt "https://www.ncbi.nlm.nih.gov/sites/GDSbrowser?acc=GDS~A"
                     @site.id))))
      (with-out-file (out (fmt "/tmp/geo/~A.txt" @site.id))
        (dotable (k v @it#0)
          (write-line (princ-to-string k) out)
          (write-line v out)
          (terpri out))
        (princ @site.id)))
      (push (pair @site.id it) rez))
    (when (> (:+ @site.id) *max-geo-id*)
      (return rez))))
