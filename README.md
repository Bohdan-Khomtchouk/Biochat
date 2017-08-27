<div align="center">
<img src="https://user-images.githubusercontent.com/9893806/29490594-f18fa890-84f5-11e7-9fd4-d9e366b1dc64.gif">
</div>

# Biochat

## Introduction

### The Problem:

Currently, there exist thousands of biological databases containing terabytes of publicly available data.  So much data scattered in so many locations impedes unified and comprehensive data-driven approaches to biological discovery.

### The Solution:

Create an artificial intelligence daemon that is constantly unifying and organizing the world's biological information by intelligently integrating it into self-similar data modules grouped by biological themes and subthemes (e.g., theme: brain cancer; subthemes: glioblastoma (GBM), astrocytoma, medulloblastoma, ... ; sub-subthemes: primary GBM, pineal astrocytic tumor, brain stem glioma, ...).

### Significance:

The biological data-verse is expanding every day, with new experimental data published daily.  Biology is done in many different model organisms (e.g., human, mouse, rat, etc.), with many different next-generation sequencing types (e.g, ChIP-seq, RNA-seq, etc.), in many different cell lines (e.g., K562, NHEK, etc.), focusing on many different transcription factors, epigenetic modifications, etc.  Multidimensionally integrating all this information is essential to data-driven discovery (e.g., [cancer cures could already exist in big data](https://www.fastcompany.com/3063530/cancer-cures-could-already-exist-in-big-data)).   Specifically, pairing ostensibly unrelated datasets (e.g., from different organisms, NGS types, age groups, cell lines, etc.) can inform and contribute deeper understanding of a variety of biological questions ranging from cancer to aging.  

## Software

`Biochat` aims at providing an interactive workbench for biological databases (e.g., [Gene Expression Omnibus (GEO)](https://www.ncbi.nlm.nih.gov), [miRBase](http://www.mirbase.org/), [TCGA](https://cancergenome.nih.gov/), [Human Epigenome Atlas](https://www.genboree.org/epigenomeatlas/index.rhtml), etc.) to learn to communicate with each other by matching and pairing similar data records across the biological data-verse.  `Biochat`'s mission is to fundamentally transform how people perform biological data science by unifying it, going from thousands of scattered database silos (that act as storage repositories) to 1 intelligent centralized framework (that acts as an AI to integrate large-scale data), thereby opening doors to more biological breakthroughs based on existing data.  `Biochat` is written in Common Lisp and operates based on efficient categorization and pairing of similar items (e.g., words that describe ostensibly unrelated data records) into groups.  It is basically the high performance computing (HPC) data science equivalent of the chemistry saying "like dissolves like."  

## Concrete example

Here is a sample run from `Biochat` using record #10 as input from the Gene Expression Omnibus (GEO) database:

```
#S(GEO-REC
   :ID 10
   :TITLE "Type 1 diabetes gene expression profiling"
   :SUMMARY "Examination of spleen and thymus of type 1 diabetes nonobese diabetic (NOD) mouse, four NOD-derived diabetes-resistant congenic strains and two nondiabetic control strains."
   :ORGANISM "Mus musculus")
```

Here is the output using two separate approaches (`vec-closest-recs` and `tree-closest-recs`, both discussed in the section [How it works](https://github.com/Bohdan-Khomtchouk/Biochat#how-it-works)):

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

Record #10 ("Type 1 diabetes gene expression profiling") is a mouse diabetes record from spleen and thymus, which are organs where immunological tolerance is frequently studied.  Even though no explicit mention of "immunological tolerance" is made in record #10, `Biochat` correctly pairs it with record #437 (where "immunological tolerance" is explicitly stated in the Summary).  Likewise, record #10 is nicely paired with record #5167 ("Type 2 diabetic obese patients: visceral adipose tissue CD14+ cells"), which is from a different model organism (human) but involves an immunological study (CD14+ cells) from diabetic patient samples.

## How it works

The data is obtained by web scraping using the project [crawlik](https://github.com/vseloved/crawlik), which should be cloned from Github prior to loading `Biochat`. The crawled data from GEO is stored as text files in [data/geo/](data/geo/) directory & in memory in the variable `*geo-db*`. Here's an example record:

```
TITLE
Na,K-ATPase alpha 1 isoform reduced expression effect on hearts

SUMMARY
Expression profiling of hearts from 8 to 16 week old adult males lacking one copy of the Na,K-ATPase alpha 1 isoform.  Na,K-ATPase alpha 1 isoform expression is reduced by half in heterozygous null mutants.  Results provide insight into the role of the Na,K-ATPase alpha 1 isoform in the heart.

ORGANISM
Mus musculus
```

The purpose of this tool is to find related/similar records using different approaches. This is implemented in the generic function `geo-group` that processes the database into a number of groups of related records. It has a number of methods:

1. Match based on the same histone (the list of known histones is read from [a text file](data/histones.txt)).
2. Match based on the same organism.
3. Synonym based on the synonyms obtained from the biological [PubData](https://github.com/Bohdan-Khomtchouk/PubData) Wordnet database (read from a [JSON file](data/pubdata-wordnet.json)).
4. Other possible simple match methods may be implemented.

Another approach to matching is via vector space representations. Each record is transformed into a vector using the pre-calculated vectors for each word in its description (either all fields, or just summary, or summary + title). The vectors used are [PubMed vectors](https://drive.google.com/open?id=0BzMCqpcgEJgiUWs0ZnU0NlFTam8).

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

## Like dissolves like

We apply the "like dissolves like" principle to teach data files to learn to talk to each other (quite literally).  In order to talk, data must first be able to find each other in space (not a trivial task, considering that there are thousands of bioinformatics databases out there... see how we've tackled this problem with <a href="https://github.com/Bohdan-Khomtchouk/PubData">PubData</a>).  So how, for example, is an RNA-seq dataset supposed to find its potentially related ChIP-seq dataset (e.g., according to some combination of similar cell type, histone mark, sequencing details, etc.)?  Through metadata, of course!  However, for the datasets to meet each other via a similar metadata footprint requires sophisticated NLP strategies to introduce them.  Once the datasets meet, we can let the conversations (i.e., integrative bioinformatics analyses) begin!  Hence the name: `Biochat`.

## Motivation

Our ultimate goal is to make integrative multi-omics a lot easier (and more fun) through artificial intelligence (AI).  Right now, we are barely scratching the surface with NLP.  Thus, we are currently implementing novel neural network approaches to help us teach data to talk to each other (stay tuned!).  


## Algorithms<sup>1</sup>

`Biochat` uses the following formula for calculating the similarity between any two distinct entities:

![image](https://cloud.githubusercontent.com/assets/5694520/21303565/5e4c1c5c-c5d4-11e6-95fe-3e434c1a3b21.png)

![image](https://cloud.githubusercontent.com/assets/5694520/21303577/79b0bd5e-c5d4-11e6-84dd-0b8343ee70b0.png)


Where affinity is defined as follows:

![image](https://cloud.githubusercontent.com/assets/5694520/21303883/c74fe9a2-c5d6-11e6-8634-d2e212ff5b32.png)

![image](https://cloud.githubusercontent.com/assets/5694520/21303889/d435c68c-c5d6-11e6-8334-8d88e20529d4.png)

These algorithms have been successfully implemented in the [Python branch](https://github.com/Bohdan-Khomtchouk/Biochat/tree/master) of `Biochat`.  We are currently re-pivoting our platform into a deep learning architecture (stay tuned!).

## Checklist

So far, here is what has been completed in `Biochat`:

* [x] Scrape [GEO](https://www.ncbi.nlm.nih.gov/geo/), then extract the title, summary, etc. from each entry (entry example: <https://www.ncbi.nlm.nih.gov/sites/GDSbrowser?acc=GDS4303>)
* [x] Store all this structured metadata in a database (currently, in-memory representation is sufficient)
* [x] Teach an algorithm to match similar groups (e.g., if organism is "Mus musculus", i.e. mouse) then group them together (which is easy), but also be able to spot "leukemia" as a cancer type, so group it together with other cancer types

Stages of the development of matching algorithm:

* [x] Direct matching on a per-word or per-phrase basis
* [x] Similarity matching using vector space modeling with word vectors from <https://github.com/cambridgeltl/BioNLP-2016> and the [doc2vec approach](https://cs.stanford.edu/~quocle/paragraph_vector.pdf)


## Installation

Additionally to having Quicklisp you'll need to clone [crawlik](https://github.com/vseloved/crawlik) into the home directory.

To use PubMed word vectors, `(pushnew :use-pubmed *features*)` before loading the system `biochat`.

## Contact

You are welcome to:

* submit suggestions and bug-reports at: <https://github.com/Bohdan-Khomtchouk/Biochat/issues>
* send a pull request on: <https://github.com/Bohdan-Khomtchouk/Biochat>
* compose an e-mail to: <bohdan@stanford.edu>

## Code of conduct

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.

## Acknowledgements

This software is thanks to the amazing work done by MANY people in the open source community of biological databases (GEO, PubMed, etc.)

The work on `Biochat` was done by [Bohdan B. Khomtchouk, Ph.D.](https://about.me/bohdankhomtchouk) and [Vsevolod Dyomkin](https://vseloved.github.io/).

## Contributors
* Vsevolod Dyomkin
* You?

## Citation
Coming soon!

-------------
<sub>
1. Yael Karov and Shimon Edelman. 1998. Similarity-based word sense disambiguation.
*Computational Linguistics, 24(1):41-59.*
</sub>
