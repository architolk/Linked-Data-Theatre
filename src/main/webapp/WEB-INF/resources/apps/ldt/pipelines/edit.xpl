<!--

    NAME     edit.xpl
    VERSION  1.16.0
    DATE     2017-02-08

    Copyright 2012-2017

    This file is part of the Linked Data Theatre.

    The Linked Data Theatre is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    The Linked Data Theatre is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.

-->
<!--
    DESCRIPTION
    Conceptversion to create the posibility to edit a page (using git)
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
		  xmlns:xforms="http://www.w3.org/2002/xforms"
		  xmlns:xxforms="http://orbeon.org/oxf/xml/xforms"
          xmlns:oxf="http://www.orbeon.com/oxf/processors"
		  xmlns:sparql="http://www.w3.org/2005/sparql-results#"
		  xmlns:ev="http://www.w3.org/2001/xml-events"
		  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		  xmlns:xs="http://www.w3.org/2001/XMLSchema">

	<!-- Configuration> -->
	<p:param type="input" name="instance"/>

	<p:processor name="oxf:httpclient-processor">
		<p:input name="data">
			<input>
				<newFileName>newresource.ttl</newFileName>
				<oldFileName>newresource.ttl</oldFileName>
				<branch>master</branch>
				<path/>
				<message>update</message>
				<charset>UTF-8</charset>
				<lineSeparator>CRLF</lineSeparator>
				<content><![CDATA[<http://test> a <http://testcase>.]]></content>
			</input>
		</p:input>
		<p:input name="config">
			<config>
				<auth-method>form</auth-method>
				<auth-url>http://git.localhost:8080/signin</auth-url>
				<username>root</username>
				<password>root</password>
				<input-type>form</input-type>
				<output-type>text</output-type>
				<url>http://git.localhost:8080/root/test1/update</url>
				<method>post</method>
			</config>
		</p:input>
		<p:output name="data" id="output"/>
	</p:processor>
	
	<p:processor name="oxf:xml-serializer">
		<p:input name="config">
			<config>
			</config>
		</p:input>
		<p:input name="data" href="#output"/>
	</p:processor>
	
</p:config>
