Αρχεια
======
Experiments with document archival and analysis.


Design ideas
------------

### Import
On import, a document is classified and parsed into meta data tags by a parser
for the determined type (such as: email message, research paper, photo, etc).


### Analysis
From meta data analysis, new entities can be discovered, such as people, and
links established between entities (a relationship graph). For example: I have
an email from, and a few photos of, John Smith, and he is also an author of
several papers (on certain topics, that he is now linked to) and a recipient of
some other emails from me directly or by way of CC (which implies either direct
or proxy relationship), he is also an author of emails to a set of mailing
lists and he usually replies to certain topics, etc. The rabbit hole is nearly
infinite.


### Storage
Component interfaces should be abstracted in such a way that initial
implementation can use SQLite for everything, and later move to an
eventually-consistent k/v store, like Riak.

Meta data makes the most sense as a relational table. Can we represent it as
k/v pairs-only (without relying on something like LevelDB 2i), and still
provide sane, complex querying?

How to represent/store a relationship graph?

doc-id = hash of document

3 collections:

#### Object storage
| Key    | Value    |
|--------|----------|
| doc-id | document |

#### Meta data
| Document ID | Tag      | Value     |
|-------------|----------|-----------|
| doc-id      | tag-name | tag-value |

#### Index
Suffix tree. But how to store?
Abstract in such a way that initial implementation can use SQLite and later can
be swapped with an implementation of on-disk suffix tree.
