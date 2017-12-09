# Biochats relevance algorithms

Biochats is a collection of procedures to group records by similarity
based on their free text description and other meta information. The
records are obtained from the datasets of biological experiment data,
such as GDS and GSE. The data is collected using web scraping.

Similarity, in the context of dataset descriptions, is not a
well-defined concept, as the dataset record contains a number of
fields, including free-form text descriptive ones such as the title,
summary, and experiment design, as well as more structured fields like
the sample organism or platform. Besides, from the point of view of a
researcher, different notions of similarity may be relevant. For
instance, sometimes only datasets for a particular group of organisms
are of interest. A more nuanced case is when only experiments that
target a particular histone (which may be mentioned in the text
summary but is not indicated in a special field) are requested. That's
why the Biochats project aims to provide a flexible toolset suitable
for experimenting with different similarity measures and their
parameters, as well as supplemental filtering based on additional
parameters.

## Biochats similarity measures

In the context of Biochats, a similarity measure is a function of 2
records that returns a number in the interval [0,1] signifying the
degree of similarity (the closer to 1 - the more similar). The
magnitude of the similarity doesn't have any particular meaning, the
only requirement is that records considered more similar should have a
larger value of similarity. So, similarity values obtained by
different similarity measures can't be compared.

Currently, in Biochats, two principal approaches to similarity
measurement are:

- bag-of-words-based similarity
- distributed representation based similarity

In the bag-of-words (or token-based) approach, each record's textual
description is transformed into a (sparse) vector of the size equal to
the size of the vocabulary. The transformation is performed by
tokenization of the text, and then assigning to the element of the
document vector representing each token some weight value.

The BoW similarity measures include the variants of TF-IDF [1]:
vanilla one and BM25 [2].

The TF and IDF vocabularies are calculated from the whole record set
using the tokens from the record's title, summary, and design
description. TF count for each document is calculated as a ratio of
token count by the document's length. IDF count is calculated using
the standard log weighting (`log(record count / token frequency)`).

Both TF-IDF and BM25 similarity measures calculations use the stored
weights. The similarity value of two records is calculated as a ratio
of the sum of all TF-IDF weights of the tokens present in both
record's text descriptions divided by the product of the L2-norms of
the TF-IDF vectors of each record.

The difference between the measures is that, in BM25, instead of the
plain TF-IDF, the following formula is used: `(k + 1) * tf * idf / (k
+ tf)`, where `k` is the BM25 parameter, the default value of which is
chosen as 1.2.

Another approach to document representation implemented in Biochats is
based on vector space models that use dense low-dimensional (vector
size: 100-300) word vectors and combine them in some way into a same
dimensional document vector. There are 2 approaches to obtaining the
document vectors: by simple aggregation of the pre-calculated word
vectors and by constructing the vector using an ML algorithm - see
Paragraph vectors [3] or Skip Thought vectors [4]. In Biochats, we
chose to implement the aggregation approach using the PubMed word
vectors [5] calculated with the word2vec algorithm [6]. This is due to
the availability of high-quality pre-trained vectors, lack of training
data for the successful application of the doc2vec approaches, and the
empirical results showing that simple word vectors aggregation
performs not worse on short texts [7].

The similarity measures based on document vectors implemented in
Biochats perform the comparison using the following algorithms:

- cosine similarity and smoothed cosine similarity [8]
  (5 is chosen as the default smoothing factor)
- Euclidian distance-based similarity. The formula for calculating the
  similarity score in the interval [0,1] is the following:
  `1/(nrm2(v1 - v2) + 1)`, where `nrm2` is the L2-norm
- combined cosine/Euclidian distance similarity that uses the square
  root of the product of both measures

## Biochats filtering procedures

The main application of Biochats is sorting the records database according to the similarity to a selected record. The sorted output may be additionally filtered based on a set of criteria:

- retain only records for a selected organism or group of organisms
- retain only records that mention a particular histone [9]


## References

[1]: http://www.tfidf.com/
[2]: https://dl.acm.org/citation.cfm?id=1704810
[3]: https://cs.stanford.edu/~quocle/paragraph_vector.pdf
[4]: https://arxiv.org/abs/1506.06726
[5]: http://bio.nlplab.org/
[6]: https://arxiv.org/abs/1301.3781
[7]: https://arxiv.org/pdf/1607.00570.pdf
[8]: http://www.benfrederickson.com/distance-metrics/
[9]: https://en.wikipedia.org/wiki/Histone



