@echo off
curl -H "accept:application/json" -X POST -F title=mytitle -F file=@content.ttl -F container=http://localhost:8080/container/defquery http://localhost:8080/container/defquery
pause
