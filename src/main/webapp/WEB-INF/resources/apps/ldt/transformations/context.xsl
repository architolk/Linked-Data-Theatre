<!--

    NAME     context.xsl
    VERSION  1.5.0
    DATE     2016-01-05

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
  Generates the context, used in the version.xpl, query.xpl and container.xpl pipelines
  
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
	
	<xsl:template match="/root|/croot">
	
		<xsl:variable name="host" select="request/headers/header[name='host']/value"/>
		<xsl:variable name="hostconfig" select="submission/representation-graph[@site=$host]/@uri"/>
		<xsl:variable name="config">
			<xsl:value-of select="$hostconfig"/>
			<xsl:if test="not($hostconfig!='')"><xsl:value-of select="submission/representation-graph[1]/@uri"/></xsl:if>
		</xsl:variable>
		<xsl:variable name="docroot"><xsl:value-of select="submission/representation-graph[@site=$host]/@docroot"/></xsl:variable>
		
		<context docroot="{$docroot}" version="{version/number}" timestamp="{version/timestamp}">
			<configuration-endpoint><xsl:value-of select="submission/@configuration-endpoint"/></configuration-endpoint>
			<local-endpoint><xsl:value-of select="submission/@local-endpoint"/></local-endpoint>
			<url><xsl:value-of select="request/request-url"/></url>
			<domain><xsl:value-of select="$host"/></domain>
			<subdomain><xsl:value-of select="substring-after(submission/subdomain,$docroot)"/></subdomain>
			<query><xsl:value-of select="submission/query"/></query>
			<representation-graph uri="{$config}"/>
			<language><xsl:value-of select="substring(request/headers/header[name='accept-language']/value,1,2)"/></language>
			<user><xsl:value-of select="request/remote-user"/></user>
			<user-role><xsl:value-of select="request-security/role"/></user-role>
			<representation><xsl:value-of select="submission/representation"/></representation>
			<format>
				<xsl:choose>
					<xsl:when test="submission/format='graphml'">application/graphml+xml</xsl:when> <!-- No specific mime-type is available for graphml, this seems the most logical -->
					<xsl:when test="submission/format='yed'">application/x.elmo.yed</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="submission/format='exml'">application/xml</xsl:when> <!-- Full XML, all resultsets -->
					<xsl:when test="submission/format='xml'">application/rdf+xml</xsl:when> <!-- Only first resultset, like ttl and json -->
					<xsl:when test="submission/format='txt'">text/plain</xsl:when>
					<xsl:when test="submission/format='ttl'">text/turtle</xsl:when>
					<xsl:when test="submission/format='json'">application/json</xsl:when>
					<xsl:when test="submission/format='xlsx'">application/vnd.openxmlformats-officedocument.spreadsheetml.sheet</xsl:when>
					<xsl:when test="submission/format='docx'">application/vnd.openxmlformats-officedocument.wordprocessingml.document</xsl:when>
					<xsl:when test="submission/format='xmi'">application/vnd.xmi+xml</xsl:when>
					<xsl:when test="submission/format='svgi'">application/x.elmo.svg+xml</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="submission/format='d3json'">application/x.elmo.d3+json</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="submission/format='query'">application/x.elmo.query</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="submission/format='rdfa'">application/x.elmo.rdfa</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/rdf+xml')">application/rdf+xml</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'text/turtle')">text/turtle</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/json')">application/json</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')">application/vnd.openxmlformats-officedocument.spreadsheetml.sheet</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/vnd.xmi+xml')">application/vnd.xmi+xml</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'text/html')">text/html</xsl:when>
					<xsl:otherwise>text/html</xsl:otherwise> <!-- If all fails: simply html -->
				</xsl:choose>
			</format>
			<subject>
				<xsl:choose>
					<!-- For security reasons, subject of a container should ALWAYS be the same as the request-url -->
					<xsl:when test="exists(/croot)"><xsl:value-of select="request/request-url"/></xsl:when>
					<!-- Subject URL available in subject parameter -->
					<xsl:when test="submission/subject!=''"><xsl:value-of select="submission/subject"/></xsl:when>
					<!-- Dereferenceable URI, /doc/ to /id/ redirect -->
					<xsl:when test="substring-before(request/request-url,'/doc/')!=''">
						<xsl:variable name="domain" select="substring-before(request/request-url,'/doc/')"/>
						<xsl:variable name="term" select="substring-after(request/request-url,'/doc/')"/>
						<xsl:value-of select="$domain"/>/id/<xsl:value-of select="$term"/>
					</xsl:when>
					<!-- Dereferenceable URI, other situations (such as def-URI's) -->
					<xsl:otherwise><xsl:value-of select="request/request-url"/></xsl:otherwise>
				</xsl:choose>
			</subject>
			<parameters>
				<xsl:for-each select="request/parameters/parameter[name!='subject' and name!='format' and name!='representation']">
					<xsl:copy-of select="."/>
				</xsl:for-each>
			</parameters>
		</context>
	</xsl:template>
</xsl:stylesheet>
