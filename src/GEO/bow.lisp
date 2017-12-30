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
  (with ((toks (geo-toks rec))
         (rez (sort (map* ^(pair % (call measure toks (geo-toks %)))
                          *geo-db*)
                    '> :key 'rt)))
    (when (plusp (length rez))
      (subseq rez 1))))  ; leave out self

(defun tfidf-sim (toks1 toks2 &key (tfidf 'tfidf))
  (let ((common (mapcar ^(expt (call tfidf %) 2)
                        (keys (inter# (hash-set (lemmas toks1) :test 'equal)
                                      (hash-set (lemmas toks2) :test 'equal))))))
    (/ (reduce '+ common)
       (reduce '* (mapcar (lambda (toks)
                            (mat:nrm2 (mat:array-to-mat
                                       (map 'vector tfidf
                                            (lemmas (nlp:uniq toks))))))
                          (list toks1 toks2))))))

(defun bm25-sim (toks1 toks2 &key (k1 1.2))
  (tfidf-sim toks1 toks2 :tfidf ^(* (/ (1+ k1)
                                       (+ k1 (? *tf* %)))
                                    (? *tf* %)
                                    (? *idf* %))))
