#!/bin/bash
for vocab in $(cat vocabs.txt)
do
  echo $vocab
#  curl -s -X GET -L -H "Accept: text/turtle,application/rdf+xml" "$vocab" > vocab
  curl -s -X GET -L -H "Accept: text/turtle,application/rdf+xml" "$vocab" > vocab
  if file vocab | grep -qi "XML\|SGML"
  then
    echo "(XML)"
    mv vocab vocab.xml
    curl -X PUT -H "Content-Type: application/rdf+xml" -T vocab.xml http://localhost:8080/data2model/container/import
    rm -f vocab.xml
  else
    echo "(Turtle)"
    mv vocab vocab.ttl
    curl -X PUT -H "Accept: text/plain" -H "Content-Type: text/turtle" -T vocab.ttl http://localhost:8080/data2model/container/import
    rm -f vocab.ttl
  fi
done
