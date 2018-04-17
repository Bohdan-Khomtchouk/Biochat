;;; Biochat utilities
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)

(eval-always
  (:= drakma:*drakma-default-external-format* :utf-8)
  (:= mat:*default-mat-ctype* :float))


(defun geo-toks (rec)
  "Geo record's REC tokens."
  (append (nlp:tokenize nlp:<word-tokenizer> @rec.title)
          (flat-map ^(nlp:tokenize nlp:<word-tokenizer> %)
                    (nlp:tokenize nlp:<sent-splitter> @rec.summary))
          (nlp:tokenize nlp:<word-tokenizer> @rec.design)))

(defun lemmas (rec)
  "Produce a list of lemmas for a list of TOKS."
  (mapcar ^(or (nlp:lemmatize nlp:<wikt-dict> (string-downcase %))
               %)
          @rec.toks))

(defun html-str (tree)
  "Convert a CRAWLIK HTML tree to a string."
  (etypecase tree
    (list (let (sink)
            (doleaves (node tree)
              (unless (blankp node)
                (push node sink)))
            (strjoin #\Space (reverse sink))))
    (string tree)))


;;; hash set

(defun hash-set (seq &key (test 'eql))
  (let ((rez (make-hash-table :test test)))
    (map nil ^(set# % rez t) seq)
    rez))

(defun inter# (hs1 hs2)
  (let ((rez (make-hash-table :test (hash-table-test hs1))))
    (dotable (k _ hs1)
      (when (in# k hs2)
        (set# k rez t)))
    rez))

(defun union# (hs1 hs2)
  (let ((rez (make-hash-table :test (hash-table-test hs1))))
    (dotable (k _ hs1)
      (set# k rez t))
    (dotable (k _ hs2)
      (set# k rez t))
    rez))

(defun diff# (hs1 hs2)
  (let ((rez (make-hash-table :test (hash-table-test hs1))))
    (dotable (k _ hs1)
      (unless (in# k hs2)
        (set# k rez t)))
    rez))

(defun xor# (hs1 hs2)
  (let ((rez (make-hash-table :test (hash-table-test hs1))))
    (dotable (k _ hs1)
      (unless (in# k hs2)
        (set# k rez t)))
    (dotable (k _ hs2)
      (unless (in# k hs1)
        (set# k rez t)))
    rez))
