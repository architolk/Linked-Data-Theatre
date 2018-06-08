#!/bin/bash
cd tests
zip ../tests.zip *.ttl
cd ..
curl -X PUT -H "Content-Type: multipart/x-zip" -T tests.zip http://localhost:8080/ldt/backstage/import