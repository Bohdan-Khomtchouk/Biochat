;;; Biochat work with GEO datasets
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


;;; web scraping

(defparameter *max-geo-id* 6248)

(defclass geo ()
  ((id :initform 1 :initarg :id :accessor geo-id)
   (seen :initform 0 :accessor geo-seen)
   (count :initform 0 :initarg :count :accessor geo-count)
   (out-dir :initform "/tmp/" :initarg :out-dir :accessor geo-out-dir)
   (url-template :initarg :url-template :accessor geo-url-template)))

(defclass geo-gds (geo)
  ((url-template :initform
                 "https://www.ncbi.nlm.nih.gov/sites/GDSbrowser?acc=GDS~A"
                 :initarg :url-template :accessor geo-url-template)))
  
(defclass geo-gse (geo)
  ((url-template :initform
                 "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE~A"
                 :initarg :url-template :accessor geo-url-template)))



(defmethod crawlik:scrape ((site geo) source)
  (crawlik:match-html
   source
   '(>> (div :class "lastcol ...")
        (>> (div :class "portlet_content")
            (ul (li)
                (>> (span :class "counts") ($ gds))
                (>> (span :class "counts") ($ gse)))))))

(defmethod crawlik:scrape ((site geo-gds) source)
  (crawlik:match-html
   source
   '(>> (table :id "gds_details")
        (tr)
        (tr (th) (td ($ title)))
        (tr (th) (td ($ summary)))
        (tr (th) (td (a ($ organism)))))))

(defmethod crawlik:scrape ((site geo-gse) source)
  (when-it (crawlik:match-html
            source
            '(>> (table :width "600")
              (tr) (tr)
              (tr (td) (td ($ title)))
              (tr (td) (td (a ($ organism))))
              (tr)
              (tr (td ($ key1)) ($ val1 td))
              (tr (td ($ key2)) ($ val2 td))
              (tr (td ($ key3)) ($ val3 td))))
    (with ((raw (? it 0))
           (rez #h(:title (? raw :title)
                   :organism (? raw :organism))))
      (dolist (key '(:summary :design :|OVERALL DESIGN|))
        (when-it (position key (map* 'mkeyw (vec (? raw :key1)
                                                 (? raw :key2)
                                                 (? raw :key3))))
          (:= key (ecase key
                    (:summary :summary)
                    ((:design :|OVERALL DESIGN|) :design)))
          (:= (? rez key)
              (strjoin #\Space (remove-if 'listp
                                          (rest (? (vec (? raw :val1)
                                                        (? raw :val2)
                                                        (? raw :val3))
                                                   it)))))))
      (list rez))))

(defmethod crawlik:crawl ((site geo))
  (crawlik:scrape site (crawlik:parse-dirty-xml
                        (drakma:http-request "https://www.ncbi.nlm.nih.gov/geo/"))))

(defmethod crawlik:crawl ((site geo-gds))
  (crawl-geo site "GDS" "/tmp/geo/"))

(defmethod crawlik:crawl ((site geo-gse))
  (crawl-geo site "GSE" "/tmp/geo/"))

(defpar *chrome-ua*
    "Mozilla/5.0 (Windows NT x.y; rv:10.0) Gecko/20100101 Firefox/10.0")

(defun crawl-geo (site type out-dir)
  (ensure-directories-exist (fmt "~A~A/" out-dir type))
  (loop :with rez :do
    (let ((out-file (fmt "~A~A/~A.txt" out-dir type @site.id)))
      (unless (probe-file out-file)
        (when-it (crawlik:scrape
                  site
                  (crawlik:parse-dirty-xml
                   (handler-bind ((flexi-streams:external-format-encoding-error
                                    (lambda (e)
                                      (declare (ignore e))
                                      (flexi-streams::use-value #\Space))))
                     (drakma:http-request (fmt @site.url-template
                                               @site.id)))))
          ;;  :user-agent *chrome-ua*))))
          (with-out-file (out out-file)
            (dotable (k v @it#0)
              (write-line (princ-to-string k) out)
              (write-line v out)
              (terpri out))
            (princ (strcat @site.id " ")))
          (push (pair @site.id it) rez)))
      (:+ @site.id)
      (when (> (:+ @site.seen) @site.count)
        (return-from crawl-geo rez)))))

(defun scrape-geo (out-dir &key (gds-id 1) (gse-id 1) gds-count gse-count)
  (with ((counts (? (crawlik:crawl (make 'geo)) 0))
         (((gds :gds) (gse :gse)) ? counts)
         (gds-crawler (make 'geo-gds :id gds-id
                                     :count (or gds-count (parse-integer gds))
                                     :out-dir out-dir))
         (gse-crawler (make 'geo-gse :id gse-id
                                     :count (or gse-count (parse-integer gse))
                                     :out-dir out-dir)))
    (format *debug-io* "Starting to crawl GDS (count=~A): " gds)
    (crawlik:crawl gds-crawler)
    (format *debug-io* "done (crawled ~A items).~%" @gds-crawler.seen)
    (format *debug-io* "Starting to crawl GSE (count=~A): " gse)
    (crawlik:crawl gse-crawler)
    (format *debug-io* "done (crawled ~A items).~%" @gse-crawler.seen)))


;;; in-memory storage

(defstruct (geo-rec (:conc-name gr-))
  id title organism summary design)

(defun load-geo (dir)
  (let (rez)
    (dolist (file (directory (strcat dir "*.txt")))
      (let ((raw (split #\Newline (read-file file))))
        (push (make-geo-rec
               :id (parse-integer (pathname-name file))
               :title (? raw (1+ (position "TITLE" raw :test 'string=)))
               :organism (? raw (1+ (position "ORGANISM" raw :test 'string=)))
               :summary (when-it (position "SUMMARY" raw :test 'string=)
                          (? raw (1+ it)))
               :design (when-it (position "DESIGN" raw :test 'string=)
                         (? raw (1+ it))))
              rez)))
    (coerce (reverse rez) 'vector)))

(defvar *gds* (load-geo (local-file "data/GEO/GEO_records/GDS/")))
(defvar *gse* (load-geo (local-file "data/GEO/GEO_records/GSE/")))
(defvar *geo-db* *gds*)


;;; auto-update

#+nil
(bt:make-thread
 ^(let ((dir (local-file "data/GEO/GEO_records/")))
    (format *debug-io* "Starting auto-update:~%")
    (flet ((max-id (rec-type)
             (reduce 'max (mapcar (=> parse-integer pathname-name)
                                  (directory (strcat dir rec-type
                                                     "/*.txt"))))))
      (loop (scrape-geo dir
                        :gds-id (max-id "GDS")
                        :gse-id (max-id "GSE"))
            (format *debug-io* "Finished auto-update run.~%")
            (sleep #.(* 1 60 60 24))))) ; 1 day
 :name "GEO updater")
