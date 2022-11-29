#!/bin/bash
set -e
user=admin
password=pass

couch_url=http://$user:$password@127.0.0.1:25984

waitForStatus() {
  count=0
  echo 'Starting curl check'
  echo $1
  while [ `curl -o /dev/null -s -w "%{http_code}\n" "$1"` -ne "$2" -a $count -lt 300 ]
    do count=$((count+=1))
    echo "Waiting for CouchDb to respond. Current count is $count"
    sleep 1
  done
  echo "CouchDb ready"
}

rm -rf ./data/*
docker rm -f -v test-couchdb2 test-couchdb3

couch2dir=$(mktemp -d -t couchdb-2x-XXXXXXXXXX)

docker run -d -p 25984:5984 -p 25986:5986 --name test-couchdb2 -e COUCHDB_USER=$user -e COUCHDB_PASSWORD=$password -v $couch2dir:/opt/couchdb/data apache/couchdb:2.3.1

waitForStatus $couch_url 200

node ./generate-documents.js $couch_url
echo $(curl $couch_url/_membership)
docker rm -f -v test-couchdb2

docker run -d -p 25984:5984 -p 25986:5986 --name test-couchdb3 -e COUCHDB_USER=$user -e COUCHDB_PASSWORD=$password -v $couch2dir:/opt/couchdb/data apache/couchdb:3
waitForStatus $couch_url 200

echo $(curl $couch_url/_membership)

node ./assert-dbs.js $couch_url
