#License

##Prerequisite
To use the license builder, please compile and install the license builder subproject.
 
##Usage
As the Linked Data Theatre is open source software, every file should contain a reference to the license.

It is not needed to manually place the license header, this can be done with the maven instruction:

    mvn license:format

This will check any file for the right license header. The header contains a reference to the file name, the file date and the project version.

This has two side effects:

- The file date will always be the date at which the license is checked, even if the original file date was earlier (because the header will be updated, which means the filedate changes);
- If the project version changes, all files are updated to the current date.

**So: don't update the license header if you don't want this behavior!!**

To check which files are out-of-date, you can use:

    mvn license:check

##Update version without updating all files
It is possible to update the project version without updating all files. For this purpose the main POM contains the properties release.version and release.date. The file-headers are considered out of date only if:

- The file date is older than the release data, AND
- The file version is not the same as the release version.

If the file data is newer than the release data, the file version should be the same as the project version.