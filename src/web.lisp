;;; Biochat work with GEO datasets
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


(defvar *hunch* (hunch:start-web 3344))

(defvar *gds-geo-groups* (merge-hts (geo-group :histones *gds*)
                                    (geo-group :organisms *gds*)))

(defvar *gse-geo-groups* (merge-hts (geo-group :histones *gse*)
                                    (geo-group :organisms *gse*)))

(defparameter *geo-sim-methods*
  '((cos-sim "Cosine similarity of document vectors")
    (euc-sim "Euclidian distance-based similarity of document vecctors")
    #+nil (wn-sim "Pubmed Wordnet-based similarity of documents")))

(defparameter *geo-sim-filters*
  '((histones "Histone")
    (organism "Same organism")))

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
                  "the input number is GDS5879. "
                  "The GSE records are also supported: "
                  "for https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE425
                   enter GSE425.")
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
                   #+nil
                   (:div :class "box" :id "sim-filters"
                    "Choose additional filters:" (:br)
                    (loop :for (filter desc) :in *geo-sim-filters* :do
                      (who:htm
                       (:input :type :checkbox
                               :value filter :name "sim-filters")
                       (:label :for "sim-filters"
                               (who:str (string-downcase desc)))
                       (:br))))
                   (:div (:input :type "submit" :value "Search")))
            (:br)
            (:div :id "search-results" ""))))))

(url "/search" (gid sim-methods sim-filters
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
               (methods (mapcar 'mkeyw (split #\, sim-methods)))
               (filters (mapcar 'mkeyw (split #\, sim-filters))))
          (if-it (find id db :key 'gr-id)
                 (who:with-html-output-to-string (out)
                   (:div "Requested record:")
                   (who:str (format-geo-rec type it))
                   (:hr)
                   (:div "Closest records:")
                   (:ol (let ((*geo-db* db)
                              (*geo-vecs* vecs))
                          (dolist (r (find-closest-recs it count
                                                        :methods methods
                                                        :filters filters))
                            (who:htm (:li (who:str (format-geo-rec type r))))))))
                 (not-found))))))

;;; utils

(defun format-geo-rec (type rec)
  (who:with-html-output-to-string (out)
    (:div :class "geo-rec"
          (:div (who:fmt "GEO # ~A~A - ~A" type @rec.id @rec.title))
          (:blockquote (who:str @rec.summary)))))

(defun find-closest-recs (rec count &key (methods *geo-sim-methods*)
                                         (filters *geo-sim-filters*))
  (take count
        (remove nil
                (remove-duplicates
                 (apply 'interleave
                        (remove-if 'null
                                   (list (when (member :cos-sim methods)
                                           (vec-closest-recs
                                            rec :measure 'cos-sim))
                                         (when (member :euc-sim methods)
                                           (vec-closest-recs
                                            rec :measure 'euc-sim)))))))))
