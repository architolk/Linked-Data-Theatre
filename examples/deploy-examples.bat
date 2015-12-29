@echo off
echo Empty graph
curl.exe -X PUT -T empty.ttl http://localhost:8890/sparql-graph-crud?graph-uri=config:demo.localhost
cd tutorial
for %%y in (*.ttl) do (
	echo %%~ny
	curl.exe -X POST -T %%y http://localhost:8890/sparql-graph-crud?graph-uri=config:demo.localhost
)
pause
