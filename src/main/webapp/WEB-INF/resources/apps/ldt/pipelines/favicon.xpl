<!--

    NAME     favicon.xpl
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
	Pipeline to show the correct favicon
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
		  xmlns:xforms="http://www.w3.org/2002/xforms"
          xmlns:oxf="http://www.orbeon.com/oxf/processors"
		  xmlns:ev="http://www.w3.org/2001/xml-events"
		  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!-- Configuration> -->
	<p:param type="input" name="instance"/>

	<!-- Generate original request -->
	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request/headers/header</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>

	<!-- Get icon name -->
	<p:processor name="oxf:xslt">
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
				<xsl:template match="/root">
					<xsl:variable name="host" select="request/headers/header[name='host']/value"/>
					<xsl:variable name="hosticon"><xsl:value-of select="theatre/site[@domain=$host]/@icon"/></xsl:variable>
					<icon>
						<xsl:value-of select="$hosticon"/>
						<xsl:if test="$hosticon=''">favicon.ico</xsl:if>
					</icon>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:input name="data" href="aggregate('root',#instance,#request)"/>
		<p:output name="data" id="icon"/>
	</p:processor>

<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config/>
	</p:input>
	<p:input name="data" href="#icon"/>
</p:processor>
-->

	<p:processor name="oxf:url-generator">
		<p:input name="config" transform="oxf:xslt" href="#icon">
			<config xsl:version="2.0">
				<url>../../images/<xsl:value-of select="icon"/></url>
				<mode>binary</mode>
			</config>
		</p:input>
		<p:output name="data" id="favicon"/>
	</p:processor>

	<!-- Serialize -->
	<p:processor name="oxf:http-serializer">
		<p:input name="config">
			<config>
				<content-type>image/vnd.microsoft.icon</content-type>
				<force-content-type>true</force-content-type>
			</config>
		</p:input>
		<p:input name="data" href="#favicon"/>
	</p:processor>

</p:config>
