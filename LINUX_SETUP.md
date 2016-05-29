# Linux setup
This document will give you a step-by-step guide to setup the Linked Data Theatre and a Virtuoso database on a clean Linux machine. A more experienced user might just want to read the deploy manual: [DEPLOY.md](DEPLOY.md)

## Debian
This guide assumes a fresh and clean installation of [Debian](https://www.debian.org). A minimal installation will suffice and no additional packages or options are needed. All the commands in this guide are run by the `root` user.

If you are installing virtuoso and the Linked Data Theatre in a virtual machine, then you will need to forward ports `8080` and `8890` from you host machine to the guest machine.

## Install software
Start with updating the apt repository:
```
>> apt-get update
>> apt-get upgrade
```

Later on we need curl:
```
>> apt-get install curl
```

### Install virtuoso
```
>> apt-get install virtuoso-server
```
During the installation process you are asked to enter the password for the main dba-user.

The virtuso conductor is not needed to complete this guide, but you will probably need this afterwards:
```
>> apt-get install virtuoso-vad-conductor
```

The installer will start virtuoso for you. You might need to restart it after installing conductor:
```
service virtuoso-opensource-6.1 restart
```
NOTE: Debian ships with version 6.1 of virtuoso. You might want to upgrade to a newer version.

You can test your virtuoso installation by visting [http://localhost:8890](http://localhost:8890). You should see the virtuoso start page. You can test the sparql endpoint at [http://localhost:8890/sparql](http://localhost:8890/sparql).

### Install Tomcat and the Linked Data Theatre
Install java:
```
>> apt-get install openjdk-7-jre-headless
```

Install tomcat:
```
>> apt-get install tomcat8
```
Go to the webapps directory:
```
>> cd /var/lib/tomcat8/webapps
```
Rename (or remove) the root directory:
```
>> mv ROOT oldROOT
```

Download the Linked Data Theatre:
```
>> wget https://github.com/architolk/Linked-Data-Theatre/releases/download/v1.7.0/ldt-1.7.0.war -O ROOT.war
```
NOTE: The will install version 1.7.0. You can change the download link if you prefer a different version.

Restart tomcat
```
>> service tomcat8 restart
```
The standard configuration of the Linked Data Theatre assumes port 80, but tomcat is connected to port 8080. Therefore the configuration needs to be adjusted. Edit the file `/var/lib/tomcat8/webapps/ROOT/WEB-INF/resources/apps/ldt/config.xml`. Change:
```
<site domain="localhost" icon="favicon.ico">
```
to
```
<site domain="localhost:8080" icon="favicon.ico">
```
You can test the Linked Data theatre by visitin [http://localhost:8080/version](http://localhost:8080/version). You should see:
```
<context xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" docroot="" version="1.7.0" timestamp="2016-05-02 22:29:32" sparql="no">
	<configuration-endpoint>http://127.0.0.1:8890/sparql</configuration-endpoint>
	<local-endpoint>http://127.0.0.1:8890/sparql</local-endpoint>
	<url>http://localhost:8080/version</url>
	<domain>localhost:8080</domain>
	<subdomain/>
	<query/>
	<representation-graph uri="http://localhost:8080/stage"/>
	<back-of-stage/>
	<language>nl</language>
	<user/>
	<user-role/>
	<representation/>
	<format>text/html</format>
	<subject>http://localhost:8080/version</subject>
	<parameters/>
</context>
```
Make sure the `representation-graph uri` shows the correct uri.

## Testing
The Linked Data Theatre comes with a couple of examples. You can download the turtle files:
```
>> cd /root
>> wget https://raw.githubusercontent.com/architolk/Linked-Data-Theatre/master/examples/tutorial/amersfoort.ttl
>> wget https://raw.githubusercontent.com/architolk/Linked-Data-Theatre/master/examples/tutorial/dbpedia.ttl
>> wget https://raw.githubusercontent.com/architolk/Linked-Data-Theatre/master/examples/tutorial/helloWorld.ttl
>> wget https://raw.githubusercontent.com/architolk/Linked-Data-Theatre/master/examples/tutorial/showGraphs.ttl
```

Upload to the triple store (put your virtuoso password at the placeholder `<<virtuosopassword>>`):
```
curl -X POST http://localhost:8890/sparql-graph-crud-auth?graph-uri=http:8080/stage --user dba:<<virtuosopassword>> --digest -T amersfoort.ttl
curl -X POST http://localhost:8890/sparql-graph-crud-auth?graph-uri=http:8080/stage --user dba:<<virtuosopassword>> --digest -T dbpedia.ttl
curl -X POST http://localhost:8890/sparql-graph-crud-auth?graph-uri=http:8080/stage --user dba:<<virtuosopassword>> --digest -T helloWorld.ttl
curl -X POST http://localhost:8890/sparql-graph-crud-auth?graph-uri=http:8080/stage --user dba:<<virtuosopassword>> --digest -T showGraphs.ttl
```
You can test the examples by visiting the Theatre pages:

[http://localhost:8080/query/helloWorld](http://localhost:8080/query/helloWorld)

[http://localhost:8080/query/amersfoort](http://localhost:8080/query/amersfoort)

[http://localhost:8080/query/dbpedia](http://localhost:8080/query/dbpedia)

[http://localhost:8080/query/showGraphs](http://localhost:8080/query/showGraphs)

---
Congratulations! You have now setup a virtuoso triple-store and connected the Linked Data Theatre.
