::
:: NAME     build.bat
:: VERSION  1.17.1-SNAPSHOT
:: DATE     2017-05-05
::
:: Copyright 2012-2017
::
:: This file is part of the Linked Data Theatre.
::
:: The Linked Data Theatre is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.
::
:: The Linked Data Theatre is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.
::
:: You should have received a copy of the GNU General Public License
:: along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.
::

@echo off
:: Update the TOMCAT_ROOT variable if you are using a docroot for your Linked Data Theatre installation
set TOMCAT_ROOT="%CATALINA_HOME%\webapps\ROOT"
cd target
del /F /Q *
cd ..\orbeon
call mvn package
cd ..\ext-resources
call mvn package
cd ..\license-builder
call mvn clean install
cd ..\orbeon
call mvn clean package
cd ..\processors
call maven-install-orbeon-jar.bat
call maven-install-virtuoso-jar.bat
call mvn clean install
cd ..
call mvn clean package
cd target
cd ldt*
call xcopy /E /Y * "%TOMCAT_ROOT%"