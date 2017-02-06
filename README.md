# Biochat

`Biochat` is a Python natural language processing (NLP) module written in highly-tuned Cython that efficiently categorizes and pairs similar items (e.g., words) into groups.  It is basically the high performance computing (HPC) data science equivalent of the chemistry saying "like dissolves like."  

## Significance

We apply the "like dissolves like" principle to teach data files to learn to talk to each other (quite literally).  In order to talk, data must first be able to find each other in space (not a trivial task, considering that there are dozens of bioinformatics databases out there... see how we've tackled this problem with <a href="https://github.com/Bohdan-Khomtchouk/PubData">PubData</a>).  So how, for example, is an RNA-seq dataset supposed to find its potentially related ChIP-seq dataset (e.g., according to some combination of similar cell type, histone mark, sequencing details, etc.)?  Through metadata, of course!  However, for the datasets to meet each other via a similar metadata footprint requires sophisticated NLP strategies to introduce them.  Once the datasets meet, we can let the conversations (i.e., integrative bioinformatics analyses) begin!  Hence the name: `Biochat`.

## Motivation
Our ultimate goal is to make integrative multi-omics a lot easier (and more fun) through artificial intelligence (AI).  Right now, we are barely scratching the surface with NLP.  Thus, we are currently implementing novel neural network approaches to help us teach data to talk to each other (stay tuned!).  


## Algorithms<sup>1</sup>

`Biochat` uses the following formula for calculating the similarity between any two distinct entities:

![image](https://cloud.githubusercontent.com/assets/5694520/21303565/5e4c1c5c-c5d4-11e6-95fe-3e434c1a3b21.png)

![image](https://cloud.githubusercontent.com/assets/5694520/21303577/79b0bd5e-c5d4-11e6-84dd-0b8343ee70b0.png)


Where affinity is defined as follows:

![image](https://cloud.githubusercontent.com/assets/5694520/21303883/c74fe9a2-c5d6-11e6-8634-d2e212ff5b32.png)

![image](https://cloud.githubusercontent.com/assets/5694520/21303889/d435c68c-c5d6-11e6-8334-8d88e20529d4.png)

We are currently re-pivoting our platform into a deep learning architecture (stay tuned!).


## Funding
`Biochat` is financially supported by the United States Department of Defense (DoD) through the National Defense Science and Engineering Graduate Fellowship (NDSEG) Program. This research was conducted with Government support under and awarded by DoD, Army Research Office (ARO), National Defense Science and Engineering Graduate (NDSEG) Fellowship, 32 CFR 168a.


-------------
<sub>
1. Yael Karov and Shimon Edelman. 1998. Similarity-based word sense disambiguation.
*Computational Linguistics, 24(1):41-59.*	
</sub>
