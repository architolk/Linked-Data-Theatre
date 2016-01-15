# Deploying the Linked Data Theatre
This document describes the steps to build the Linked Data Theatre.
You could follow two approaches:

- Deploying the Linked Data Theatre using Docker. This is described in: [DOCKER.md](DOCKER.md).
- Deploying the Linked Data Theatre from scratch.

## Deploying the Linked Data Theatre from scratch

### Prerequisites
You should have a working version of the Java Runtime Environment.

### Install virtuoso
You can download Virtuoso from this location: [http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main](http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main).
Prebuild versions are avaiable, you can also try to build virtuoso yourself.
Installing Virtuoso isn't necessary for the build process, but should be done as part of the installation.

### Install Tomcat
You need an installation of Tomcat to run Orbeon, and within Orbeon the Linked Data Theatre.
You can download Tomcat from this location: [https://tomcat.apache.org/](https://tomcat.apache.org/).
The LDT is tested with Tomcat version 7.0.33.

### Install the Linked Data Theatre
Stop your Tomcat service. Delete all files in the \webapps\ROOT directory and unpack the LDT.war into the \webapps\ROOT directory. Restart your Tomcat service.

### Test your version of the Linked Data Theatre
Go to `http://localhost/version` and check if the Linked Data Theatre runs correctly. 