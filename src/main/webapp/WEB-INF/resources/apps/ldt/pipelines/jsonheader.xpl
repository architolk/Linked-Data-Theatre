<!--

    NAME     jsonheader.xpl
    VERSION  1.6.0
    DATE     2016-03-13

    Copyright 2012-2016

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
	Debug option to show header information, json style
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
		  xmlns:xforms="http://www.w3.org/2002/xforms"
          xmlns:oxf="http://www.orbeon.com/oxf/processors"
		  xmlns:sparql="http://www.w3.org/2005/sparql-results#"
		  xmlns:ev="http://www.w3.org/2001/xml-events"
		  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		  xmlns:xs="http://www.w3.org/2001/XMLSchema">

	<!-- Configuration> -->
	<p:param type="input" name="instance"/>

	<!-- Header information needed for Cool-URI implementation -->
	<p:processor name="oxf:request">
	  <p:input name="config">
		<config stream-type="xs:anyURI">
		  <include>/request</include>
		</config>
	  </p:input>
	  <p:output name="data" id="request"/>
	</p:processor>

	<!-- Security configuration -->
	<p:processor name="oxf:request-security">
		<p:input name="config">
			<config>
				<role>admin-user</role>
			</config>
		</p:input>
		<p:output name="data" id="security"/>
	</p:processor>
	
	<!-- Transform header to json object-->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="#request"/>
		<p:input name="config" href="../transformations/header2json.xsl"/>
		<p:output name="data" id="json"/>
	</p:processor>
	<!-- Convert XML result to plain text -->
	<p:processor name="oxf:text-converter">
		<p:input name="config">
			<config>
				<encoding>utf-8</encoding>
			</config>
		</p:input>
		<p:input name="data" href="#json" />
		<p:output name="data" id="converted" />
	</p:processor>
	<!-- Serialize -->
	<p:processor name="oxf:http-serializer">
		<p:input name="config">
			<config>
				<cache-control><use-local-cache>false</use-local-cache></cache-control>
			</config>
		</p:input>
		<p:input name="data" href="#converted"/>
	</p:processor>
					
</p:config>
