;;; Biochat work with GEO datasets
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


(defvar *hunch* (hunch:start-web 3344))

(defvar *basic-geo-groups* (merge-hts
                            (geo-group :histones)
                            (geo-group :organisms)))

(defvar *pubdata-geo-groups* #h())
(bt:make-thread ^(:= *pubdata-geo-groups* (geo-group :pubdata-wordnet))
                :name "Pubdata geo groups builder")


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
            (:form :action "/search" :method "GET" :id "search-form"
                   :onsubmit "return search()"
                   (:label :for "gid" "Enter GEO record id:") " "
                   (:input :type "text" :name "gid" :id "gid" :size "30") " "
                   (:label :for "count" "count:") " "
                   (:input :type "text" :name "count" :id "count" :size "3"
                           :value "10") " "
                   (:input :type "submit" :value "Search"))
            (:br)
            (:div :id "search-results" ""))))))

(url "/search" ((gid :parameter-type 'integer)
                (count :parameter-type 'integer :init-form 10))
  (if-it (find gid *geo-db* :key 'gr-id)
         (who:with-html-output-to-string (out)
           (:div "Requested record:")
           (who:str (format-geo-rec it))
           (:hr)
           (:div "Closest records:")
           (:ol (dolist (r (find-closest-recs it count))
                  (who:htm (:li (who:str (format-geo-rec r)))))))
         (who:with-html-output-to-string (out)
           (who:fmt "No record with ID ~A found in GEO database." gid))))

;;; utils

(defun format-geo-rec (rec)
  (who:with-html-output-to-string (out)
    (:div :class "geo-rec"
          (:div (who:fmt "GEO # ~A - ~A" @rec.id @rec.title))
          (:blockquote (who:str @rec.summary)))))

(defun find-closest-recs (rec count)
  (take count
        (remove nil
                (remove-duplicates
                 (apply 'interleave
                        (remove-if 'null
                                   (list (let (rez)
                                           (dotable (k v *basic-geo-groups*)
                                             (when-it (find rec v)
                                               (push it rez)))
                                           (loop :while (< (length rez) count)
                                                 :do (push nil rez))
                                           (reverse rez))
                                         (vec-closest-recs rec :measure 'cos-sim)
                                         (vec-closest-recs rec :measure 'euc-sim)
                                         (let (rez)
                                           (dotaтble (k v *pubdata-geo-groups*)
                                             (when-it (find rec v)
                                               (push it rez)))
                                           (loop :while (< (length rez) count)
                                                 :do (push nil rez))
                                           (reverse rez)))))))))
