@echo off
echo Uploading elmo vocabulary...
curl.exe -X PUT -T ../vocabulary/elmo.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://bp4mc2.org/elmo/def
echo Clearing graphs...
curl.exe -X PUT -T empty.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stage
curl.exe -X PUT -T empty.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8888/stage
type NUL > concat.ttl
cd tests
for %%y in (*.ttl) do (
	echo Processing %%~ny...
	type %%y >> "../concat.ttl"
	echo. >> "../concat.ttl"
)
echo Deploying site check...
curl.exe -X PUT -T SiteWelcome.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stagename/substagename/stage
curl.exe -X PUT -T SiteWelcome.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8888/stagename/substagename/stage
cd ..
echo Deploying tests...
curl.exe -X POST -T concat.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stage
curl.exe -X POST -T concat.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8888/stage
del concat.ttl
echo Done.
pause
