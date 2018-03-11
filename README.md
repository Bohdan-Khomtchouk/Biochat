<div align="center">
<img src="https://user-images.githubusercontent.com/9893806/29490594-f18fa890-84f5-11e7-9fd4-d9e366b1dc64.gif">
</div>

# Biochat

## Introduction

### The Problem:

Currently, there exist thousands of biological databases (e.g., [Gene Expression Omnibus (GEO)](https://www.ncbi.nlm.nih.gov/geo/), [miRBase](http://www.mirbase.org/), [TCGA](https://cancergenome.nih.gov/), [Human Epigenome Atlas](https://www.genboree.org/epigenomeatlas/index.rhtml), etc.) containing terabytes of publicly available data.  So much data scattered in so many locations impedes unified and comprehensive data-driven approaches to biological discovery.

### The Solution:

Forget databases.  If you want to efficiently integrate next-generation sequencing (NGS) and microarray datasets across diverse heterogeneous sources, then pull down their respective metadata and decentralize it via a blockchain.  Then, use natural language processing (NLP) algorithms to categorize the metadata into self-similar and closely related modules.  Then, track user behavior in interacting with these modules via mouse clicks that record the user's IP address, timestamp, input query, output clicked on, and NLP settings directly onto the blockchain.  Basically, refine the machine-generated modules with human touch.  Then, use literature co-citation information to further refine the accuracy of this NLP+clicks system, assuming that papers that cite one another presumably contain biological data that is related by some common theme or subject.  Wrap this 3-layer system (NLP/clicks/citations) into a neural network while treating the user clicks as a collective intelligence-driven Bayesian framework that naturally evolves over time as `Biochat` grows its robust and diverse userbase, where each user brings their unique set of skills and expertise in biology to the framework on a daily basis.

## Screenshot

<img width="839" alt="screen shot 2018-03-04 at 10 33 54 pm" src="https://user-images.githubusercontent.com/9893806/36960584-7b34f7f2-1ffc-11e8-9b9f-e17aea59c11e.png">

If you're really interested in one of those outputs (e.g., because it looks so relevant to your input), you're likely to click the PMID (i.e., PubMed ID) to navigate to the respective publication to learn more information about the respective study that generated the data.  In doing so, your click is registered as a new block on the blockchain -- where each block contains the user's IP address, timestamp, input query, output clicked on, and NLP settings -- as described in the section above.  In this framework, user interactions are treated like as if they are cryptocurrency payment transactions, whose provenance can be traced back and monitored in real-time.  

Similarly to the concept behind the Proof-of-Work (PoW) algorithm, the ranking of output results will only be affected system-wide once consensus is reached amongst a sufficiently diverse set of users.  This is similar to the concept of cryptocurrency miners competing against each other to complete transactions on the network and getting rewarded for it with Bitcoin.  As such, for any given input, users are motivated/incentivized to click on PMID outputs that will match the double-blind activity of other geographical users.  Instead of being offered a coin as a reward for these "mining" efforts, users are rewarded with a re-ordered set of output results that more accurately reflect current community consensus via the collective intelligence that was captured during this process.  Therefore, `Biochat` is driven by altruism not greed, since it would technically be possible to call up your (X number) of buddies throughout the world and have everybody click on the same output for some identical input search string.  Although such a comical scenario cannot be ruled out when the extrinsic motivator is purely financial (e.g., mining a new altcoin), it can certainly be ruled out when the intrinsic motivator is altruistic in nature -- benefiting biological data science through your unique set of skills, knowledge, and expertise in a given area(s) of inquiry.  Since the biological research community is extremely diverse (e.g., a fly geneticist is likely to have a very different set of expertise/knowledge than an infectious disease immunologist or a bacteriologist), this leads to the following testable hypothesis:             

## Hypothesis

Collective intelligence (as quantified by observing and learning from multiple users' behavior/interactions with metadata recorded on the blockchain), in combination with training sources such as literature citations and natural language processing techniques, is better and more effective in finding natural groupings and emergent structure within large volumes of biological data compared to arbitrarily assigning data files to a database(s) in an ad-hoc manner.  

## Software name, history, and call for feedback/suggestions

`Biochat` is about teaching biological datasets to learn to talk to each other, i.e., to learn to communicate with each other by matching and pairing similar data records across the biological data-verse using human-trained AI (via clicks and citations).  It was inspired by the field called the [Internet of Things (IoT)](https://www.upwork.com/hiring/for-clients/mobile-apps-impact-internet-things/), where hardware devices can communicate via a wireless network (e.g., you can send a message from your phone to your coffee machine to make you an espresso).  By abstracting the concept of "things" from hardware devices to software devices, you begin to deal with a kind of "Internet of Data" and, since biological data science is very domain-specific in its terminology, we began to refer to it locally as the "Internet of Omics".  However, given that we were coining a new term in the lab, we thought it would be more appropriate to just go with a simpler title for the URL, like "Biochat", but quickly realized that the domain name biochat.com was already taken and in-use by a completely unrelated business that then put up its domain name for sale at $50,000 and is currently squatting on it.  Thus, we just ended up purchasing biochats.io (adding an "s" to "biochat", since biochat.io is also being squatted on) as a temporary workaround.  

All being said, we are very flexible on the software name and would welcome suggestions.  Some contenders we have heard so far include `blockblockbio`, `metablox`, and even the fun-sounding `biojibberjabber`.  We would also welcome community suggestions on an appropriate software logo.  Note: the animated GIF above is not a logo.  Feel free to open up a Github issue to comment on either or any of these topics.    

## Software significance

The biological data-verse is expanding every day, with new experimental data published daily.  Biology is done in many different model organisms (e.g., human, mouse, rat, etc.), with many different next-generation sequencing types (e.g, ChIP-seq, RNA-seq, etc.), in many different cell lines (e.g., K562, NHEK, etc.), focusing on many different transcription factors, epigenetic modifications, etc.  Multidimensionally integrating all this information is essential to data-driven discovery (e.g., [cancer cures could already exist in big data](https://www.fastcompany.com/3063530/cancer-cures-could-already-exist-in-big-data)).   Specifically, pairing ostensibly unrelated datasets (e.g., from different organisms, NGS types, age groups, cell lines, etc.) can inform and contribute deeper understanding of a variety of biological questions ranging from cancer to aging.  `Biochat`'s mission is to fundamentally transform how people perform biological data science by unifying it, going from thousands of scattered database silos (that act as storage repositories) to 1 intelligent decentralized framework (that acts as an AI to integrate large-scale data, thanks to the neural network architecture described above), thereby opening doors to more biological breakthroughs based on existing data.  

## Why Lisp?

`Biochat` is written in Common Lisp.  Deal with it :sunglasses:  

Or just read the "Why Lisp?" section at: http://biolisp.org

## Installation

Additionally to having Quicklisp you'll need to clone [crawlik](https://github.com/vseloved/crawlik) into the home directory.

To use PubMed word vectors, `(pushnew :use-pubmed *features*)` before loading the system `biochat`.

## NLP in action (command-line example)

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

This software is thanks to the amazing work done by MANY people in the open source community of biological databases (GEO, PubMed, etc.)

The work on `Biochat` was done by [Bohdan B. Khomtchouk, Ph.D.](https://about.me/bohdankhomtchouk) and [Vsevolod Dyomkin](https://vseloved.github.io/).

## Funding

`Biochat` is supported by the National Institute on Aging of the National Institutes of Health under Award Number T32 AG0047126 awarded to Bohdan Khomtchouk. The content is solely the responsibility of the author(s) and does not necessarily represent the official views of the National Institutes of Health.

## Contributors
* Vsevolod Dyomkin
* You?

## Citation
Coming soon!
