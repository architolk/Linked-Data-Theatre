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
