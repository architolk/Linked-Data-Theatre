<!--

    NAME     svg2document.xpl
    VERSION  1.8.0
    DATE     2016-06-15

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
	Server-site conversion of svg to pdf or png
	
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

	<!-- Get the posted svg data -->
	<p:processor name="oxf:request">
	  <p:input name="config">
		<config stream-type="xs:anyURI">
		  <include>/request/parameters</include>
		</config>
	  </p:input>
	  <p:output name="data" id="request"/>
	</p:processor>

	<!-- svg variable omzetten naar document zodat je er weer XML van kunt maken -->
    <p:processor name="oxf:xslt">
        <p:input name="data" href="#request"/>
        <p:input name="config" href="../transformations/post2xmldoc.xsl"/>
        <p:output name="data" id="svgdoc"/>
    </p:processor>

	<!-- Converteren naar een XML document -->
	<p:processor name="oxf:to-xml-converter">
		<p:input name="config">
		  <config>
		  </config>
		</p:input>
		<p:input name="data" href="#svgdoc"/>
		<p:output name="data" id="converted"/>
	</p:processor>
	
	<!-- Naar XMLFO omzetten -->
    <p:processor name="oxf:xslt">
        <p:input name="data" href="aggregate('root',#request,#converted)"/>
        <p:input name="config" href="../transformations/svg2fo.xsl"/>
        <p:output name="data" id="fo"/>
    </p:processor>

	<p:processor name="oxf:xmlfo-processor">    
		<p:input name="config" transform="oxf:xslt" href="#request">
			<config xsl:version="2.0">
				<content-type>
					<xsl:choose>
						<xsl:when test="/request/parameters/parameter[name='type']/value='png'">image/png</xsl:when>
						<xsl:otherwise>application/pdf</xsl:otherwise>
					</xsl:choose>
				</content-type>
			</config>
		</p:input>
		<p:input name="data" href="#fo"/>
		<p:output name="data" id="document"/>
	</p:processor>
<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config>
		</config>
	</p:input>
	<p:input name="data" href="#fo"/>
</p:processor>
-->
	<p:processor name="oxf:http-serializer">
	   <p:input name="config" transform="oxf:xslt" href="#request">
			<config xsl:version="2.0">
				<header>
					<name>Content-Disposition</name>
					<value>attachment; filename=graph.<xsl:value-of select="/request/parameters/parameter[name='type']/value"/></value>
				</header>
			</config>
		</p:input>
	   <p:input name="data" href="#document" />
	</p:processor>

</p:config>
