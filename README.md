Test whether view indexes are preserved when upgrading from Couch 2.3.1 to Couch 3.2.2

Steps:
- launch 2.3.1 in docker container, no config changes
- create 4 databases, each with 1000 documents + one view
- query this view and output data
- kill 2.3.1 container
- launch 3.2.2 in docker container, mounting same data volume as 2.3.1
- query database views with `stale=ok&update_seq=true` and throw error if views are not indexed

Usage:

```
npm ci
./test/single-node-upgrade.sh
```
