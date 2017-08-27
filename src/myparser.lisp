;;; (load (compile-file "myparser.lisp"))

#| Common top level functions:

(start-parse-server) ;; Inits, tests, starts the server on port 4242, and then hangs in an infinite sleep loop.
(commit-new-test) ;; When you have a new sentence to add to the test set.
(recreate-testnlp.html) ;; When the test set changes.
(init-grammar) ;; If the grammar changes.
(drive-parser "...") ;; Most inner call.
(recompute-all-tests) ;; Re-runs all tests, recreating tests.lisp and testnlp.html

|#

;;; Based on SYNTAX2.LISP: The PSG-based natural language parser with
;;; semantics from Section 19.5 of Norvig's PAIP.

(defvar *pprint+?* t)
(defun pprint+ (l &key label)
  (when *pprint+?*
    (when label (format t "~%vvvvvvvvvvv ~a vvvvvvvvvvv~%" label))
    (pprint l) (terpri)
    (when label (format t "~%^^^^^^^^^^^ ~a ^^^^^^^^^^^~%" label)))

  l)

(eval-when
 (:compile-toplevel :load-toplevel :execute)
 (ql:quickload :hunchentoot)
 (ql:quickload :cl-json))


(declaim (optimize (debug 3)))

(defvar *grammar* "The grammar used by GENERATE.")

(defstruct (rule (:type list)) lhs -> rhs sem)

(defvar *tests* nil)

(defun dht (table &optional (n 10))
  (maphash #'(lambda (key value)
              (when (zerop (decf n)) (return-from dht))
              (format t "~s: ~s~%" key value))

     table))

(defstruct (parse) tree rem)

;;; So, I'll bet you're wondering why the defstruct for tree is
;;; commented out and replaced with definitions, wheraeas the others
;;; aren't. Long story: I had in mind at one point automatically
;;; translating this code into javascript, but the xlator doesn't
;;; understand lisp defstructs, so I replaced them with equivalent
;;; code. Later I decided not to do this translation so I put the
;;; defstructs above back, but for some reason this one can't be put
;;; back. The parser doesn't err out, but also doesn't work! I must
;;; have changed something in the body code as well to go with this
;;; rewrite, and haven't bothered to figure out why this doesn't
;;; work. FFF

;(defstruct (tree (:type list) (:include rule) (:copier nil)
;                 (:constructor new-tree (lhs sem rhs))))
(defun new-tree (lhs sem rhs) (list lhs sem rhs))
(defun tree-lhs (tree) (first tree))
(defun tree-sem (tree) (second tree))
(defun tree-rhs (tree) (third tree))

(defun parse-lhs (parse) (tree-lhs (parse-tree parse)))

