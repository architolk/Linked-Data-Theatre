<!--

    NAME     edit.xpl
    VERSION  1.20.0
    DATE     2018-01-12

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

	<!-- Only in development mode -->
	<p:choose href="#instance">
		<p:when test="theatre/@env='dev'">
		
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
			
		</p:when>
		<p:otherwise>
			<p:processor name="oxf:identity">
				<p:input name="data">
					<parameters>
							<error-nr>404</error-nr>
					</parameters>
				</p:input>
				<p:output name="data" id="errortext"/>
			</p:processor>
			<p:processor name="oxf:xslt">
				<p:input name="data" href="aggregate('results',#errortext)"/>
				<p:input name="config" href="../transformations/error2html.xsl"/>
				<p:output name="data" id="html"/>
			</p:processor>
			<p:processor name="oxf:html-converter">
				<p:input name="config">
					<config>
						<encoding>utf-8</encoding>
						<version>5.0</version>
					</config>
				</p:input>
				<p:input name="data" href="#html"/>
				<p:output name="data" id="htmlres" />
			</p:processor>
			<!-- Serialize -->
			<p:processor name="oxf:http-serializer">
				<p:input name="config">
					<config>
						<cache-control><use-local-cache>false</use-local-cache></cache-control>
						<status-code>404</status-code>
					</config>
				</p:input>
				<p:input name="data" href="#htmlres"/>
			</p:processor>
		</p:otherwise>
	</p:choose>
	
</p:config>
