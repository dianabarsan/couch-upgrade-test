#!/bin/bash
set -e
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $BASEDIR


user=admin
password=pass

couch_url=http://$user:$password@127.0.0.1:25984

waitForStatus() {
  count=0
  echo 'Starting curl check'
  echo $1
  while [ `curl -o /dev/null -s -w "%{http_code}\n" "$1"` -ne "$2" -a $count -lt 300 ]
    do count=$((count+=1))
    sleep 1
  done
  echo "CouchDb ready"
}

# cleanup from previous test
mkdir -p ../data
rm -rf ../data/*
docker rm -f -v test-couchdb2 test-couchdb3

# data store
couch2dir=$(mktemp -d -t couchdb-2x-XXXXXXXXXX)

# start couch 2.3.1 container
docker run -d -p 25984:5984 -p 25986:5986 --name test-couchdb2 -e COUCHDB_USER=$user -e COUCHDB_PASSWORD=$password -v $couch2dir:/opt/couchdb/data apache/couchdb:2.3.1
waitForStatus $couch_url 200
curl -s $couch_url/_membership

# generate documents and index views
node ./generate-documents.js $couch_url

docker rm -f -v test-couchdb2

# start couch 3.2.2 container
docker run -d -p 25984:5984 --name test-couchdb3 -e COUCHDB_USER=$user -e COUCHDB_PASSWORD=$password -v $couch2dir:/opt/couchdb/data apache/couchdb:3
waitForStatus $couch_url 200
curl $couch_url/_membership

# assert all docs are present and views are indexed
node ./assert-dbs.js $couch_url
