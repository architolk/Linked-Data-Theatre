#!/bin/bash
rm -f config.zip
zip config.zip *.ttl
cd extensions
zip ../config.zip *.ttl
cd ..
curl -X PUT -H "Content-Type: multipart/x-zip" -T config.zip http://localhost:8080/data2model/backstage/import
