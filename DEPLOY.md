# Deploying the Linked Data Theatre
This document describes the steps to build the Linked Data Theatre.
You could follow two approaches:

- Deploying the Linked Data Theatre using Docker. This is described in: [DOCKER.md](DOCKER.md).
- Deploying the Linked Data Theatre from scratch.

## Deploying the Linked Data Theatre from scratch

### Prerequisites
You should have a working version of the Java Runtime Environment.

### 1. Install a triple store
The configuration of the LDT should be stored in a triple store. The LDT uses a SPARQL endpoint to query for the configuration. And, naturally, the LDT uses one or more triple stores to fetch the data that is presented by the LDT. The LDT can use any SPARQL 1.1 endpoint, but is optimized for use with Virtuoso.

You can download Virtuoso from this location: [http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main](http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main).
Prebuild versions are available, you can also try to build virtuoso yourself.

#### 1.1 Update stored procedures
Execute `\stored-procs\install.bat`, located in your git repository. If you have only downloaded the war from the release, follow these steps:

1. Download the file [create_procedures.sql](stored-procs/create_procedures.sql);
2. Open your browser at [http://localhost:8890/conductor](http://localhost:8890/conductor), login as dba and navigate to the interactive SQL module;
3. Paste the content of the create_procedures.sql file into the interactive SQL editor;
4. Click on the `Execute` button.

### 2. Install Tomcat
You need an installation of Tomcat to run Orbeon, and within Orbeon the Linked Data Theatre.
You can download Tomcat from this location: [https://tomcat.apache.org/](https://tomcat.apache.org/).
The LDT is tested with Tomcat version 7.0.33.

### 3. Install the Linked Data Theatre
Stop your Tomcat service. Delete all files in the \webapps\ROOT directory and unpack the LDT.war into the \webapps\ROOT directory. Restart your Tomcat service.

#### 3.1 Using an existing Tomcat installation
If you want to use an existing tomcat installation, just unpack the war in the \webapps\ldt directory. Make sure you change the configuration file (section 4.1).

### 4. Change the configuration file
All system configurations are stored in `\webapps\ROOT\WEB-INF\resources\apps\ldt\config.xml`. The default configuration works OK for development purposes: installation on your localhost with a virtuoso endpoint on the same machine. Change it if you have a different configuration. (See the wiki for more information).

#### 4.1 In case of an existing Tomcat installation.
If you have performed step 3.1, please add a `docroot` statement to the configuration file:

	<site domain="localhost" icon="favicon.ico" docroot="/ldt">
		<stage/>
	</site>

Without the docroot statement, the LDT won't be able to find the right stylesheets or javascript libraries.

### 5. Test your version of the Linked Data Theatre
Go to `http://localhost/version` and check if the Linked Data Theatre runs correctly. You should receive something that looks like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<context sparql="no" timestamp="2016-03-13 16:24:38" version="1.6.0" docroot="">
		<configuration-endpoint>http://127.0.0.1:8890/sparql</configuration-endpoint>
		<local-endpoint>http://127.0.0.1:8890/sparql</local-endpoint>
		<url>http://localhost/version</url>
		<domain>localhost</domain>
		<subdomain/>
		<query/>
		<representation-graph uri="http://localhost/stage"/>
		<back-of-stage>http://localhost/stage</back-of-stage>
		<language>nl</language>
		<user/>
		<user-role/>
		<representation/>
		<format>text/html</format>
		<subject>http://localhost/version</subject>
		<parameters/>
	</context> 