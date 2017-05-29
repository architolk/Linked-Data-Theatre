@echo off
echo Empty graph
curl.exe -X PUT -T empty.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8888/stage
cd tests
for %%y in (*.ttl) do (
	echo %%~ny
	curl.exe -X POST -T %%y http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8888/stage
)
echo Site check
curl.exe -X PUT -T SiteWelcome.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8888/stagename/substagename/stage
pause

