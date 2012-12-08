αρχεια
======

Currently experimental, full-text, document database management system with
primarily text mining in mind (frequent reads, rare updates).

Originally I set-out to mine mailing list archives, but realized that the
concept generalizes to any collection of textual documents.

Build and usage instructions are intentionally omitted, since I do not intend
for anyone to use it just yet, however - I welcome any help/suggestions :)


Concepts
--------
* Database, stores collections
* Collection, stores documents
* Document, stores:
    - body of text
    - set of mendatory meta headers:
        - ID
        - Title
        - Authors
        - Links (a set of IDs (references in a paper, parents in a mailing list
          thread, etc))
    - set of arbitrary, optional meta headers
* Query language: a subset of SQL


High-level Roadmap
------------------
Primarily I am interested in mining collections of textual documents, not
necessarily storing application data, so updates will receive less attention
then full-text searching.


Low-level Roadmap
-----------------
* Hashing of supplied document IDs (which may contain any character and make
  filesystem storage error-prone)
* ~~Store individual documents as marshalled records (as opposed to raw text)~~
* ~~Switch to in-memory index construction (disk is much slower than I
  realized...)~~
* ~~Switch to single file marshalling (again, due to slow disk) at least until
  more infrustructure (HTTP server and front-end) is added and I can look into
  specialized binary formats~~
* Add a simple HTTP server
* Add a simple HTTP access API (not sure of serialization yet, but JSON seems
  fine)
* Add a simple web client
* Index headers in addition to body
* Implement Suffix Tree indexing
* Implement substring matching


Random thoughts/ideas
---------------------
* SSH shell for interactive admin and client sessions
