#Docker build instructions
A complete dockercompose file is already part of the Linked Data Theatre. The dockercompose file exists of 2 services:
- Tomcat container
- Virtuoso container

Make sure you have a recent docker installation ([www.docker.com](https://www.docker.com)), and proceed by creating the network:

	docker network create ldt

Start the containers with:

  docker-compose up

Also do (TODO automate this step):
	execute create_procedure.sql

Adapt context.xml (in META-INF)
  Replace localhost with virtuoso
	serverName="localhost" -> serverName="virtuoso"
	url="jdbc:virtuoso://localhost:1111/" -> url="jdbc:virtuoso://virtuoso:1111/"

Adapt config.xml (in WEB-INF/resources/apps/ldt/config.xml)
<theatre env="dev" configuration-endpoint="http://127.0.0.1:8890/sparql" local-endpoint="http://127.0.0.1:8890/sparql" sparql="yes">
to
<theatre env="dev" configuration-endpoint="http://virtuoso:8890/sparql" local-endpoint="http://virtuoso:8890/sparql" sparql="yes">


Now virtuoso should be running (http://localhost:8890/conductor/) and Tomcat should be running but without LDT yet. For building the LDT with Maven do (TODO implement in Maven in stead of seperate script):

	bash build.sh
