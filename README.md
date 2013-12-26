Αρχεια
======

Document archival and analysis.

## Design ideas

### Storage

3 databases:

#### Object storage (k/v)
| Key                  | Value        |
|----------------------|--------------|
| hash of raw document | raw document |

#### Meta data (relational)
| Document             | Field-1  | .. | Field-N |
|----------------------|----------|----|---------|
| hash of raw document | datum-1  | .. | datum-N |

#### Index (k/v)
| Key   | Value            |
|-------|------------------|
| token | set of locations |
