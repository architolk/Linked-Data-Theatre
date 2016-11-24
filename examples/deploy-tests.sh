echo Elmo vocabulary
curl -X PUT -T ../vocabulary/elmo.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://bp4mc2.org/elmo/def
echo Empty graph
curl -X PUT -T empty.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stage

cd tests
shopt -s nullglob
for FILE in *.ttl
do
	echo "Test file: $FILE"
 	curl -X POST -T "$FILE" "http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stage"

	# open url in browser (not all files result in a query yet(TODO))
	open 'http://localhost:8080/ldt/query/'${FILE%.ttl}
	read -p "Press any key to continue... " -n1 -s

done
