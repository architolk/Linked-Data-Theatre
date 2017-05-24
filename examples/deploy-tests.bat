@echo off
cd tests
"C:\Program Files\7-Zip\7z.exe" a ..\tests.zip *.ttl
cd ..
curl.exe -X PUT -H "Content-Type: multipart/x-zip" -T tests.zip http://localhost:8080/backstage/import
del tests.zip
pause
