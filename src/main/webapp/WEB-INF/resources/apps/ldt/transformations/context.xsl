<!--

    NAME     context.xsl
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
	Generates the context, used in the info.xpl, version.xpl, query.xpl, sparql.xpl and container.xpl pipelines

-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>

	<xsl:template match="/root|/croot">
		<xsl:variable name="uri-filter">[^a-zA-Z0-9:\.\-_~/()#&amp;=,]</xsl:variable> <!-- ampersand and equal-sign added for Juriconnect -->
		<xsl:variable name="x-forwarded-host"><xsl:value-of select="replace(request/headers/header[name='x-forwarded-host']/value,'^([^,]+).*$','$1')"/></xsl:variable>
		<xsl:variable name="domain">
			<xsl:value-of select="$x-forwarded-host"/> <!-- Use original hostname in case of proxy, first one in case of multiple proxies -->
			<xsl:if test="$x-forwarded-host=''"><xsl:value-of select="request/headers/header[name='host']/value"/></xsl:if>
		</xsl:variable>
		<!-- docroot is defined as the root that MUST be included after the domain. -->
		<xsl:variable name="docroot"><xsl:value-of select="theatre/site[@domain=$domain]/@docroot"/></xsl:variable>
		<!-- staticroot is defined as the root that MUST be included, but only for static content. Is made the same as the docroot, but can be explicitly set -->
		<xsl:variable name="staticroot">
			<xsl:choose>
				<xsl:when test="exists(theatre/site[@domain=$domain]/@staticroot)"><xsl:value-of select="theatre/site[@domain=$domain]/@staticroot"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$docroot"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- Subdomain is the part after the docroot, but if the docroot is not part of the URL (in case of a proxy), the docroot is ignored -->
		<xsl:variable name="subdomain2" select="substring-after(theatre/subdomain,$docroot)"/>
		<xsl:variable name="subdomain1">
			<xsl:value-of select="$subdomain2"/>
			<xsl:if test="not($subdomain2!='')"><xsl:value-of select="theatre/subdomain"/></xsl:if>
		</xsl:variable>
		<xsl:variable name="subdomain">
			<xsl:if test="matches($subdomain1,'^[^/]')">/</xsl:if>
			<xsl:value-of select="$subdomain1"/>
		</xsl:variable>
		<xsl:variable name="url-stage" select="replace($subdomain,'^/([^/]+)','$1')"/>
		<xsl:variable name="stage" select="theatre/site[@domain=$domain]/stage[not(@name!='') or @name=substring($subdomain,2,string-length(@name))][1]"/>
		<xsl:variable name="stylesheet">
			<xsl:choose>
				<xsl:when test="$stage/@css!=''"><xsl:value-of select="$stage/@css"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="theatre/site[@domain=$domain]/@css"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="backstage" select="theatre/site[@backstage=$domain]/stage[not(@name!='') or @name=substring($subdomain,2,string-length(@name))][1]"/>
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

		<!-- URL should be request-url, but in case of proxy we need to replace the host -->
		<xsl:variable name="url-with-domain">
			<xsl:choose>
				<xsl:when test="$x-forwarded-host!=''"><xsl:value-of select="replace(request/request-url,'^([a-z]+://)([^/]+)(.*)',concat('$1',$x-forwarded-host,'$3'))"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="request/request-url"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- In case of a docroot, the url request-path SHOULD start with the docroot, if not: add it -->
		<xsl:variable name="url">
			<xsl:choose>
				<xsl:when test="$docroot=''"><xsl:value-of select="$url-with-domain"/></xsl:when>
				<xsl:when test="matches(request/request-url,concat('^([a-z]+://[^/]+)',$docroot))"><xsl:value-of select="$url-with-domain"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="replace($url-with-domain,'^([a-z]+://[^/]+)(.*)$',concat('$1',$docroot,'$2'))"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="datearray" select="tokenize(theatre/date,'[-/]')"/>
		<xsl:variable name="normalized-date">
			<xsl:if test="$datearray[1]!=''"><xsl:value-of select="format-number(number($datearray[1]),'0000')"/></xsl:if>
			<xsl:if test="$datearray[2]!=''">-<xsl:value-of select="format-number(number($datearray[2]),'00')"/></xsl:if>
			<xsl:if test="$datearray[3]!=''">-<xsl:value-of select="format-number(number($datearray[3]),'00')"/></xsl:if>
			<xsl:if test="$datearray[4]!=''">T<xsl:value-of select="format-number(number($datearray[4]),'00')"/></xsl:if>
			<xsl:if test="$datearray[5]!=''">:<xsl:value-of select="format-number(number($datearray[5]),'00')"/></xsl:if>
			<xsl:if test="$datearray[6]!=''">:<xsl:value-of select="format-number(number($datearray[6]),'00')"/></xsl:if>
			<xsl:if test="$datearray[7]!=''">.<xsl:value-of select="format-number(number($datearray[7]),'000')"/></xsl:if>
		</xsl:variable>
		<xsl:variable name="normal-date">
			<xsl:choose>
				<xsl:when test="matches(theatre/date,'/')"><xsl:value-of select="replace($normalized-date,'[-T:\.]','/')"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="replace($normalized-date,'[T:\.]','-')"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<context env="{theatre/@env}" docroot="{$docroot}" staticroot="{$staticroot}" version="{version/number}" timestamp="{version/timestamp}" sparql="{theatre/@sparql}">
			<configuration-endpoint><xsl:value-of select="theatre/@configuration-endpoint"/></configuration-endpoint>
			<local-endpoint>
				<xsl:choose>
					<xsl:when test="theatre/site[@domain=$domain]/@site-endpoint!=''"><xsl:value-of select="theatre/site[@domain=$domain]/@site-endpoint"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="theatre/@local-endpoint"/></xsl:otherwise>
				</xsl:choose>
			</local-endpoint>
			<title>
				<xsl:choose>
					<xsl:when test="$stage/@title!=''"><xsl:value-of select="$stage/@title"/></xsl:when>
					<xsl:otherwise>Linked Data Theatre</xsl:otherwise>
				</xsl:choose>
			</title>
			<url><xsl:value-of select="$url"/></url>
			<domain><xsl:value-of select="$domain"/></domain>
			<subdomain><xsl:value-of select="$subdomain"/></subdomain>
			<date><xsl:value-of select="$normal-date"/></date>
			<timestamp><xsl:value-of select="$normalized-date"/><xsl:value-of select="substring(string(current-dateTime()),1+string-length($normalized-date),255)"/></timestamp>
			<query><xsl:value-of select="theatre/query"/></query>
			<representation-graph uri="{$config}"/>
			<back-of-stage><xsl:value-of select="$back-of-stage"/></back-of-stage>
			<language><xsl:value-of select="substring(request/headers/header[name='accept-language']/value,1,2)"/></language>
			<user><xsl:value-of select="request/remote-user"/></user>
			<user-role><xsl:value-of select="request-security/role"/></user-role>
			<representation><xsl:value-of select="replace(theatre/representation,$uri-filter,'')"/></representation> <!-- Remove any illegal characters -->
			<xsl:if test="$stylesheet!=''"><stylesheet href="{$staticroot}/css/{$stylesheet}"/></xsl:if>
			<format>
				<xsl:choose>
					<xsl:when test="theatre/format='graphml'">application/graphml+xml</xsl:when> <!-- No specific mime-type is available for graphml, this seems the most logical -->
					<xsl:when test="theatre/format='yed'">application/x.elmo.yed</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="theatre/format='exml'">application/xml</xsl:when> <!-- Full XML, all resultsets -->
					<xsl:when test="theatre/format='xml'">application/rdf+xml</xsl:when> <!-- Only first resultset, like ttl and json -->
					<xsl:when test="theatre/format='rdf'">application/rdf+xml</xsl:when>
					<xsl:when test="theatre/format='sparql'">application/sparql-results+xml</xsl:when>
					<xsl:when test="theatre/format='txt'">text/plain</xsl:when>
					<xsl:when test="theatre/format='csv'">text/csv</xsl:when>
					<xsl:when test="theatre/format='ttl'">text/turtle</xsl:when>
					<xsl:when test="theatre/format='json'">application/json</xsl:when>
					<xsl:when test="theatre/format='jsonld'">application/json</xsl:when>
					<xsl:when test="theatre/format='xlsx'">application/vnd.openxmlformats-officedocument.spreadsheetml.sheet</xsl:when>
					<xsl:when test="theatre/format='docx'">application/vnd.openxmlformats-officedocument.wordprocessingml.document</xsl:when>
					<xsl:when test="theatre/format='pdf'">application/pdf</xsl:when>
					<xsl:when test="theatre/format='xmi'">application/vnd.xmi+xml</xsl:when>
					<xsl:when test="theatre/format='svgi'">application/x.elmo.svg+xml</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="theatre/format='d3json'">application/x.elmo.d3+json</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="theatre/format='query'">application/x.elmo.query</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="theatre/format='rdfa'">application/x.elmo.rdfa</xsl:when> <!-- Application specific mime-type -->
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/sparql-results+xml')">application/sparql-results+xml</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/rdf+xml')">application/rdf+xml</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'text/turtle')">text/turtle</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'text/csv')">text/csv</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/json')">application/json</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/ld+json')">application/json</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')">application/vnd.openxmlformats-officedocument.spreadsheetml.sheet</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/vnd.openxmlformats-officedocument.wordprocessingml.document')">application/vnd.openxmlformats-officedocument.wordprocessingml.document</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/pdf')">application/pdf</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'application/vnd.xmi+xml')">application/vnd.xmi+xml</xsl:when>
					<xsl:when test="contains(request/headers/header[name='accept']/value,'text/html')">text/html</xsl:when>
					<xsl:otherwise>text/html</xsl:otherwise> <!-- If all fails: simply html -->
				</xsl:choose>
			</format>
			<subject>
				<xsl:choose>
					<!-- For security reasons, subject of a container should ALWAYS be the same as the request-url -->
					<xsl:when test="exists(/croot)"><xsl:value-of select="$url"/></xsl:when>
					<!-- Subject URL available in subject parameter -->
					<!-- Remove any illegal characters from URI -->
					<xsl:when test="theatre/subject!=''"><xsl:value-of select="replace(theatre/subject,$uri-filter,'')"/></xsl:when>
					<!-- Dereferenceable URI, /doc/ to /id/ redirect -->
					<xsl:when test="substring-before($url,'/doc/')!=''">
						<xsl:variable name="domain" select="substring-before($url,'/doc/')"/>
						<xsl:variable name="term" select="substring-after($url,'/doc/')"/>
						<xsl:value-of select="$domain"/>/id/<xsl:value-of select="$term"/>
					</xsl:when>
					<!-- Special case: /context/ to /def/ redirect -->
					<xsl:when test="substring-before($url,'/context/')!=''">
						<xsl:variable name="domain" select="substring-before($url,'/context/')"/>
						<xsl:variable name="term" select="substring-after($url,'/context/')"/>
						<xsl:value-of select="$domain"/>
						<xsl:text>/def/</xsl:text>
						<xsl:choose>
							<xsl:when test="matches($term,'.json$')"><xsl:value-of select="substring-before($term,'.json')"/></xsl:when>
							<xsl:otherwise><xsl:value-of select="$term"/></xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<!-- Query URL's, without a subject parameter should not have a subject -->
					<xsl:when test="substring-before($url,'/query/')!=''"/>
					<!-- Dereferenceable URI, other situations (such as def-URI's) -->
					<xsl:otherwise><xsl:value-of select="$url"/></xsl:otherwise>
				</xsl:choose>
			</subject>
			<parameters>
				<xsl:for-each select="request/parameters/parameter[name!='subject' and name!='format' and name!='representation' and name!='date']">
					<xsl:copy-of select="."/>
				</xsl:for-each>
			</parameters>
			<attributes>
				<xsl:for-each select="request/attributes/attribute[name!='']">
					<xsl:copy-of select="."/>
				</xsl:for-each>
			</attributes>
			<xsl:if test="request/body/@xsi:type='xs:anyURI'">
				<xsl:choose>
					<xsl:when test="request/method='POST'"><upload-file action='insert'><xsl:value-of select="request/body"/></upload-file></xsl:when>
					<xsl:when test="request/method='PUT'"><upload-file action='put'><xsl:value-of select="request/body"/></upload-file></xsl:when>
					<xsl:otherwise/>
				</xsl:choose>
			</xsl:if>
		</context>
	</xsl:template>
</xsl:stylesheet>
