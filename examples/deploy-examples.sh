echo Empty graph
curl -X PUT -T empty.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stage
cd tutorial
shopt -s nullglob
for FILE in *.ttl 
do 
    echo "$FILE"
    curl -X POST -T "$FILE" "http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stage"
done
echo Done
