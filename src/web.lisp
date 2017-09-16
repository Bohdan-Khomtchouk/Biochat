;;; Biochat work with GEO datasets
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


(defvar *hunch* (hunch:start-web 3344))

(defvar *gds-by-histone* (geo-group :histones *gds*))

(defvar *gds-same-histones*
  (pairs->ht
   (remove nil
           (map 'list (lambda (rec)
                        (let ((similar-recs
                                (remove rec
                                        (reduce 'append
                                                (mapcar ^(? *gds-by-histone*
                                                            (when (search-rec % rec)
                                                              %))
                                                        *histones*)))))
                          (when (rest similar-recs)
                            (pair rec (coerce similar-recs 'vector)))))
                                
                *gds*))))

;; (defvar *gds-geo-groups* (merge-hts (geo-group :histones *gds*)
;;                                     (geo-group :organisms *gds*)))

;; (defvar *gse-geo-groups* (merge-hts (geo-group :histones *gse*)
;;                                     (geo-group :organisms *gse*)))

(defparameter *geo-sim-methods*
  '((cos-sim "Cosine similarity of document vectors")
    (euc-sim "Euclidian distance-based similarity of document vecctors")
    #+nil (wn-sim "Pubmed Wordnet-based similarity of documents")))

(defparameter *geo-sim-filters*
  '((:histone "Histone")
    (:organism "Same organism")))

(defparameter *geo-organisms*
  (mapcar 'lt
          (sort (ht->pairs (nlp:uniq (map* 'gr-organism *geo-db*) :raw t))
                '> :key 'rt)))

;; (defvar *pubdata-geo-groups* #h())
;; (bt:make-thread ^(:= *pubdata-geo-groups* (geo-group :pubdata-wordnet))
;;                 :name "Pubdata geo groups builder")


;;; urls

(url "/static/:file" (file)
  (htt:handle-static-file (local-file (fmt "web/static/~A" file))))

(url "/" ()
  (who:with-html-output-to-string (out)
    (:html
     (:head
      (:title "Biochats")
      (:link :href "/static/style.css" :rel "stylesheet" :type "text/css")
      (:script :type "text/javascript" :src "/static/jquery-1.11.3.js" "")
      (:script :type "text/javascript" :src "/static/main.js" ""))
     (:body
      (:div :class "page"
            (:h1 "Biochats demo")
            (:div :style "font-size: smaller; color: gray;"
                  "Here, you can find the most similar records from the "
                  (:a :href "https://www.ncbi.nlm.nih.gov/geo/" "GEO DB")
                  ". To do that, you have to put in a particular record's "
                  "ID (and optionally select the number of similar records "
                  "to show). For instance, in record: "
                  "https://www.ncbi.nlm.nih.gov/sites/GDSbrowser?acc=GDS5879 "
                  "the input number is GDS5879. ")
                  ;; "The GSE records are also supported: "
                  ;; "for https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE425
                  ;;  enter GSE425.")
            (:form :action "/search" :method "GET" :id "search-form"
                   :onsubmit "return search()"
                   (:label :for "gid" "Enter GEO record id:") " "
                   (:input :type "text" :name "gid" :id "gid" :size "30") " "
                   (:label :for "count" "count:") " "
                   (:input :type "text" :name "count" :id "count" :size "3"
                           :value "10")
                   (:br)
                   (:div :class "box" :id "sim-methods"
                    "Choose similarity methods:" (:br)
                    (loop :for (method desc) :in *geo-sim-methods* :do
                      (who:htm
                       (:input :type :checkbox :name "sim-methods"
                               :value method :checked t)
                       (:label :for "sim-methods"
                               (who:str (string-downcase desc)))
                       (:br))))
                   (:div :class "box" :id "sim-filters"
                    "Choose additional filters:" (:br)
                    (loop :for (filter desc) :in *geo-sim-filters* :do
                      (who:htm
                       (:input :type :checkbox
                               :value filter :name "sim-filters")
                       (:label :for "sim-filters"
                               (who:str (string-downcase desc)))
                       (:br))))
                   #+nil
                   (:div :class "box" :id "sim-organisms"
                         "Look only in these organisms:" (:br)
                         (loop :for organism :in *geo-organisms* :do
                           (who:htm
                            (:input :type :checkbox
                                    :value organism :name "sim-organisms")
                            (:label :for "sim-organisms"
                                    (who:str organism))
                            " ")))
                   (:div (:input :type "submit" :value "Search")))
            (:br)
            (:div :id "search-results" ""))))))

(url "/search" (gid sim-methods sim-filters sim-organisms
                (count :parameter-type 'integer :init-form 10))
  (flet ((not-found ()
           (who:with-html-output-to-string (out)
             (who:fmt "No record with ID ~A found in GEO database." gid))))
    (if (< (length gid) 4)
        (not-found)
        (with ((type (mkeyw (slice gid 0 3)))
               (id (parse-integer (slice gid 3) :junk-allowed t))
               (db (case type
                     (:gds *gds*)
                     (:gse *gse*)))
               (vecs (case type
                       (:gds *gds-vecs*)
                       (:gse *gse-vecs*)))
               (methods (mapcar ^(mksym % :package :b42)
                                (split #\, sim-methods :remove-empty-subseqs t)))
               (filters (or (mapcar 'mkeyw (split #\, sim-filters
                                                  :remove-empty-subseqs t))
                            (split #\, sim-organisms :remove-empty-subseqs t))))
          (if-it (find id db :key 'gr-id)
                 (who:with-html-output-to-string (out)
                   (:div "Requested record:")
                   (who:str (format-geo-rec type it))
                   (:hr)
                   (:div "Closest records:")
                   (:ol (let ((*geo-db* db)
                              (var-*geo-vecs* vecs))
                          (when filters
                            (let (db vecs)
                              (dotimes (i (length *geo-db*))
                                (let ((rec (? *geo-db* i)))
                                  (when (some (lambda (filter)
                                                (case filter
                                                  (:histone
                                                   (if-it (? *gds-same-histones*
                                                             it)
                                                          (member rec it)
                                                          t))
                                                  (:organism
                                                   (string= @rec.organism
                                                            @it.organism))
                                                  (otherwise
                                                   (string= @rec.organism
                                                            filter))))
                                              filters)
                                    (push rec db)
                                    (push (? *geo-vecs* i) vecs))))
                              (:= *geo-db* (coerce db 'vector))
                              (:= var-*geo-vecs* (coerce vecs 'vector))))
                          (loop :for (r m) :in (find-closest-recs
                                                it count :methods methods) :do
                            (who:htm (:li (who:str (format-geo-rec type r m))))))))
                 (not-found))))))

;;; utils

(defun format-geo-rec (type rec &optional method)
  (who:with-html-output-to-string (out)
    (:div :class "geo-rec"
          (:div (who:fmt "GEO # ~A~A - ~A (~A)~@[ [~(~A~)]~]"
                         type @rec.id @rec.title @rec.organism
                         (when-it (car (assoc1 method *geo-sim-methods*))
                           (strjoin #\Space (take 3 (re:split "\\b" it))))))
          (:blockquote (who:str @rec.summary)))))

(defun find-closest-recs (rec count
                          &key (methods (mapcar 'first *geo-sim-methods*)))
  (mapcar ^(pair (lt (lt %))
                 (rt %))
          (take count
                (sort (remove-duplicates
                       (reduce 'append
                               (mapcar (lambda (method)
                                         (when (member method methods)
                                           (mapcar ^(pair % method)
                                                   (vec-closest-recs
                                                    rec :measure method))))
                                       '(cos-sim euc-sim)))
                       :key 'lt)
                      '> :key (=> rt lt)))))
                 
