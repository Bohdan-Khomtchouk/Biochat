;;; Biochat bag-of-words similarity methods
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


;;; TF-IDF

(defun calc-tfidf (texts)
  (let ((n (length texts))
        (tf #h(equal))
        (idf #h(equal)))
    (dolist (text texts)
      (let ((cur #h(equal))
            (len (length text)))
        (dolist (tok text)
          (:+ (get# tok cur 0)))
        (dotable (tok freq cur)
          (:+ (get# tok tf 0) (float (/ freq len)))
          (:+ (get# tok idf 0)))))
    (dotable (tok freq idf)
      (:= (? idf tok) (log (/ n freq))))
    (values tf
            idf)))

(defun tfidf (word)
  (* (sqrt (? *tf* word))
     (? *idf* word)))

;;; comparison of documents

(defun tok-closest-recs (rec &key (measure 'tfidf-sim))
  (with ((rez (sort (map* ^(pair % (call measure rec %))
                          *geo-db*)
                    '> :key 'rt)))
    (when (plusp (length rez))
      (subseq rez 1))))  ; leave out self

(defun tfidf-sim (rec1 rec2 &key (tfidf 'tfidf))
  (with ((lemmas1 (lemmas rec1))
         (lemmas2 (lemmas rec2))
         (common (mapcar ^(expt (call tfidf %) 2)
                         (keys (inter# (hash-set lemmas1 :test 'equal)
                                       (hash-set lemmas2 :test 'equal))))))
    (/ (reduce '+ common)
       (reduce '* (mapcar ^(mat:nrm2 (mat:array-to-mat (map 'vector 'tfidf %)))
                          (list lemmas1 lemmas2))))))

(defun bm25-sim (rec1 rec2 &key (k1 1.2))
  (tfidf-sim rec1 rec2 :tfidf ^(* (/ (1+ k1)
                                       (+ k1 (? *tf* %)))
                                    (? *tf* %)
                                    (? *idf* %))))
