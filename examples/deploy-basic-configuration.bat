@echo off
echo Deploying basic configuration...
curl.exe -X PUT -T ../basic-configuration.ttl http://localhost:8080/ldt/backstage/import
echo Done.
pause
