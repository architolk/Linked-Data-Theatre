# Building the Linked Data Theatre
This document describes the steps to build the Linked Data Theatre.
## Prerequisites
You should have a sound build environment, please install:

- An up-to-date version of the JDK, from [http://www.oracle.com/technetwork/java/javase/downloads/index.html](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
- Git. You've probably already installed git. If not, go to: [http://www.git-scm.com/downloads](http://www.git-scm.com/downloads)
- Maven, from: [https://maven.apache.org/download.cgi](https://maven.apache.org/download.cgi)

## Dependancy on open source components
The Linked Data Theatre depends on a couple of open source components:

1. Virtuoso Open Source, the triple store
2. Orbeon, a portal implementation. The LDT uses Orbeon only for the MVC framework within an XPL context
3. Tomcat, the web application service used to deploy Orbeon and the LDT itself
4. Bootstrap, the responsive UI framework
5. A couple of javascript libraries (mainly: jQuery, D3.js, Leaflet.js and Yasqe.js)

### Virtuoso
You can download Virtuoso from this location: [http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main](http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main).
Prebuild versions are avaiable, you can also try to build virtuoso yourself.
Installing Virtuoso isn't necessary for the build process, but should be done as part of the installation.

### Orbeon
You need the orbeon.jar file to build some of the LDT components. And the orbeon code is necessary to build to whole Linked Data Theatre. The latest version of orbeon Community Edition from this location: [http://www.orbeon.com/download](http://www.orbeon.com/download).
The LDT is tested with version 4.7.0 of Orbeon. 

Execute the following steps to download the required files and place them in the correct directories:

1.	Fork and clone the Linked-Data-Theatre from https://github.com/architolk/Linked-Data-Theatre to a local directory.
2.	In command prompt: `cd {local directory}\Linked-Data-Theatre\orbeon`
3.	Execute: `mvn package`


### Tomcat
You need an installation of Tomcat to run Orbeon, and within Orbeon the Linked Data Theatre.
You can download Tomcat from this location: [https://tomcat.apache.org/](https://tomcat.apache.org/).
The LDT is tested with Tomcat version 7.0.33.

1.	Download Tomcat from https://tomcat.apache.org/. The LDT is tested with Tomcat version 7.0.33.
2.	Unpack the distribution so that it resides in its own directory
3.	Create an environmental variable CATALINA_HOME and set it to the directory where the distribution of tomcat resides
4.	In command prompt execute: `cd %CATALINA_HOME%\bin`
5.	Run Tomcat bij executing the following command: `startup.bat`
6.	Visit http://localhost:8080/ to check the default web application included with Tomcat. In case the web application cannot be reached go to the directory where Tomcat is installed and open RUNNING.txt. Possible solutions for not being able to visit the default web application can be found at the end of this document.
7.	Close tomcat with the command: `shutdown.bat`

### Bootstrap and other javascript libraries
The LDT uses a couple of javascript libraries. It is not needed to download these libraries: the build process will take care of this. Fetch all libraries by executing the command `mvn package` in the `ext-resources` directory.

## Build proces
The Linked Data Theatre consists of four different components:

1. Java source code, for custom Orbeon processors
2. Virtuoso stored procedures
3. Javascript
4. Orbeon app (mainly XPL and XSL source code)

### Build the java source code
To build the java source code perform the following steps (only ones):

1.	Go to \license-builder and execute: `mvn clean install`
2.	Go to \processors and install the orbeon.jar in your local maven repository by executing: `maven-install-orbeon-jar.bat`.
3.	Go to \processors and execute `mvn clean install`

### Virtuoso stored procedures
No build is needed for the virtuoso stored procedures.

### Javascript
No build is needed for the javascript sources.

### Orbeon app
You should only perform this step after all other steps!
To build the full orbeon app (including the orbeon code):

1.	Go to the root directory of the Linked Data Theatre.
2.	Execute: `mvn clean package`. 
