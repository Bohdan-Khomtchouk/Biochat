;;; Biochat work with GEO datasets
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


(defstruct (geo-rec (:conc-name gr-))
  id
  title
  organism
  summary
  design
  platform
  citations
  libstrats
  microarrayp)


;;; web scraping

(defclass geo ()
  ((id :initform 1 :initarg :id :accessor geo-id)
   (last-id :initform -1 :initarg :last-id :accessor geo-last-id)
   (seen :initform 0 :initarg :seen :accessor geo-seen)
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
  (when-it (crawlik:match-html source
                               '(>> (table :id "gds_details")
                                    (tr)
                                    (tr (th) (td ($ title)))
                                    (tr (th) (td ($ summary)))
                                    (tr (th) (td (a ($ organism))))
                                    (tr (th) ($ platform td))
                                    (tr (th) ($ citations td))))
    (dolist (rec it)
      (:= (? rec :platform) (re:regex-replace-all
                             "\\s+" (html-str (? rec :platform)) " ")
          (? rec :citations) (html-str (? rec :citations))))
    it))

(defmethod crawlik:scrape ((site geo-gse) source)
  (when-it (crawlik:match-html source
                               '(>> td ($ content (table :width "600"))))
    (let ((rez #h()))
      (dotable (id markers #h(:title "title"
                              :organism '("sample organism" "organism")
                              :summary "summary"
                              :design "design"
                              :platform "platforms"
                              :citations "citation"))
        (loop :for (th td) :in (mapcar 'rest (rest (? it 0 :content))) :do
          (when (some ^(search % (second th) :test 'string-equal)
                      (mklist markers))
            (:= (? rez id) (html-str td)))))
      (list rez))))

(defmethod crawlik:crawl ((site geo))
  (crawlik:scrape site (crawlik:parse-dirty-xml
                        (drakma:http-request "https://www.ncbi.nlm.nih.gov/geo/"))))

(defmethod crawlik:crawl ((site geo-gds))
  (crawl-geo site "GDS"))

(defmethod crawlik:crawl ((site geo-gse))
  (crawl-geo site "GSE"))

(defpar *chrome-ua*
    "Mozilla/5.0 (Windows NT x.y; rv:10.0) Gecko/20100101 Firefox/10.0")

(defun crawl-geo (site type)
  (ensure-directories-exist (fmt "~A~A/" @site.out-dir type))
  (loop :with rez :do
    (let ((out-file (fmt "~A~A/~A.txt" @site.out-dir type @site.id)))
      (unless (probe-file out-file)
        (when-it (first (crawlik:scrape
                         site
                         (crawlik:parse-dirty-xml
                          (handler-bind
                              ((flexi-streams:external-format-encoding-error
                                 (lambda (e)
                                   (declare (ignore e))
                                   (flexi-streams::use-value #\Space))))
                            (loop
                              (handler-case
                                  (return (drakma:http-request
                                           (fmt @site.url-template @site.id)
                                           :user-agent *chrome-ua*))
                                ((or cl+ssl::ssl-error-syscall
                                  cl+ssl::ssl-error-zero-return) () (sleep 5))
                                (drakma::drakma-simple-error () nil)))))))
          (when (plusp (tally it))
            (:+ @site.seen)
            (with-out-file (out out-file)
              (dotable (k v it)
                (write-line (princ-to-string k) out)
                (write-line (princ-to-string v) out)
                (terpri out)))
            (when (:= (? it :microarrayp) (scrape-microarrayp (? it :platform)))
              (format out-file "MICROARRAYP~%T~%~%"))
            (with ((rec (load-geo out-file))  ; TODO: add libstrats
                   (vec (geo-vec rec)))
              (switch (type :test 'string=)
                ("GDS" (pushx rec *gds*)
                       (pushx vec *gds-vecs*))
                ("GSE" (pushx rec *gse*)
                       (pushx vec *gse-vecs*))))
            (push (pair @site.id it) rez)
            (:= @site.last-id @site.id)
            (format *debug-io* "~A~A " type @site.id))))
      (:+ @site.id)
      (when (or (>= @site.seen @site.count)
                (> (- @site.id @site.last-id) 1000))
        (return-from crawl-geo rez)))))

(defun scrape-geo (out-dir &key (gds-id 1) (gse-id 1) gds-count gse-count)
  (with ((counts (? (crawlik:crawl (make 'geo)) 0))
         (((gds :gds) (gse :gse)) ? counts)
         (gds-crawler (make 'geo-gds :id gds-id
                                     :last-id gds-id
                                     :seen (length *gds*)
                                     :count (or gds-count (parse-integer gds))
                                     :out-dir out-dir))
         (gse-crawler (make 'geo-gse :id gse-id
                                     :last-id gse-id
                                     :seen (length *gse*)
                                     :count (or gse-count (parse-integer gse))
                                     :out-dir out-dir)))
    (bt:make-thread
     (lambda ()
       (format *debug-io* "Starting to crawl GDS (count=~A): " gds)
       (crawlik:crawl gds-crawler)
       (format *debug-io* "done (crawled ~A items).~%"
               (- @gds-crawler.seen (length *gds*))))
     :name "GDS scraper")
    (bt:make-thread
     (lambda ()
       (format *debug-io* "Starting to crawl GSE (count=~A): " gse)
       (crawlik:crawl gse-crawler)
       (format *debug-io* "done (crawled ~A items).~%"
               (- @gse-crawler.seen (length *gse*))))
     :name "GSE scraper")))

(defun scrape-libstrats (geo rec)
  (remove
   nil
   (sort (nlp:uniq (map* ^(let ((raw (drakma:http-request
                                      (fmt "https://www.ncbi.nlm.nih.gov/geo/~
                                           query/acc.cgi?acc=~A" %))))
                            (when-it (search "Library strategy" raw)
                              (mkeyw (slice (first (re:all-matches-as-strings
                                                    "<td>([^<]+)" raw :start it))
                                            #.(length "<td>")))))
                         (re:all-matches-as-strings
                          "GSM\\d+"
                          (drakma:http-request
                           (fmt "https://www.ncbi.nlm.nih.gov/geo/~
                                download/?format=xml&acc=GSE~A"
                                @rec.id)))))
         'string<)))
  
(defun scrape-gsms (&optional (geo *gse*))
  (let ((gse (make 'geo-gse :out-dir (local-file "data/GEO/GEO_records/GSE/"))))
    (lparallel:pmap nil (lambda (rec)
                          (sleep (random 0.01))
                          (unless @rec.libstrats
                            (:= @rec.libstrats (scrape-libstrats gse rec))
                            (when-it @rec.libstrats
                              (with-open-file (out (fmt "~A/~A.txt" @gse.out-dir
                                                        @rec.id)
                                                   :direction :output
                                                   :if-exists :append)
                                (format out "LIBSTRATS~%~{~S~^ ~}~%" it)))
                            (princ (if @rec.libstrats "+" "."))))
                    geo)))

(defun all-libstrats (&key (geo *gse*))
  (let ((rez #h()))
    (dovec (rec geo)
      (dolist (libstrat @rec.libstrats)
        (when (null libstrat) (void @rec.libstrats))
        (:+ (get# libstrat rez 0))))
    rez))

(defun scrape-microarrayp (platform)
  (true (search "in situ oligonucleotide"
                (drakma:http-request
                 (fmt "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=~A"
                      (re:scan-to-strings "(GPL\\d+)" platform))))))


;;; in-memory storage

(defun load-geo (file)
  (let ((raw (split #\Newline (read-file file))))
    (make-geo-rec
     :id (parse-integer (pathname-name file))
     :title (? raw (1+ (position "TITLE" raw :test 'string=)))
     :organism (? raw (1+ (position "ORGANISM" raw :test 'string=)))
     :summary (when-it (position "SUMMARY" raw :test 'string=)
                (? raw (1+ it)))
     :design (when-it (position "DESIGN" raw :test 'string=)
               (? raw (1+ it)))
     :platform (when-it (position "PLATFORM" raw :test 'string=)
                 (? raw (1+ it)))
     :citations (when-it (position "CITATIONS" raw :test 'string=)
                  (? raw (1+ it)))
     :libstrats (when-it (position "LIBSTRATS" raw :test 'string=)
                  (mapcar 'read-from-string (split #\Space (? raw (1+ it))
                                                   :remove-empty-subseqs t)))
     :microarrayp (when-it (position "MICROARRAYP" raw :test 'string=)
                    (read-from-string (? raw (1+ it)))))))

(defun load-geo-dir (dir)
  (format *debug-io* "Loading GEO data from: ~A~%" dir)
  (let ((cc 0)
        rez)
    (dolist (file (directory (strcat dir "*.txt")))
      (when (zerop (rem (:+ cc) 100)) (format *debug-io* "."))
        (push (load-geo file) rez))
    (format *debug-io* " done.~%")
    (make-array (length rez) 
                :initial-contents (reverse rez)
                :adjustable t 
                :fill-pointer t)))
