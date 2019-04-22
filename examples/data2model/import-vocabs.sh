#!/bin/bash
for vocab in $(cat vocabs.txt)
do
  echo $vocab
  curl -X GET -L -H "Accept: application/rdf+xml" $vocab > vocab.xml
  curl -X PUT -H "Content-Type: application/rdf+xml" -T vocab.xml http://localhost:8080/data2model/container/import
done
rm -f vocab.xml
