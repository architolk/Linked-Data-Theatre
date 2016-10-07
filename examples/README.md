#Examples
This folder contains a list of examples for the Linked Data Theatre. It contains all the features that are available in the Linked Data Theatre.

##Regression test
This folder also contains a couple of tests to check if all functionality of the LDT is working correctly.

##Prerequisites
To execute the tests, please have:

- A Tomcat server at http://localhost:8080;
- A Virtuoso sparql endpoint at http://localhost:8890;
- A sesame endpoint at http://localhost:7200.

##Starting the tests
Execute `deploy-tests.bat` to insert the configuration and testdata into the triplestore.

For the sesame tests, insert the `testdata.ttl` triples into a repository with the name `data`.