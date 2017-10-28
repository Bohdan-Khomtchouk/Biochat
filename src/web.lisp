;;; Biochat work with GEO datasets
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


(defvar *hunch* (hunch:start-web 3344))
 
(defparameter *geo-sim-methods*
  '((cos-sim "Cosine similarity of document vectors")
    (euc-sim "Euclidian distance-based similarity of document vectors")
    (eucos-sim "Euclidian-cosine averaged similarity")
    (smoothed-cos-sim "Smoothed cosine similarity")
    (tfidf-sim "TFIDF similarity")
    (bm25-sim "BM25 similarity - a variant of TFIDF")
    #+nil (wn-sim "Pubmed Wordnet-based similarity of documents")))

(defparameter *geo-sim-filters*
  '((:histone "Histone")
    (:organism "Same organism")))


;;; urls

(url "/static/:file" (file)
  (htt:handle-static-file (local-file (fmt "web/static/~A" file))))

(url "/" ()
  (who:with-html-output-to-string (out)
    (:html
     (:head
      (:title "GEObrain")
      (:link :href "/static/style.css" :rel "stylesheet" :type "text/css")
      (:script :type "text/javascript" :src "/static/jquery-1.11.3.js" "")
      (:script :type "text/javascript" :src "/static/main.js" "")
      (:script :type "text/javascript"
               "$(document).ready(function () {
                   $('input[name=simmethods]:first').attr('checked', true);
                });"))
     (:body
      (:div :class "page"
            (:h1 "GEObrain demo")
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
                       (:input :type :radio :name "simmethods" :value method)
                       (:label :for "simmethods"
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
                   (:div :class "box" :id "sim-organisms"
                         "Look only in these organisms: "
                         (:a :href "#" :onclick "return toggle_simorganisms()"
                             :class "black"
                             "▼")
                         (:br)
                         (:div :id "simorganisms"
                          (loop :for organism :in *geo-organisms* :do
                            (who:htm
                             (:div :class "organisms-box"
                              (:input :type :checkbox
                                      :value organism :name "sim-organisms")
                              (:label :for "sim-organisms" :class "spacelabel"
                                      (who:str organism)))
                             " "))))
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
               (db *gds*
                   #+nil (case type
                     (:gds *gds*)
                     (:gse *gse*)))
               (vecs *gds-vecs*
                     #+nil (case type
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
                              (*geo-vecs* vecs))
                          (when filters
                            (let (db vecs)
                              (dotimes (i (length *geo-db*))
                                (let ((rec (? *geo-db* i)))
                                  (when (some (lambda (filter)
                                                (case filter
                                                  (:histone
                                                   (if-it (? *geo-same-histones*
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
                              (:= *geo-vecs* (coerce vecs 'vector))))
                          (loop :for (r m s) :in (find-closest-recs
                                                  it count :methods methods) :do
                            (who:htm (:li (who:str (format-geo-rec type r m s))))))))
                 (not-found))))))

;;; utils

(defun format-geo-rec (type rec &optional method score)
  (who:with-html-output-to-string (out)
    (:div :class "geo-rec"
          (:div (who:fmt "GEO # ~A~A - ~A (~A)~@[ / ~(~A~)~]~@[: ~A~]"
                         type @rec.id @rec.title @rec.organism
                         (when-it (car (assoc1 method *geo-sim-methods*))
                           (strjoin #\Space (take 3 (re:split "\\b" it))))
                         score))
          (:blockquote (who:str @rec.summary)))))

(defun find-closest-recs (rec count
                          &key (methods (mapcar 'first *geo-sim-methods*)))
  (mapcar ^(list (lt (lt %))
                 (rt %)
                 (rt (lt %)))
          (take count
                (sort (remove-duplicates
                       (take (* 2 count)
                             (append
                              (reduce 'append
                                      (mapcar (lambda (method)
                                                (when (member method methods)
                                                  (mapcar ^(pair % method)
                                                          (vec-closest-recs
                                                           rec :measure method))))
                                              '(cos-sim euc-sim eucos-sim
                                                smoothed-cos-sim)))
                              (reduce 'append
                                      (mapcar (lambda (method)
                                               (when (member method methods)
                                                 (map 'list ^(pair % method)
                                                      (tok-closest-recs
                                                       rec :measure method))))
                                             '(tfidf-sim bm25-sim)))))
                       :key 'lt)
                      '> :key (=> rt lt)))))
                 
