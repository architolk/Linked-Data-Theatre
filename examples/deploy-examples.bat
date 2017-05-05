@echo off
type NUL > concat.ttl
cd tutorial
for %%y in (*.ttl) do (
	echo Processing %%~ny...
	type %%y >> "../concat.ttl"
	echo. >> "../concat.ttl"
)
cd ..
echo Deploying...
curl.exe -X PUT -T concat.ttl http://localhost:8890/sparql-graph-crud?graph-uri=http://localhost:8080/stage
del concat.ttl
echo Done.
pause
