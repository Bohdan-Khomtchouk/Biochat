;;; Biochat doc2vec implementation
;;; see LICENSE file for permissions

(in-package :b42)
(named-readtables:in-readtable rutilsx-readtable)


;;; PubMed vectors

(defvar *pubmed*
  (nlp:init-vecs (make 'nlp:mem-vecs :order 200) :wvlib
                 (local-file "data/PubMed-shuffle-win-30.bin"))
  "This variable will be initialized on first access and, for it to work,
   a file PubMed-shuffle-win-30.bin from here:
   https://drive.google.com/open?id=0BzMCqpcgEJgiUWs0ZnU0NlFTam8")

(defun 2medvec (word)
  (mat:array-to-mat (nlp:2vec *pubmed* word)))

(defvar *zero-vec* (2medvec ""))

(defun text-vec (text)
  (if-it (remove-if (lambda (word)
                      (or (notevery ^(or (eql #\- %) (alphanumericp %))
                                    word)
                          (nlp:stopwordp word)))
                    (mapcan ^(mapcar 'nlp:tok-word (nlp:sent-toks %))
                            (flatten (nlp:tokenize nlp:*full-text-tokenizer*
                                                   text))))
         (mat:scal! (/ 1 (length it))
                    (reduce 'mat:m+ (mapcar '2medvec it)))
         *zero-vec*))

(defun geo-vec (geo &key (w #h(:title 0.0 :summary 1.0 :organism 0.0)))
  (reduce 'mat:m+ (list (mat:scal! (? w :title) (text-vec @geo.title))
                        (mat:scal! (? w :summary) (text-vec @geo.summary))
                        (mat:scal! (? w :organism) (text-vec @geo.organism)))))


;;; simple vector similarity

(defun closest-vecs (vec vecs measure &key (n 10))
  (let ((maxs '(0))
        (args '(maxs)))
    (dotimes (i (length vecs))
      (with ((v (svref vecs i))
             (sim (call measure vec v))
             (ind (doindex (j max maxs
                              j)
                    (when (< sim max)
                      (return j)))))
        (when (plusp ind)
          (:= maxs (append (subseq maxs 0 ind)
                           (list sim)
                           (subseq maxs ind))
              args (append (subseq args 0 ind)
                           (list i)
                           (subseq args ind)))
          (when (> (length maxs) (1+ n))
            (pop maxs)
            (pop args)))))
    (reversef args)
    (reversef maxs)
    (when (>= (first maxs) 1)
      (pop args)
      (pop maxs))
    (values (take n args)
            (take n maxs))))

(defun vec-closest-recs (rec &key (measure 'cos-sim) (n 10))
  (apply 'mapcar ^(pair (? *geo-db* %)
                        %%)
         (multiple-value-list (closest-vecs (geo-vec rec) *geo-vecs* measure
                                            :n n))))

(defun cos-sim (v1 v2)
  (declare (ignore _))
  (/ (mat:dot v1 v2)
     (* (mat:nrm2 v1)
        (mat:nrm2 v2))))

(defun euc-sim (v1 v2)
  (declare (ignore _))
  (/ 1 (1+ (mat:nrm2 (mat:m- v1 v2)))))

(defun eucos-sim (v1 v2)
  (sqrt (* (cos-sim v1 v2)
           (euc-sim v1 v2))))

(defun smoothed-cos-sim (v1 v2 &key (smoothing 5))
  (with ((toks-s1 (hash-set @v1.toks :test 'equalp))
         (toks-s2 (hash-set @v2.toks :test 'equalp))
         (overlap (/ (ht-count (inter# toks-s1 toks-s2))
                     (ht-count (union# toks-s1 toks-s2)))))
    (* (cos-sim v1 v2)
       (/ overlap (+ smoothing overlap)))))  ; leave out self


;;; clustering

(defun cluster-dist (dists v v1 v2)
  (/ (+ (or (? dists (pair v v1))
            (? dists (pair v1 v)))
        (or (? dists (pair v v2))
            (? dists (pair v2 v))))
     2))

(defun tree-cluster-vecs (&key (measure 'cos-sim))
  (with ((dists #h(equalp))
         (clusters #h())
         (total (length *geo-vecs*))
         (cid (1- total)))
    (labels ((cid->vert (id)
               (cond ((listp id) (mapcar #'cid->vert id))
                     ((< id total) id)
                     (t (mapcar #'cid->vert (? clusters id 0))))))
      (dotimes (i total)
        (dotimes (j total)
          (when (> i j)
            (:= (? dists (pair i j))
                (call measure (? *geo-vecs* i) (? *geo-vecs* j))))))
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

;(defpar *geo-tree* (load-geo-tree (local-file "data/GEO/GEO-tree-cos.lisp")))
