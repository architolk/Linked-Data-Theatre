# Make a release.
To make a release, follow these steps.

## 1. Set version number for new release.
The Linked Data Theatre uses [semantic versioning](http://semver.org).

If you make any changes to the LDT, you should include a `-SNAPSHOT` postfix to the project version, like any maven project. *A release version should never have such a postfix.*

- Set the project version for any new release.
- In case of a major or minor release: set the release version and release date. **Don't set the release version (or release date) for a patch version!**
- **Also: don't update the patch date at this step!**

Change this in the `\pom.xml` maven project file:

	<project>
		<version>1.6.0</version>
		<properties>
			<release.version>1.6.0</release.version>
			<release.date>2016-03-13</release.date>
			...
		</properties>

(This example shows only the relevant lines from the pom.xml. This example refers to a release with version 1.6.0 and release data march 13, 2016).

## 2. Change the README.md description
The README.md contains a link to the most recent release of the Linked Data Theatre. In case of a major or minor release: update this link.

## 3. Check if all license headers are set correctly
All license-headers should have the release version included. This means that all files should have the same date for major and minor releases (the release date). A patch release leaves the version header of unchanged files to the version of the major/minor release.

	mvn license:format

You should perform this step twice, just to be sure that every file header has the correct file date.

## 4. Create the war package
You're now ready to create the war:

	mvn clean package

## 5. Test the package
**NB: you should have a working triplestore with the test-configuration in place, or the test will fail.**

If you have a working triplestore, but not sure whether your configuration is up to date, please go to `\examples` and execute `deploy-tests.bat` (windows) or `deploy-tests.sh` (linux).

Please test the package for possible regression:

	mvn verify

This will install a temporary jetty application server at port 8888 (and port 8889 for the STOP commando). A jmeter functional test is performed. The build will fail if some regression has occured.

JMeter will check every response with a preconfigured MD5 hash. If for some reason the response has changed (for example: a version number has changed), the test will fail. To correct this, you will have to change the asserted MD5 hash. Please follow these steps if you want to update the regression test set:

1. Look into `/target/jmeter/results/*.jtl` and find out which test has failed. Write down the MD5 hash that has been generated from the response.
2. Look into `/target/testFiles` and find the reponse file that corresponds with the failed test (should be the same index number).
3. Please make sure that the result is actually what you want. You might have stumbled on a real error!
4. Start the jmeter GUI: `mvn jmeter:gui`. Open the testplan (at `/src/test/jmeter/FunctionalTestPlan.jmx`. Go to the definition of the failed test and fix the MD5 hash, at the MD5Hex assertion page.
5. Save the testplan and rerun the test.

If you want to have a look at the theatre via a browser, you could start the jetty application on its own:

	mvn jetty:run

Open a browser and go to `http://localhost:8888` to check the theatre. To end the jetty server, please use `CTRL-C` in the command windows.    

## 6. Commit changes to github and create release tag
For example (refering to release 1.6.0):

	git add -A
	git commit -m "Release 1.6.0"
	git push origin
	git tag -a v1.6.0 -m "Release 1.6.0"
	git push origin v1.6.0

## 7. Add war to github release
**Do this step only for minor and major releases! Patch release should not have a new war uploaded!.**

1. Goto github: [https://github.com/architolk/Linked-Data-Theatre/tags](https://github.com/architolk/Linked-Data-Theatre/tags). Look for the correct tag (should be the topmost) and navigate to "Add release notes".
2. Update the documentation for the release notes (at least: set the title to something like "Release 1.6.0").
3. Upload the war using the user interface of github. 
4. Publish the release.

## 8. Update pom.xml to snapshot version
Because any change after the release should be a new version, directly update the version of the project to patchversion+1 (for example from `.0` to `.1`) and prefix `-SNAPSHOT`. Also set the date of the patch level to the current date:

	<project>
		<version>1.6.1-SNAPSHOT</version>
		<properties>
			...
			<patch.date>2016-03-14</patch.date>
		</properties>

This is a safe way that mitigates the risk that you change a file without reference to the correct project version (which should be the patch version!). 