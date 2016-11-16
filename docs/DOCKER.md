#Docker build instructions
This document describes the steps to run the Linked Data Theatre with Docker.

A complete dockercompose file is already part of the Linked Data Theatre. The dockercompose file exists of 2 services/Docker containers:
- Tomcat container
- Virtuoso container

### Prerequisites

- Make sure you have a recent docker installation ([www.docker.com](https://www.docker.com))
- Install Maven

## Create network in Docker

At the command line execute the following command:

	docker network create ldt

## Build and start the Docker containers

Start the containers with (the first time, the containers will be build, this can take some time):

  docker-compose up

Now virtuoso should be running (http://localhost:8890/conductor/) and Tomcat should be running but without LDT yet.

## Prepare the LDT

### Update stored procedures
(This step is only necessary if you use Virtuoso as a backend. Note that some functionality (mainly backstage and containers) is not available if you use different backend).

Execute the following commands from your local machine:
1. docker cp stored-procs/create_procedures.sql virtuoso:/var/tmp
2. docker exec -it virtuoso sh -c 'isql -U dba -P dba < /var/tmp/create_procedures.sql'

### Adapt config for Docker
The default setup assumes Virtuoso and Tomcat run at the same server, but with Docker they communicate through the docker network. The LDT should be configured to use virtuoso (hostname) in stead of localhost.

#### Adapt Context.xml
In the file src/main/webapp/META-INF/context.xml replace localhost with virtuoso:
- serverName="localhost" -> serverName="virtuoso"
- url="jdbc:virtuoso://localhost:1111/" -> url="jdbc:virtuoso://virtuoso:1111/"

#### Adapt config.xml
In the file src/main/webapp/WEB-INF/resources/apps/ldt/config.xml:

Replace &lsaquo;theatre env="dev" configuration-endpoint="http://127.0.0.1:8890/sparql" local-endpoint="http://127.0.0.1:8890/sparql" sparql="yes"&rsaquo;

with

&lsaquo;theatre env="dev" configuration-endpoint="http://virtuoso:8890/sparql" local-endpoint="http://virtuoso:8890/sparql" sparql="yes"&rsaquo;

## Build LDT
(For this step Maven should be installed, another options is to download the LDT war release, see DEPLOY.md)

For building the LDT with Maven do (TODO implement in Maven in stead of separate script):

	bash build.sh

## Run LDT
Now ldt is up and running so open the backstage in your browser with the url:
http://localhost:8080/ldt/backstage, press import and select the file the basic-configuration.ttl press Upload.

Now LDT front could be opened in your browser with:
http://localhost:8080/ldt/
