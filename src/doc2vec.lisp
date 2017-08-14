;;; BIOCHAT2 doc2vec implementation
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


;;; pubmed vectors

(defvar-lazy *pubmed*
  (nlp:init-vecs (make 'nlp:mem-vecs :order 200) :wvlib
                 (local-file "data/PubMed-shuffle-win-30.bin"))
  "This variable will be initialized on first access and, for it to work,
   a file PubMed-shuffle-win-30.bin from here:
   https://drive.google.com/open?id=0BzMCqpcgEJgiUWs0ZnU0NlFTam8")

(defun text-vec (text)
  (let ((words (nlp:tokenize nlp:<word-tokenizer> text)))
    (mat:scal! (/ 1 (length words))
               (reduce 'mat:m+ (mapcar ^(mat:array-to-mat (nlp:2vec *pubmed* %))
                                       words)))))

(defun geo-vec (geo &key (w #h(:title 0.0 :summary 1.0 :organism 0.0)))
  (reduce '
   mat:m+ (list (mat:scal! (? w :title) (text-vec @geo.title))
                        (mat:scal! (? w :summary) (text-vec @geo.summary))
                        (mat:scal! (? w :organism) (text-vec @geo.organism)))))

(defvar-lazy *geo-vecs* (map* 'geo-vec *geo-db*))


;;; simple similarity

(defun cos-sim (v1 v2)
  (/ (mat:dot v1 v2)
     (* (mat:nrm2 v1)
        (mat:nrm2 v2))))

(defun euc-sim (v1 v2)
  (/ 1 (1+ (mat:nrm2 (mat:m- v1 v2)))))

(defun weighted-sim (v1 v2)
  (sqrt (* (cos-sim v1 v2)
           (euc-sim v1 v2))))


(defun closest-vecs (vec &key (vecs *geo-vecs*) (measure 'cos-sim))
  (subseq (sort (map* ^(pair %% (call measure vec %))
                      vecs (range 0 (length vecs)))
                '> :key 'rt)
          1))

(defun vec-closest-recs (rec &key (db *geo-db*) (measure 'cos-sim))
  (map 'list ^(? db (lt %))
       (closest-vecs (geo-vec rec))))
                  

;;; clustering

(defun cluster-dist (dists v v1 v2)
  (/ (+ (or (? dists (pair v v1))
            (? dists (pair v1 v)))
        (or (? dists (pair v v2))
            (? dists (pair v2 v))))
     2))

(defun tree-cluster-vecs (&key (vecs *geo-vecs*) (measure 'cos-sim))
  (with ((dists #h(equalp))
         (clusters #h())
         (total (length vecs))
         (cid (1- total)))
    (labels ((cid->vert (id)
               (cond ((listp id) (mapcar #'cid->vert id))
                     ((< id total) id)
                     (t (mapcar #'cid->vert (? clusters id 0))))))
      (dotimes (i total)
        (dotimes (j total)
          (when (> i j)
            (:= (? dists (pair i j))
                (call measure (? vecs i) (? vecs j))))))
      (loop :repeat total :do
        (let ((max 0)
              arg)
          (dotable (k v dists)
            (when (> v max)
              (:= max v
                  arg k)))
          (when arg
            (let ((verts (flatten arg)))
              (:= (? clusters (:+ cid))
                  (pair (mapcar #'cid->vert verts)
                        max))
              (rem# arg dists)
              (dotable (k _ dists)
                (when-it (or (and (member (lt k) verts) 1)
                             (and (member (rt k) verts) 0))
                  (getset# (pair (? k it) cid) dists
                           (apply 'cluster-dist dists (? k it) verts))
                  (rem# k dists)))))))
      (? clusters cid 0))))

(defun tree-closest-recs (rec &key (db *geo-db*) (root *geo-tree*))
  (let ((rec-id (position rec db))
        (q root)
        (seen #h())
        path
        rez)
    (loop (let ((cur (pop q)))
            (if (atom cur)
                (when (= cur rec-id)
                  (return))
                (progn
                  (push cur path)
                  (dolist (node (reverse cur))
                    (push node q))))))
    (labels ((collect-recs (tree)
               (dolist (node tree)
                 (if (atom node)
                     (unless (or (= node rec-id)
                                 (? seen node))
                       (push (? db node) rez)
                       (:= (? seen node) t))
                     (collect-recs node)))))
      (dolist (step path)
        (collect-recs step)))
    (reverse rez)))


;;; serialization

(defun save-geo-tree (tree file)
  (with-standard-io-syntax
    (with-out-file (out file)
      (format out "~A"
              (mapleaves ^(? *geo-db* % 'id) tree))))
  file)

(defun load-geo-tree (file)
  (with-open-file (in file)
    (mapleaves ^(position % *geo-db* :key 'gr-id)
               (read in))))

(defpar *geo-tree* (load-geo-tree (local-file "data/geo-tree-cos.lisp")))
