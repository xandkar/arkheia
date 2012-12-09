αρχεια
======

Experimental, full-text, document database management system with primarily
text mining in mind (frequent reads, rare updates).

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
    - set of mandatory meta headers:
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
* Storage:
    + ~~Switch to in-memory index construction (disk is much slower than I
      realized...)~~

    + ~~Hashing of supplied document IDs (which may contain any character and
      make filesystem storage error-prone)~~

    + ~~Store individual documents as marshalled records (as opposed to raw
      text)~~

    + ~~Switch to single file marshalling (again, due to slow disk) at least
      until more infrustructure (HTTP server and front-end) is added and I can
      look into specialized binary formats~~

    + Storage engine:
        - Use a 3rd party storage engine (BDB? Kyoto Cabinet? LevelDB?)
        - Storage engine abstracted and swappable
        - Implement a simple k/v storage engine

* Web interface:
    + Simple HTTP server
    + Simple HTTP access API (not sure of serialization yet, but JSON seems
      fine)
    + Simple web client

* Index headers in addition to body

* Implement Suffix Tree indexing

* Implement substring matching


Random thoughts/ideas
---------------------
* SSH shell for interactive admin and client sessions
