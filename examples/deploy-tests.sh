#!/bin/bash
echo Elmo vocabulary
curl -X PUT -T ../vocabulary/elmo.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://bp4mc2.org/elmo/def
echo Empty graph
curl -X PUT -T empty.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stage
curl -X PUT -T empty.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8888/stage

cd tests
shopt -s nullglob
for FILE in *.ttl
do
	echo "Test file: $FILE"
 	curl -X POST -T "$FILE" "http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stage"
 	curl -X POST -T "$FILE" "http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8888/stage"
done
echo Site check
curl -X PUT -T SiteWelcome.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stagename/substagename/stage
