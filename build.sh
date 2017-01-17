#
# NAME     build.sh
# VERSION  1.14.0
# DATE     2017-01-04
#
# Copyright 2012-2017
#
# This file is part of the Linked Data Theatre.
#
# The Linked Data Theatre is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# The Linked Data Theatre is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.
#

# package all dependencies (TODO: should be done by Maven)
cd license-builder/
mvn clean install
cd ..
cd orbeon/
mvn package
cd ..
cd ext-resources
mvn package
cd ..
cd processors
bash maven-install-orbeon-jar.bat
mvn clean install
cd ..
# package ldt
mvn clean package
# cp files to tomcat webapps dir
cp -R target/ldt*/ webapps/ROOT/
