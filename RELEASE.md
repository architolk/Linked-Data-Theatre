# Make a release.
To make a release, follow these steps.

##1. Set version number for new release.
The Linked Data Theatre uses [semantic versioning](http://semver.org).

If you make any changes to the LDT, you should include a `-SNAPSHOT` postfix to the project version, like any maven project. *A release version should never have such a postfix.*

Set the project version for any new release. But set only the release version for a major or minor release. **Don't set the release version (or release date) for a patch version!**. Change this in the `\pom.xml` maven project file:

	<project>
		<version>1.6.0</version>
		<properties>
			<release.version>1.6.0</release.version>
			<release.date>2016-03-13</release.date>
			...
		</properties>

(This example shows only the relevant lines from the pom.xml. This example refers to a release with version 1.6.0 and release data march 13, 2016).

##2. Check if all license headers are set correctly
All license-headers should have the release version included. This means that all files should have the same date for major and minor releases (the release date). A patch release leaves the version header of unchanged files to the version of the major/minor release.

	mvn license:format

You should perform this step twice, just to be sure that every file header has the correct file date.

##3. Create the war package
You're now ready to create the war:

	mvn clean package

##4. Test the package
You should perform a regression test. A regression test is currently not part of the build procedure. 

##5. Commit changes to github and create release tag
For example (refering to release 1.6.0):

	git add *
	git commit -m "Release 1.6.0"
	git tag -a v1.6.0 -m "Release 1.6.0"
	git push origin v1.6.0

##6. Add war to github release
**Do this step only for minor and major releases! Patch release should not have a new war uploaded!.**

Goto github: [https://github.com/architolk/Linked-Data-Theatre/tags](https://github.com/architolk/Linked-Data-Theatre/tags). Look for the correct tag (should be the topmost) and navigate to "Add release notes" and update the documentation for the release notes. Upload the war using the user interface of github. Publish the release.

##7. Update pom.xml to snapshot version
Because any change after the release should be a new version, directly update the version of the project to patchversion+1 (for example from `.0` to `.1`) and prefix `-SNAPSHOT`. Also set the date of the patch level to the current date:

	<project>
		<version>1.6.1-SNAPSHOT</version>
		<properties>
			...
			<patch.date>2016-03-14</patch.date>
		</properties>

This is a safe way that mitigates the risk that you change a file without reference to the correct project version (which should be the patch version!). 