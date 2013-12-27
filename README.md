Αρχεια
======

Document archival and analysis.


Design ideas
------------

### Storage
Component interfaces should be abstracted in such a way that initial
implementation can use SQLite for everything, and later move to a Dynamo-style
K/V store, like Riak.

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
