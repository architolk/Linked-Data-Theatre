<!--

    NAME     context.xsl
    VERSION  1.6.3
    DATE     2016-03-29

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
		<xsl:variable name="domain" select="request/headers/header[name='host']/value"/>
		<xsl:variable name="docroot"><xsl:value-of select="theatre/site[@domain=$domain]/@docroot"/></xsl:variable>
		<xsl:variable name="stylesheet"><xsl:value-of select="theatre/site[@domain=$domain]/@css"/></xsl:variable>
		<xsl:variable name="subdomain1" select="substring-after(theatre/subdomain,$docroot)"/>
		<xsl:variable name="subdomain">
			<xsl:if test="matches($subdomain1,'^[^/]')">/</xsl:if>
			<xsl:value-of select="$subdomain1"/>
		</xsl:variable>
		<xsl:variable name="stage" select="theatre/site[@domain=$domain]/stage[not(@name!='') or @name=substring($subdomain,2,string-length(@name))]"/>
		<xsl:variable name="backstage" select="theatre/site[@backstage=$domain]/stage[not(@name!='') or @name=substring($subdomain,2,string-length(@name))]"/>
		<xsl:variable name="config">
			<xsl:choose>
				<xsl:when test="exists($stage)">
					<xsl:text>http://</xsl:text>
					<xsl:value-of select="$domain"/>
					<xsl:if test="$stage[1]/@name!=''">/<xsl:value-of select="$stage[1]/@name"/></xsl:if>
					<xsl:text>/stage</xsl:text>
				</xsl:when>
				<xsl:when test="exists($backstage)">
					<xsl:text>http://</xsl:text>
					<xsl:value-of select="$domain"/>
					<xsl:text>/stage</xsl:text>
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:variable>
		<!-- This variable contains the stage for a particular backstage. Three situations can occur:
			1. The backstage is not defined, the stage is requested. Backstage uses the same domain as the stage;
			2. The backstage is defined, and the backstage is requested
			3. The backstage is defined, and the stage is requested. In this case: the back-of-the-stage should not be available
		-->
		<xsl:variable name="back-of-stage">
			<xsl:if test="exists($backstage)">
				<xsl:text>http://</xsl:text>
				<xsl:value-of select="$backstage/../@domain"/>
				<xsl:if test="$backstage[1]/@name!=''">/<xsl:value-of select="$backstage[1]/@name"/></xsl:if>
				<xsl:text>/stage</xsl:text>
			</xsl:if>
		</xsl:variable>
		
		<context docroot="{$docroot}" version="{version/number}" timestamp="{version/timestamp}" sparql="{theatre/@sparql}">
			<configuration-endpoint><xsl:value-of select="theatre/@configuration-endpoint"/></configuration-endpoint>
			<local-endpoint>
				<xsl:choose>
					<xsl:when test="theatre/site[@domain=$domain]/@site-endpoint!=''"><xsl:value-of select="theatre/site[@domain=$domain]/@site-endpoint"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="theatre/@local-endpoint"/></xsl:otherwise>
				</xsl:choose>
			</local-endpoint>
			<url><xsl:value-of select="request/request-url"/></url>
			<domain><xsl:value-of select="$domain"/></domain>
			<subdomain><xsl:value-of select="$subdomain"/></subdomain>
			<query><xsl:value-of select="theatre/query"/></query>
			<representation-graph uri="{$config}"/>
			<back-of-stage><xsl:value-of select="$back-of-stage"/></back-of-stage>
			<language><xsl:value-of select="substring(request/headers/header[name='accept-language']/value,1,2)"/></language>
			<user><xsl:value-of select="request/remote-user"/></user>
			<user-role><xsl:value-of select="request-security/role"/></user-role>
			<representation><xsl:value-of select="theatre/representation"/></representation>
			<xsl:if test="$stylesheet!=''"><stylesheet href="{$docroot}/css/{$stylesheet}"/></xsl:if>
			<format>
				<xsl:choose>
					<xsl:when test="theatre/format='graphml'">application/graphml+xml</xsl:when> <!-- No specific mime-type is available for graphml, this seems the most logical -->
					<xsl:when test="theatre/format='yed'">application/x.elmo.yed</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="theatre/format='exml'">application/xml</xsl:when> <!-- Full XML, all resultsets -->
					<xsl:when test="theatre/format='xml'">application/rdf+xml</xsl:when> <!-- Only first resultset, like ttl and json -->
					<xsl:when test="theatre/format='txt'">text/plain</xsl:when>
					<xsl:when test="theatre/format='ttl'">text/turtle</xsl:when>
					<xsl:when test="theatre/format='json'">application/json</xsl:when>
					<xsl:when test="theatre/format='xlsx'">application/vnd.openxmlformats-officedocument.spreadsheetml.sheet</xsl:when>
					<xsl:when test="theatre/format='docx'">application/vnd.openxmlformats-officedocument.wordprocessingml.document</xsl:when>
					<xsl:when test="theatre/format='xmi'">application/vnd.xmi+xml</xsl:when>
					<xsl:when test="theatre/format='svgi'">application/x.elmo.svg+xml</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="theatre/format='d3json'">application/x.elmo.d3+json</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="theatre/format='query'">application/x.elmo.query</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="theatre/format='rdfa'">application/x.elmo.rdfa</xsl:when> <!-- Application specific mime-type -->
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
					<xsl:when test="theatre/subject!=''"><xsl:value-of select="theatre/subject"/></xsl:when>
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
