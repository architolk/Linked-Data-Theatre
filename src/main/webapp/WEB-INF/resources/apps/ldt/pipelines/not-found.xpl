<!--

    NAME     not-found.xpl
    VERSION  1.14.0
    DATE     2017-01-04

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
    Default page to show after a 404 not found error
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
		  xmlns:xforms="http://www.w3.org/2002/xforms"
          xmlns:oxf="http://www.orbeon.com/oxf/processors"
		  xmlns:ev="http://www.w3.org/2001/xml-events"
          xmlns:xs="http://www.w3.org/2001/XMLSchema"
		  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!-- Configuration> -->
	<p:param type="input" name="instance"/>
		  
	<!-- Generate original request -->
	<p:processor name="oxf:request">
		<p:input name="config">
			<config stream-type="xs:anyURI">
				<include>/request/headers/header</include>
				<include>/request/request-url</include>
				<include>/request/parameters/parameter</include>
				<include>/request/remote-user</include>
				<include>/request/request-path</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>

	<!-- Config won't be part of the configuration, so explicit loading -->
	<p:processor name="oxf:url-generator">
		<p:input name="config">
			<config>
				<url>../config.xml</url>
				<content-type>application/xml</content-type>
			</config>
		</p:input>
		<p:output name="data" id="defaults"/>
	</p:processor>
	
	<!-- Convert defaults to context -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="aggregate('root',#request,#defaults)"/>
		<p:input name="config" href="../transformations/context.xsl"/>
		<p:output name="data" id="context"/>
	</p:processor>
	

	<!-- Transform error message to HTML -->
	<p:processor name="oxf:identity">
		<p:input name="data">
			<parameters>
					<error-nr>404</error-nr>
			</parameters>
		</p:input>
		<p:output name="data" id="errortext"/>
	</p:processor>
	<p:processor name="oxf:xslt">
		<p:input name="data" href="aggregate('results',#context,#errortext)"/>
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
		<p:output name="data" id="converted" />
	</p:processor>

	<!-- Serialize -->
	<p:processor name="oxf:http-serializer">
		<p:input name="config">
			<config>
				<cache-control><use-local-cache>false</use-local-cache></cache-control>
				<status-code>404</status-code>
			</config>
		</p:input>
		<p:input name="data" href="#converted"/>
	</p:processor>

</p:config>
