Αρχεια
======

Document archival and analysis.

## Design ideas

### Storage

3 databases:

1. Object storage: key = hash of raw document, value = raw document
2. Meta data: table of descriptive fields and a document hash
3. Index: key = token, value = list of locations
