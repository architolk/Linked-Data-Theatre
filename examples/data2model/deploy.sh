#!/bin/bash
zip config.zip *.ttl
curl -X PUT -H "Content-Type: multipart/x-zip" -T config.zip http://localhost:8080/data2model/backstage/import
