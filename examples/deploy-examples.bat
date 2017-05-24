@echo off
cd tutorial
"C:\Program Files\7-Zip\7z.exe" a ..\tutorial.zip *.ttl
cd ..
curl.exe -X PUT -H "Content-Type: multipart/x-zip" -T tutorial.zip http://localhost:8080/backstage/import
del tutorial.zip
pause
