@echo off
echo Empty graph and populate with elmo vocabulary definition
curl.exe -X PUT -T elmo.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://bp4mc2.org/elmo/def
pause
