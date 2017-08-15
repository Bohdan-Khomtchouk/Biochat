# Biochat 2 - matching bioinformatics dataset for fun and profit

## How it works

The project aims at providing an interactive workbench for matching records from medical/bio databases (like [GEO](https://www.ncbi.nlm.nih.gov)).

The data is obtained by web scraping using the project [crawlik](https://github.com/vseloved/crawlik), which should be cloned from github prior to loading Biochat. The crawled data from GEO is stored as text files in [data/geo/](data/geo/) directory & in memory in the variable `*geo-db*`. Here's an example record:

```
TITLE
Na,K-ATPase alpha 1 isoform reduced expression effect on hearts

SUMMARY
Expression profiling of hearts from 8 to 16 week old adult males lacking one copy of the Na,K-ATPase alpha 1 isoform.  Na,K-ATPase alpha 1 isoform expression is reduced by half in heterozygous null mutants.  Results provide insight into the role of the Na,K-ATPase alpha 1 isoform in the heart.

ORGANISM
Mus musculus
```

The purpose of this tool is to find related/similar records using different approaches. This is implemented in the generic function `geo-group` that processes the DB into a number of groups of related records. It has a number of methods:

1. Match based on the same histone (the list of known histones is read from [a text file](data/histones.txt).
2. Match based on the same organism.
3. Synonym based on the synonyms obtained from the biological Pubdata Wordnet databsed (read from a [JSON file](data/pubdata-wordnet.json)).
4. Other possible simple match methods may be implemented.

Another approach to matching is via vector space representations. Each record is transformed into a vector using the pre-calculated vectors for each word in its description (either all fields, or just summary, or summary + title). The vectors used are [Pubmed vectors](https://drive.google.com/open?id=0BzMCqpcgEJgiUWs0ZnU0NlFTam8).

The combination of individual word vectors may be performed in several ways.
The most straightforward approach (implemented in the library) is direct aggregation,
in which a document vector is a normalized sum of vectors for its words.
Additional weighting may be applied to words from different parts of the document
(summary, title, ...). Another possible aggregation approach is to use [doc2vec](https://cs.stanford.edu/~quocle/paragraph_vector.pdf) PV-DM algorithm. The function `text-vec` produces an aggregated document vector from individual PubMed vectors.

The obtained document vectors may be matched using various similarity measures.
The most common are cosine similarity (`cos-sim`) and
Euclidian distance-based similarity (`euc-sim`). Unlike `geo-group`, vector-space modeling results in a continuous space, in which it is unclear how to separate individual groups of related vectors. That's why an alternative approach is taken: arrange record vectors in terms of proximity to a given record. This is done with the functions:

- `vec-closest-recs` that sorts the aggregated document vectors directly with the similarity measure (`cos-sim`, `euc-sim`, etc.)
- `tree-closest-recs` finds the closest records based on the pre-calculated hierarchical clustering (performed with the UPGMA algorithm using the cosine similarity measure). The results of clustering are stored in the [text file](data/geo-tree-cos.lisp)

Here is an example run of theses functions with the record #10 from GEO db:

```
#S(GEO-REC
   :ID 10
   :TITLE "Type 1 diabetes gene expression profiling"
   :SUMMARY "Examination of spleen and thymus of type 1 diabetes nonobese diabetic (NOD) mouse, four NOD-derived diabetes-resistant congenic strains and two nondiabetic control strains."
   :ORGANISM "Mus musculus")
```

```
B42> (subseq (vec-closest-recs (? *geo-db* 0)) 0 3)
(#S(GEO-REC
     :ID 5167
     :TITLE "Type 2 diabetic obese patients: visceral adipose tissue CD14+ cells"
     :SUMMARY "Analysis of visceral adipose tissue CD14+ cells isolated from obese, type 2 diabetic patients. Obesity is marked by changes in the immune cell composition of adipose tissue. Results provide insight into the molecular basis of proinflammatory cytokine production in obesity-linked type 2 diabetes."
     :ORGANISM "Homo sapiens")
  #S(GEO-REC
     :ID 4191
     :TITLE "NZM2410-derived lupus susceptibility locus Sle2c1: peritoneal cavity B cells"
     :SUMMARY "Analysis of peritoneal cavity B cells (B1a) and splenic B (sB) cells from B6.Sle2c1 mice. Sle2 induces expansion of the B1a cell compartment, a B cell defect consistently associated with lupus. Results provide insight into molecular mechanisms underlying susceptibility to lupus in the NZM2410 model."
     :ORGANISM "Mus musculus")
  #S(GEO-REC
     :ID 437
     :TITLE "Heart transplants"
     :SUMMARY "Examination of immunologic tolerance induction achieved in cardiac allografts from BALB/c to C57BL/6 mice by daily intraperitoneal injection of anti-CD80 and anti-CD86 monoclonal antibodies (mAbs)."
     :ORGANISM "Mus musculus"))
     
B42> (subseq (tree-closest-recs (? *geo-db* 0)) 0 3)
(#S(GEO-REC
    :ID 471
    :TITLE "Malaria resistance"
    :SUMMARY "Examination of molecular basis of malaria resistance. Spleens from malaria resistant recombinant congenic strains AcB55 and AcB61 compared with malaria susceptible A/J mice."
    :ORGANISM "Mus musculus")
 #S(GEO-REC
    :ID 4258
    :TITLE "THP-1 macrophage-like cells response to W-Beijing Mycobacterium tuberculosis strains: time course"
    :SUMMARY "Temporal analysis of macrophage-like THP-1 cell line infected by Mycobacterium tuberculosis (Mtb) W-Beijing strains and H37Rv. Mtb W-Beijing sublineages are highly virulent, prevalent and genetically diverse. Results provide insight into host macrophage immune response to Mtb W-Beijing strains."
    :ORGANISM "Homo sapiens")
 #S(GEO-REC
    :ID 4966
    :TITLE "Active tuberculosis: peripheral blood mononuclear cells"
    :SUMMARY "Analysis of PBMCs isolated from patients with active pulmonary tuberculosis (PTB) and latent TB infection (LTBI). Results provide insight into identifying potential biomarkers that can distinguish individuals with PTB from LTBI."
    :ORGANISM "Homo sapiens"))
```

## Project conception history

The project's initial concept is by [Bohdan Khomtchouk](http://bohdankhomtchouk.com):

> a 24/7 artificial intelligence system that's using NLP techniques to pair, organize, and group together different biological datasets, such that you could query based on a set of keywords (e.g., "cancer", "leukemia", "mouse"), and it would return to you datasets that are most like each other and most deserving of being considered integratively (i.e., analyzing both or three together could unlock an interesting medical result that could not otherwise be found by analyzing just one dataset alone)

The plan for the first version is:

* [x] Scrape [GEO](https://www.ncbi.nlm.nih.gov/geo/), then extract the title, summary, etc. from each entry (entry example: <https://www.ncbi.nlm.nih.gov/sites/GDSbrowser?acc=GDS4303>)
* [x] Store all this structured metadata in a database (currently, in-memory representation is sufficient)
* [x] Teach an algorithm to match similar groups (e.g., if organism is "Mus musculus", i.e. mouse) then group them together (which is easy), but also be able to spot "leukemia" as a cancer type, so group it together with other cancer types

Stages of the development of matching algorithm:

* [x] Direct matching on a per-word or per-phase basis
* [x] Similarity matching using vector space modeling with word vectors from <https://github.com/cambridgeltl/BioNLP-2016> and the [doc2vec approach](https://cs.stanford.edu/~quocle/paragraph_vector.pdf)


## Installation

Additionally to having Quicklisp you'll need to clone [crawlik](https://github.com/vseloved/crawlik) to `~/common-lisp/`.

To use PubMed word vectors, `(pushnew :use-pubmed *features*)` before loading the system `biochat2`.
