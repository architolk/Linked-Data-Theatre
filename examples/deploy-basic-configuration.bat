@echo off
echo Deploying basic configuration...
curl.exe -X PUT -T ../basic-configuration.ttl http://localhost:8080/backstage/import
echo Done.
pause
