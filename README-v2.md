# Biochat 2 - matching bioinformatics dataset for fun and profit

The project's initial concept is by [Bohdan Khomtchouk](http://bohdankhomtchouk.com):

> a 24/7 artificial intelligence system that's using NLP techniques to pair, organize, and group together different biological datasets, such that you could query based on a set of keywords (e.g., "cancer", "leukemia", "mouse"), and it would return to you datasets that are most like each other and most deserving of being considered integratively (i.e., analyzing both or three together could unlock an interesting medical result that could not otherwise be found by analyzing just one dataset alone)

The plan for the first version is:

* [x] Scrape [GEO](https://www.ncbi.nlm.nih.gov/geo/), then extract the title, summary, etc. from each entry (entry example: <https://www.ncbi.nlm.nih.gov/sites/GDSbrowser?acc=GDS4303>)
* [ ] Store all this structured metadata in a database
* [ ] Teach an algorithm to match similar groups (e.g., if organism is "Mus musculus", i.e. mouse) then group them together (which is easy), but also be able to spot "leukemia" as a cancer type, so group it together with other cancer types

Stages of the development of matching algorithm:

* [ ] Direct matching on a per-word or per-phase basis
* [ ] Similarity matching using vector space modeling. Using word vectors from <https://github.com/cambridgeltl/BioNLP-2016> and the [doc2vec approach](https://cs.stanford.edu/~quocle/paragraph_vector.pdf)


## Installation

Additionally to having Quicklisp you'll need to clone [crawlik](https://github.com/vseloved/crawlik) to `~/common-lisp/`.
