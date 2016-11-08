# package all dependencies (TODO: should be done by Maven)
cd license-builder/
mvn clean install
cd ..
cd orbeon/
mvn package
cd ..
cd ext-resources
mvn package
cd ..
cd processors
bash maven-install-orbeon-jar.bat
mvn clean install
cd ..
# package ldt
mvn clean package
# cp files to tomcat webapps dir
cp -R target/ldt*/ webapps/ldt/
