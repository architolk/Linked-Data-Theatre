@echo off
echo Deploying basic configuration...
curl.exe -X PUT -T ../basic-configuration.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stage
echo Done.
pause
