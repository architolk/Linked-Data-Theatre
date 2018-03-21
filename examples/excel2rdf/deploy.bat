@echo off
"C:\Program Files\7-Zip\7z.exe" a config.zip *.ttl
curl.exe -X PUT -H "Content-Type: multipart/x-zip" -T config.zip http://localhost:8080/excel2rdf/backstage/import
pause
