#!/usr/bin/env bash
#
# NAME     create_tomcat_admin_user.sh
# VERSION  1.6.0
# DATE     2016-03-13
#
# Copyright 2012-2016
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


if [ -f /.tomcat_admin_created ]; then
    echo "Tomcat 'admin' user already created"
    exit 0
fi

#generate password
PASS=${TOMCAT_PASS:-$(pwgen -s 12 1)}
_word=$( [ ${TOMCAT_PASS} ] && echo "preset" || echo "random" )

echo "=> Creating and admin user with a ${_word} password in Tomcat"
sed -i -r 's/<\/tomcat-users>//' ${CATALINA_HOME}/conf/tomcat-users.xml
echo '<role rolename="manager-gui"/>' >> ${CATALINA_HOME}/conf/tomcat-users.xml
echo '<role rolename="manager-script"/>' >> ${CATALINA_HOME}/conf/tomcat-users.xml
echo '<role rolename="manager-jmx"/>' >> ${CATALINA_HOME}/conf/tomcat-users.xml
echo '<role rolename="admin-gui"/>' >> ${CATALINA_HOME}/conf/tomcat-users.xml
echo '<role rolename="admin-script"/>' >> ${CATALINA_HOME}/conf/tomcat-users.xml
echo "<user username=\"admin\" password=\"${PASS}\" roles=\"manager-gui,manager-script,manager-jmx,admin-gui, admin-script\"/>" >> ${CATALINA_HOME}/conf/tomcat-users.xml
echo '</tomcat-users>' >> ${CATALINA_HOME}/conf/tomcat-users.xml 
echo "=> Done!"
touch /.tomcat_admin_created

echo "========================================================================"
echo "You can now configure to this Tomcat server using:"
echo ""
echo "    admin:${PASS}"
echo ""
echo "========================================================================"