;; Categories to consider for unknown words.
;(defparameter *open-categories* '(N V))
(defparameter *open-categories* '(N V A))

(defvar *word->lexical-rules* (make-hash-table :test #'equal))
(defun lexical-rules (word)
  "Return a list of rules with word on the right hand side."
  (or (gethash word *word->lexical-rules*)
      (mapcar #'(lambda (cat) `(,cat -> ,word)) *open-categories*)))

(defvar *cat->rules* (make-hash-table :test #'equal))
(defun rules-starting-with (cat)
  (gethash cat *cat->rules*))

(defun first-or-nil (x)
  "The first element of x if it is a list; else nil."
  (if (consp x) (first x) nil))

(defun complete-parses (parses)
  "Those parses that are complete (have no remainder)."
  (remove-if-not #'null parses :key #'parse-rem))

(defun append1 (items item)
  "Add item to end of list of items."
  (append items (list item)))

(defun parser (words)
  "Return all complete parses of a list of words."
  (mapcar #'parse-tree (complete-parses (parse words))))

(defun parse (words)
  (unless (null words)
    (mapcan #'(lambda (rule)
               (extend-parse (rule-lhs rule) (rule-sem rule)
                         (list (first words)) (rest words) nil))
      (lexical-rules (first words)))))


(defun extend-parse (lhs sem rhs rem needed)
  "Look for the categories needed to complete the parse.
  This version has semantics."
  (if (null needed)
      ;; If nothing is needed, return this parse and upward extensions,
      ;; unless the semantics fails
      (let ((parse (make-parse :tree (new-tree lhs sem rhs) :rem rem)))
        (unless (null (apply-semantics (parse-tree parse)))
          (cons parse
                (mapcan
                  #'(lambda (rule)
                      (extend-parse (rule-lhs rule) (rule-sem rule)
                                    (list (parse-tree parse)) rem
                                    (rest (rule-rhs rule))))
                  (rules-starting-with lhs)))))
      ;; otherwise try to extend rightward
      (mapcan
        #'(lambda (p)
            (if (eq (parse-lhs p) (first needed))
                (extend-parse lhs sem (append1 rhs (parse-tree p))
                              (parse-rem p) (rest needed))))
        (parse rem))))

;;; For terminal nodes, just fetch the semantics.  Otherwise, apply
;;; the sem function to its constituents. The arg can be a lambda fn,
;;; or the name of a function, or a keyword. If it's a key, we emit
;;; the keyword, otherwise it calls the fn. The fn has to be either
;;; &rest, or must take exactly the number of arguments that are in
;;; the RHS of the pattern. The default is LIST.

(defun apply-semantics (tree)
  (if (terminal-tree-p tree)
      (tree-sem tree)
    (setf (second tree)
     (let ((label (tree-sem tree)))
        (cond ((null label)
               (apply #'list (mapcar #'tree-sem (tree-rhs tree))))
         ((keywordp label)
          (apply #'list (cons label (mapcar #'tree-sem (tree-rhs tree)))))
         ((and (listp label)
           (apply #'list (cons (car label)
                          (loop with rhs = (tree-rhs tree)
                               for l in (cdr label)
                               collect (tree-sem (nth (1- l) rhs)))))))
         (t (error "In apply-semantics: label is ~s which isn't understandable!" label)))))))

(defun terminal-tree-p (tree)
  "Does this tree have a single word on the rhs?"
  (and (length=1 (tree-rhs tree))
       (atom (first (tree-rhs tree)))))

(defun length=1 (x)
  "Is x a list of length 1?"
  (and (consp x) (null (cdr x))))

(defun find-all (item sequence &rest keyword-args
                 &key (test #'eql) test-not &allow-other-keys)
  "Find all those elements of sequence that match item,
  according to the keywords.  Doesn't alter sequence."
  (if test-not
      (apply #'remove item sequence
             :test-not (complement test-not) keyword-args)
      (apply #'remove item sequence
             :test (complement test) keyword-args)))

(defun plain-words (words)
  (loop for word in words collect `(,word -> ,word ,word)))
(defun typed-words (type words)
  (loop for word in words collect `(,type -> ,word ,(format nil "~a.~a" type word))))

(defvar *grammar* nil)

(defparameter *base-grammar*
  `((sentence -> (*mutphrase in *setting *relphrase *txphrase))
    (sentence -> (in *setting *mutphrase *relphrase *txphrase))
    (sentence -> (*mutphrase *relphrase *txphrase))
    (sentence -> (*mutphrase *relphrase *txphrase))
    (sentence -> (*mutphrase *relphrase *txphrase in *setting)) ;;...
    (sentence -> (*txphrase *relphrase *aephrase in *setting)) ;; added for adverse events
    (sentence -> (*txphrase *relphrase *aephrase))
    (sentence -> (*txphrase is *relphrase in *setting))
    (*setting -> (setting) :setting)
    (setting -> (patientphrase))
    (setting -> (experimentphrase))
    (setting -> (*cancerdesc))
    (experimentphrase -> (det experimentype numberword subjectphrase))
    (experimentphrase -> (det experimentype))
    (experimentype -> (trial) :trial)
    (experimentype -> (clinical trial) :trial)
    (experimentype -> (phase trialstatus clinical trial) :trial)
    (experimentype -> (rct) :rct)
    (experimentype -> (randomized controlled trial) :rct)
    (experimentype -> (laboratory experiment) :in_vitro)
    (experimentype -> (rare cases) :rare_cases)
    (experimentype -> (experiment) :experiment)
    (subjectphrase -> (<number> model))
    (subjectphrase -> (<number> model with *cancerdesc))
    (patientphrase -> (det persondesc ptword) :case_study)
    (patientphrase -> (det persondesc ptword with *cancerdesc))
    (*cancerdesc -> (cancerdesc) :dx)
    (cancerdesc -> (cancertype cancer))
    (cancerdesc -> (cancertype))
    (cancerdesc -> (metastatic cancerdesc))
    (cancerdesc -> (stage <number> cancerdesc))
    (persondesc -> (<number> year old) (:age 1))
    (persondesc -> (year old))
    (persondesc -> (elderly))
    (persondesc -> (middle age))
    (*mutphrase -> (mutationp) :aberration)
    (*mutphrase -> (*mutphrase and *mutphrase))
    (mutphrase -> (det mutphrase))
    (mutationp -> (gene expressionexpression))
    (mutationp -> (gene mutypeword))
    (mutationp -> (mutypeword gene))
    (gene -> (m))
;    (expressionexpression -> (suppression) :suppression)
;    (expressionexpression -> (expression) :expression)
;    (expressionexpression -> (over expression) :over_expression)
;    (expressionexpression -> (under expression) :under_expression)
    (*relphrase -> (conferword subrelation) (:relation 2))
    (*relphrase -> (relation) :relation)
    (*relphrase -> (conferword) :relation)
    (subrelation -> (relation))
    (subrelation -> (relation to))
    (conferword -> (confers))
    (conferword -> (confers to))
    (conferword -> (can relphrase))
    (conferword -> (significantly confers))
    (relation -> (good response) :sensitivity_to)
    (relation -> (bad response) :resistance_to)
    (relation -> (no response) :no_sensitivity)
    (relation -> (poor response) :resistance_to)
    (relation -> (sensitivity) :sensitivity_to)
    (relation -> (resistance) :resistance_to)
    (relation -> (no sensitivity or resistance) :no_sensitivity)
    (relation -> (off-label for) :off_label)
    (*txphrase -> (txphrase) :tx)
    (txphrase -> (det txphrase cocktail))
    (txphrase -> (txphrase and txphrase))
    (txphrase -> (txphrase txphrase))
    (txphrase -> (while taking txphrase))
    (txphrase -> (tx))
    (*aephrase -> (aephrase) :ae)
    (aephrase -> (det aephrase))
    (aephrase -> (aephrase and aephrase))
    (aephrase -> (aephrase aephrase))
    (aephrase -> (aephrase to aephrase)) ;; toxic to the heart...
    (aephrase -> (ae))
    ,@(typed-words 'ae '(toxicity toxic death cell bone organ liver kidney metabolic dysfunction heart GI discomfort
                         arrhythmia arrhythmias fibrillation fatigue weakness wobbliness nausea vertigo vomitting
                         severe immune system tract failure adverse event events seizures seizure disease
                         progression wooziness rash hospitalization fainting faintness pain painful blood pressure high
                         low weak sickness anemia disorder disorders cardiac arrest major distress))
    ,@(typed-words 'numberword '(involving containing with of))
    ,@(typed-words 'trialstatus '(I II III i ii iii))
    ,@(typed-words 'ptword '(patient man woman child))
    ,@(typed-words 'mutypeword '(deletion duplication insertion amplification methylation un-methylated expression))
    ,@(typed-words 'model '(patients mice rats tumors))
    ,@(typed-words 'confers '(confers confer conferred develop developed induce induced induces shows show showed causes
                              caused leads lead predicts predicted predict is accelerated accelerates accelerate))
    ,@(typed-words 'det '(a an the this))
    ,@(typed-words 'cancertype '(melanoma lung breast skin prostate brain gbm plga))
    ,@(plain-words '(expression suppression under over metastatic stage with cancer resistance patients elderly mice
                     laboratory experiment involving of containing patient man woman year old middle age for phase
                     and in rct randomized controlled trial cocktail no or sensitivity to is off-label good
                     bad poor response while taking clinical can significantly rare cases))))



;;; This is an ugly hack to pull the number of cases from the setting
;;; tree. It pulls out the first number it comes across. If there are
;;; no numbers, it returns nil.

(defun tree-extract-number (tree)
  (loop for i in (flatten tree)
   when (numberp i)
   do (return i)))

(defparameter *more-drugs* '(PACLITAXEL DEXAMETHASONE TMZ NIVOLUMAB KEPPRA CYCLOPHOSPHAMIDE))

(defun init-grammar ()
  (setf *grammar* *base-grammar*)
  (loop for mol in (trex-molecules)
        do (push `(m -> ,mol ,(format nil "M.~a" mol)) *grammar*))
  (loop for drug in (union *more-drugs* (trex-drugs))
        do (push `(tx -> ,drug ,(format nil "TX.~a" drug)) *grammar*))
  (loop for drug in (union *more-drugs* (trex-drugs))
        do (push `(aetx -> ,drug ,(format nil "AETX.~a" drug)) *grammar*))
  (init-rule-lkup-tbls)
  (format t "~%*GRAMMAR* has ~a entries~%" (length *grammar*)))

(defun init-rule-lkup-tbls ()
  (clrhash *cat->rules*)
  (loop for rule in *grammar*
   do (push rule (gethash (first-or-nil (rule-rhs rule)) *cat->rules*)))
  (clrhash *word->lexical-rules*)
  (loop for rule in *grammar*
   as rhs = (rule-rhs rule)
   if (symbolp rhs)
   do (push rule (gethash rhs *word->lexical-rules*))))


(defun preprocess-numbers (s)
  (loop for word in s
   when (numberp word)
   do
   (let ((rule `(<number> -> ,word ,word)))
      (pushnew rule *grammar* :test #'equal)
      (push rule (gethash word *word->lexical-rules*)))
   (let ((rule `(<number> -> (,word) list)))
      (pushnew rule *grammar* :test #'equal)
      (push rule (gethash word *cat->rules*)))))


(defun flatten (l)
  (cond ((null l) nil)
   ((atom l) (list l))
   (t (append (flatten (car l))
       (flatten (cdr l))))))

;;; Output for TrEx.

#| Example entry:

{"_id":"TTD-1",
 "cancer":"Melanoma",
 "Alias (modifier)":"",
 "relation":"efficacy",
 "reference":"Da Rocha Dias S, Cancer Res 2005, 65:10686-91",
 "note":"17-AAG is a HSP90 inhibitor",
 "molecule":{"state":"mut V600E",
             "name":"BRAF",
             "class":"DNA"},
 "hypothesis":{"condition":"BRAF mut V600E",
               "relation":"efficacy",
               "cancer":"Melanoma",
               "drug":"17-AAG"},
 "Modifier":"",
 "model":3,
 "condition":"BRAF mut V600E",
 "collaborations":["TTD"],
 "h":1,
 "drug":"17-AAG",
 "insightLabel":"TTD-1",
 "relationshipTo":"sensitivity to",
 "ref_url":"https://www.ncbi.nlm.nih.gov/pubmed/16322212"}


|#

(defun emit-trex-json (semantics o)
  (pprint+ semantics :label "EMIT-TREX-JSON semantics")
  (labels
   ((jsonize (l) (if l (with-output-to-string (s) (json:encode-json l s)) "null"))
    (find (key) (second (assoc key semantics)))
    (rsget (key) (jsonize (find key))))

   (format o "
      {\"cancer\":~a,
      \"relation\":~a,
      \"adverse event\":~a,
      \"reference\":~a,
      \"molecule(s)\":[~{{\"name\":\"~a\",\"state\":\"~a\"}~^,\"~}],
      \"model\":~a,
      \"cases\":~a,
      \"drug(s)\":~a
      }
      "
     (rsget :dx)
     (rsget :relation)
     (rsget :ae)
     (rsget :citation)
     (flatten (find :aberration))
     (jsonize (find-setting-model (find :setting)))
     (case (find-setting-model (find :setting))
      (:case_study (print-patient-info semantics)) ;; still in progress FFF !!!
      (:in_vitro (or (tree-extract-number (assoc :setting semantics)) (jsonize "undefined")))
      (:rct (or (tree-extract-number (assoc :setting semantics)) (jsonize "undefined")))
      (:trial (or (tree-extract-number (assoc :setting semantics)) (jsonize "undefined")))
      (:experiment (or (tree-extract-number (assoc :setting semantics)) (jsonize "undefined")))
      (otherwise (jsonize "undefined")))

     (jsonize (find :tx)))))


(defparameter *models* '(:rct :in_vitro :experiment :case_study :trial))

(defun find-setting-model (result)
  ;; Drops most of the info on the floor, unfortunately.
  (cond ((and (keywordp result)
          (member result *models* :test #'string-equal))
         result)
   ((atom result) nil)
   (t (or (find-setting-model (car result))
          (find-setting-model (cdr result))))))

(defun print-patient-info (result)
  (if (>= (length (find-patient-info result)) 2)
      (format nil "[~{{\"age\":~a,\"gender\":\"~a\"}~^,\"~}]" (find-patient-info result))
    (format nil "\"undefined\"")))

(defun find-patient-info (result)
  (flatten (list (second (flatten (assoc :age result)))
            (loop for item in (flatten result)
                    when (and (stringp item) (search "PTWORD." item) (= 0 (search "PTWORD." item)))
                    collect (get-patient-gender (subseq item 7))))))

(defun make-keyword (name) (values (intern name "KEYWORD")))

(defun get-patient-gender (word)
  (case (make-keyword (string-upcase word))
    (:woman "FEMALE")
    (:girl "FEMALE")
    (:man "MALE")
    (:boy "MALE")))

;;; Importer for Insights from CaseBook

(defvar *trexrecs* nil)

(defun import-trex-recs ()
  (length
   (or *trexrecs*
       (setq *trexrecs*
        (with-open-file
          (i "insights.json")
          (loop for rec = (ignore-errors (cl-json::decode-json-from-source i))
           until (null rec)
           collect rec))))))

(defun trex-molecules ()
  (import-trex-recs)
  (mapcar #'molecule-to-symbol
    (remdups
     (loop for rec in *trexrecs*
      collect (cdr (assoc :name (cdr (assoc :molecule rec))))))))

(defun trex-drugs ()
  (import-trex-recs)
  (mapcar #'molecule-to-symbol
    (remdups
     (loop for rec in *trexrecs*
      collect (cdr (assoc :drug rec))))))

(defun molecule-to-symbol (m)
  (intern (substitute #\& #\, (substitute #\- #\space (string-upcase m)))))

(defparameter *junk-chars* "()-. ,;:!	[]%{}/+\\

")

(defun trim-word (w) (string-trim *junk-chars* w))

(defvar *citation* nil) ;; localize

;;; Citations are anything in parens. I assume for the moment that
;;; there's just one, and do NO ERROR CHECKING! This returns the
;;; string cleaned of the citation.

(defun strip-and-save-citation (s)
  (setq *citation* nil)
  (let* ((open (position #\( s))
         (close (position #\) s)))
    (when (and open close)
      (setq *citation* (subseq s (1+ open) close)
       s (format nil "~a~a" (subseq s 0 open) (subseq s (1+ close)))))
    s))

(defun start-parse-server ()
  (setq *pprint+?* nil)
  (init-grammar)
  (test-parser)
  (hunchentoot:define-easy-handler
   (cnlparser :uri "/cnlparser")
   (s)
   (setf (hunchentoot:content-type*) "text/plain")
   (drive-parser s))

  (hunchentoot:start (make-instance 'hunchentoot:easy-acceptor :port 4242))
  (loop do (sleep 100)))


(defun drive-parser (s)
  ;; Returns with JSON or nil if there are no valid parses.
  (let ((s (mapcar #'(lambda (w) (if (numberp w) w (intern (trim-word (string-upcase w)))))
            (string-split (strip-and-save-citation s) :convert-num-values? t))))
    (setq s (remove '|| s))
    ;;(mapcar #'print s)
    (preprocess-numbers s)
    (let* ((parses (pprint+ (parser s)))
           (raw-semantics (pprint+ (remove nil (extract-semantics parses)) :label "raw-semantics"))
           (final-semantics (pprint+ (post-process-semantics raw-semantics) :label "final-semantics")))

      (when parses
       (with-output-to-string
          (s) (emit-trex-json `(,@final-semantics (:citation ,*citation*)) s))))))

(defun extract-semantics (tree)
  (cond ((null tree) (list nil))
   ((atom tree) nil)
   ((listp tree)
    (cond ((keywordp (car tree)) (list tree))
          (t (append (extract-semantics (car tree))
              (extract-semantics (cdr tree))))))
   (t (error "EXTRACT-SEMANTICS doesn't understand: ~s" tree))))

;;; Collect common elements and compress subsumptions.

(defun post-process-semantics (r)
  (loop for key in (remdups (mapcar #'car r))
   collect (list key
            (key-specific-post-processing
               key (reduce-subsumptions
                    (loop for (key2 . rest) in r when (eq key key2) collect (flatten rest)))))))

(defun key-specific-post-processing (key result)
  (case key
   (:relation (post-process-relation (flatten result)))
   (:aberration (post-process-aberrations result))
   (:tx (flatten (post-process-tx result)))
   (:dx (car result))
   (:aetx (flatten (post-process-aetx result)))
   (t result)))

(defparameter *aberrations*
  '(:OVER_EXPRESSION :UNDER_EXPRESSION :EXPRESSION :SUPPRESSION "MUTYPEWORD.DELETION" "MUTYPEWORD.EXPRESSION"
         "MUTYPEWORD.DUPLICATION" "MUTYPEWORD.INSERTION" "MUTYPEWORD.AMPLIFICATION"
         "MUTYPEWORD.UN-METHYLATED" "MUTYPEWORD.METHYLATION"))

(defun post-process-aberrations (semantics)
  (loop for item in semantics
   when (member (second item) *aberrations* :test #'equal)
   collect item
   when (member (first item) *aberrations* :test #'equal)
   collect (reverse item)))

(defun post-process-relation (semantics)
  (cond ((member :resistance_to semantics) :resistance_to)
   ((member :no_sensitivity semantics) :no_sensitivity)
   ((member :sensitivity_to semantics) :sensitivity_to)
   ((member :off_label semantics) :off_label)
   (t (get-confer-word semantics))))

(defun get-confer-word (semantics)
  (loop for item in semantics
   when (and (stringp item) (search "CONFERS." item) (= 0 (search "CONFERS." item)))
   collect (subseq item 8)))

(defun post-process-tx (semantics)
  (loop for item in (flatten semantics)
   when (and (stringp item) (search "TX." item) (= 0 (search "TX." item)))
   collect (subseq item 3)))

(defun post-process-aetx (semantics)
  (loop for item in (flatten semantics)
   when (and (stringp item) (search "AETX." item) (= 0 (search "AETX." item)))
   collect (subseq item 5)))

(defun reduce-subsumptions (l)
  (remdups ;; The below leaves some exactly equal sets.
   (loop for elt1 in l
   ;; Collect this elt unless...
    unless (loop for elt2 in l ;; ...there's any other elt (including ME!) ...
            when (and (set-difference elt2 elt1 :test #'equal) ;; ... that's larger than the target ... and ...
                  (null (set-difference elt1 elt2 :test #'equal))) ;; ... the target is a perfect subset.

            do (return t))
    collect elt1)))

(defun remdups (l &key (test #'equal))
  (loop for e+ on l
   unless (member (car e+) (cdr e+) :test test)
   collect (car e+)))

(defun string-split (string &key (delimiter #\space) (convert-num-values? nil))
  "Split string into substrings delimited by delimiter"
  (let ((substrings '())
        (length (length string))
        (last 0))
    (flet ((add-substring
            (i)
            (push (subseq string last i)
             substrings)))
     (dotimes (i length)
        (when (eq (char string i) delimiter)
           (add-substring i)
           (setq last (1+ i))))
     (add-substring length)
     (let ((substrings (nreverse substrings)))
        (if convert-num-values?
         (loop for string in substrings
                 as v = (ignore-errors (read-from-string string))
                 if (numberp v)
                 collect v
                 else
                 collect string)
         substrings)))))

;;; Testing
(defun test-maker (location)
  (with-open-file (input location)
    (let* ((tests (json:decode-json input)))
         (return-from test-maker (rest (assoc :tests tests))))))

(defun test-parser ()
  (init-grammar)
  (load-parser-tests)
  (loop for (input output) in *tests*
   with fails = 0
   as result = (drive-parser input)
   do (if result
           (let ((compare (ugly-string-equal output result)))
            (if compare
                  (format t "~%~%*** PASSED ***~%~%Input:~%~s~%Result:~%~s~%~%----------------~%" input result)
                  (progn
                      (format t "~%~%!!! TEST FAILED !!!~%~%Input:~%~s~%Expected output:~%~s~%Actual Result:~%~s~%~%----------------~%"
                          input output result)
                      (incf fails)))))
   finally (if (> fails 0)
            (format t "*************************************************************************************
***** SOME TESTS FAILED! Of the ~a sentences tested, ~a filed (i.e., ~a% passed) *****
*************************************************************************************"
                (length *tests*) fails (* 100.0 (- 1 (/ fails (length *tests*)))))
            (format t "ALL TEST PASSED!"))))

(defun load-parser-tests ()
  (format t "Loading parser tests...")
  (setf *tests* (with-open-file (i "tests.lisp") (loop for test = (read i nil nil) until (null test) collect test)))
  ;; The test can be more than one sentence that's supposed to parse
  ;; identical semantics. These get unwound here into separate tests
  ;; (which isn't the optimal way to do this, but it'll do for the
  ;; moment.) FFF
  (loop for test in *tests*
   as (inputs output) = test
   when (listp inputs)
  ;; This is ultra ugly -- it adds tests for all but the first,
  ;; and then smashes the inputs to the last one UUU
   do (loop for input in (cdr inputs)
       do (push (list input output) *tests*))
   (setf (car test) (car inputs)))
  (format t "~a tests loaded.~%" (length *tests*)))


(defun recreate-testnlp.html ()
  (format t "Recreating testnlp.html~%")
  (load-parser-tests)
  (with-open-file
   (o "testnlp.html" :direction :output :if-exists :supersede)
   (loop for (s nil) in *tests*
    do
    (format o "
<form action=\"http://platformtest.cancercommons.org:4242/cnlparser\" id=\"myform\">
  Text:<br>
  <textarea rows=3 cols=120 name=\"s\">~a</textarea><br>
  <input type=\"submit\" value=\"Parse\">
</form>
" s))))

;;; When you are satisfied that a new sentence gives acceptable
;;; semantics, use this to commit the test to the test set.

(defun commit-new-test (s &key (force? nil))
  (print s)
  (let ((parse (drive-parser s)))
    (if parse
     (progn
        (or force? (format t "~%Confirm that this is the correct output for your sentence:~%~a" parse))
        (if (or force? (y-or-n-p "Confirmed! Commit it:"))
            (progn
             (with-open-file
                (o "tests.lisp" :direction :output :if-exists :append :if-does-not-exist :create)
                (format o "~%(~s~%~s)~%" s parse)
                (recreate-testnlp.html))

             (format t "Done! *** REMEMBER TO COMMIT AND PUT THE TEST FILE (test.lisp) TO THE REPO ***"))
           (format t "Aborted!")))
     (format t "Parse failed, not added to tests.lisp~%"))))


(defun recompute-all-tests ()
  (format t "Copying tests.lisp to temporary timestamped file.~%")
  (init-grammar)
  (load-parser-tests)
  (ignore-errors (copy-file "tests.lisp" (print (format nil "tests.lisp.~a" (get-universal-time))))
     (delete-file "tests.lisp"))
  (loop for (input nil) in *tests*
   do (print input)
   (commit-new-test input :force? t))
  (test-parser))

;; This version of string-equal ignores white space and non-printing
;; characters, as well as case folding. It's slightly inefficient b/c
;; it copies both strings, but as this is only used in the testing. It
;; also tells you where the problem starts, if it fails.

(defun ugly-string-equal (a b)
  (let* ((ca (copy-ascii-only-string a))
         (cb (copy-ascii-only-string b)))
    (or (string-equal ca cb)
     (format t "~%****** UGLY-STRING-EQUAL failed:~%")
     (let ((p (loop for p below (min (length ca) (length cb))
               unless (char-equal (aref ca p) (aref cb p))
               do (return p))))
        (format t "  ~s|...~%  ...~s~%  ...~s~%~%" (subseq ca 0 p) (subseq ca p) (subseq cb p))))))

(defparameter *allowed-chars*
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ:\",{}[]0123456789-\'/*+=%$#@!)(&^><;|._")

(defun copy-ascii-only-string (s)
  (loop for c across s
   with r = ""
   when (position c *allowed-chars* :test #'char-equal)
   do (setf r (format nil "~a~c" r c))
   finally (return r)))

;;; ===========================================================
;;; Main:

;(test-parser)
(start-parse-server)
