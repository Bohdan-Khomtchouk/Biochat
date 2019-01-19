<div align="center">
<img src="https://user-images.githubusercontent.com/9893806/38167027-35f89d3c-34e3-11e8-9c84-18a2c3ea20f0.png">
</div>

## Screenshot

<img width="839" alt="screen shot 2018-03-04 at 10 33 54 pm" src="https://user-images.githubusercontent.com/9893806/36960584-7b34f7f2-1ffc-11e8-9b9f-e17aea59c11e.png">


## Installation (for developers only)

Additionally to having Quicklisp you'll need to clone [crawlik](https://github.com/vseloved/crawlik) into the home directory.

To use PubMed word vectors, `(pushnew :use-pubmed *features*)` before loading the system `biochat`.

## NLP in action (command-line example for developers)

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

The data is obtained by web scraping using the project [crawlik](https://github.com/vseloved/crawlik), which should be cloned from Github prior to loading `Biochat`. The crawled data from GEO is stored as text files in <a href="https://github.com/Bohdan-Khomtchouk/Biochat/tree/master/data/GEO/GEO_records">data/GEO/GEO_records</a> directory & in memory in the variable `*geo-db*`. Here's an example record:

```
TITLE
Na,K-ATPase alpha 1 isoform reduced expression effect on hearts

SUMMARY
Expression profiling of hearts from 8 to 16 week old adult males lacking one copy of the Na,K-ATPase alpha 1 isoform.  Na,K-ATPase alpha 1 isoform expression is reduced by half in heterozygous null mutants.  Results provide insight into the role of the Na,K-ATPase alpha 1 isoform in the heart.

ORGANISM
Mus musculus
```

The purpose of this tool is to find related/similar records using different approaches. This is implemented in the generic function `geo-group` that processes the GEO database into a number of groups of related records. It has a number of methods:

1. Match based on the same histone (the list of known histones is read from a <a href="https://github.com/Bohdan-Khomtchouk/Biochat/blob/master/data/GEO/histones.txt">text file</a>).
2. Match based on the same organism.
3. Synonym based on the synonyms obtained from the biological [PubData](https://github.com/Bohdan-Khomtchouk/PubData) wordnet database (read from a <a href="https://github.com/Bohdan-Khomtchouk/Biochat/blob/master/data/GEO/pubdata-wordnet.json">JSON file</a>).
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
- `tree-closest-recs` finds the closest records based on the pre-calculated hierarchical clustering (performed with the UPGMA algorithm using the cosine similarity measure). The results of clustering are stored in the <a href="https://github.com/Bohdan-Khomtchouk/Biochat/blob/master/data/GEO/GEO-tree-cos.lisp">text file</a>.

## Contact

You are welcome to:

* submit suggestions and bug-reports at: <https://github.com/Bohdan-Khomtchouk/Biochat/issues>
* send a pull request on: <https://github.com/Bohdan-Khomtchouk/Biochat>
* compose an e-mail to: <bohdan@stanford.edu>

## Code of conduct

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.

## Acknowledgements

This software is thanks to the amazing work done by MANY people in the open source community of biological databases (GEO, PubMed, etc.).  Some of the computing for this project was performed on the [Sherlock cluster](https://www.sherlock.stanford.edu). We would like to thank Stanford University and the Stanford Research Computing Center for providing computational resources and support that contributed to these research results.

## Citation
https://doi.org/10.1101/480020
