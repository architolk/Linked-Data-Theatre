@echo off
echo Create testresult folder (or skip if already existing)
mkdir testresults
echo Remove previous testresults (if any)
del /q testresults\*
echo application/xml
curl -i -H "Accept: application/rdf+xml" -X GET http://localhost:8080/query/SelectFormats > testresults\select.rdf.xml
curl -i -H "Accept: application/sparql-results+xml" -X GET http://localhost:8080/query/SelectFormats > testresults\select.sparql.xml
curl -i -H "Accept: application/xml" -X GET http://localhost:8080/query/SelectFormats > testresults\select.xml
curl -i -H "Accept: application/json" -X GET http://localhost:8080/query/SelectFormats > testresults\select.json
curl -i -H "Accept: application/ld+json" -X GET http://localhost:8080/query/SelectFormats > testresults\select.ld.json
curl -i -H "Accept: text/turtle" -X GET http://localhost:8080/query/SelectFormats > testresults\select.ttl
curl -i -H "Accept: application/rdf+xml" -X GET http://localhost:8080/query/ConstructFormats > testresults\construct.rdf.xml
curl -i -H "Accept: application/sparql-results+xml" -X GET http://localhost:8080/query/ConstructFormats > testresults\construct.sparql.xml
curl -i -H "Accept: application/xml" -X GET http://localhost:8080/query/ConstructFormats > testresults\construct.xml
curl -i -H "Accept: application/json" -X GET http://localhost:8080/query/ConstructFormats > testresults\construct.json
curl -i -H "Accept: application/ld+json" -X GET http://localhost:8080/query/ConstructFormats > testresults\construct.ld.json
curl -i -H "Accept: text/turtle" -X GET http://localhost:8080/query/ConstructFormats > testresults\construct.ttl
pause
