@echo off
mvn install:install-file -Dfile=../morphrdb/morph-rdb-dist-3.5.15.jar -DgroupId=morphrdb -DartifactId=morphrdb -Dversion=3.5.15 -Dpackaging=jar -DgeneratePom=true
pause
