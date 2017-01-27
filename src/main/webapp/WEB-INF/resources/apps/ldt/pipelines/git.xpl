<!--

    NAME     git.xpl
    VERSION  1.15.0
    DATE     2017-01-27

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
    Virtual sparql endpoint. This service looks at the query, and distilles the subject-resource from the query.
	The subject-resource is then requested from a git store and returned
	
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
	
	<!-- Translate to file context -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="#instance"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0">
				<xsl:template match="/">
					<xsl:variable name="subject"><xsl:value-of select="replace(theatre/query,'^[^&lt;]*&lt;([^&gt;]*)&gt;[^@]*$','$1')"/></xsl:variable>
					<xsl:variable name="domain"><xsl:value-of select="replace($subject,'^http(s|)://([^/]+).*$','$2')"/></xsl:variable>
					<xsl:variable name="fullpath"><xsl:value-of select="replace($subject,'^http(s|)://([^/]+)(.*)$','$3')"/></xsl:variable>
					<xsl:variable name="path"><xsl:value-of select="replace($fullpath,'[^/]+$','')"/></xsl:variable>
					<filecontext>
						<subject><xsl:value-of select="$subject"/></subject>
						<domain><xsl:value-of select="$domain"/></domain>
						<path><xsl:value-of select="$path"/></path>
						<filename><xsl:value-of select="substring-after($fullpath,$path)"/></filename>
					</filecontext>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="filecontext"/>
	</p:processor>
	
	<!-- Fetch file -->
	<p:processor name="oxf:httpclient-processor">
		<p:input name="config" transform="oxf:xslt" href="#filecontext">
			<config xsl:version="2.0">
				<input-type>text</input-type>
				<output-type>rdf</output-type>
				<url>http://git.localhost:8080/root/<xsl:value-of select="filecontext/domain"/>/raw/master<xsl:value-of select="filecontext/path"/><xsl:value-of select="filecontext/filename"/>.ttl</url>
				<method>get</method>
			</config>
		</p:input>
		<p:output name="data" id="output"/>
	</p:processor>
	
	<!-- Translate triples to sparql result -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="aggregate('root',#filecontext,#output)"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0">
				<xsl:template match="root">
					<xsl:variable name="uri" select="filecontext/subject"/>
					<sparql:sparql>
						<sparql:head>
							<sparql:variable name="p"/>
							<sparql:variable name="o"/>
						</sparql:head>
						<sparql:results distinct="false" ordered="true">
							<xsl:for-each-group select="response/rdf:RDF/rdf:Description[@rdf:about=$uri]" group-by="@rdf:about">
								<xsl:for-each select="current-group()/*">
									<sparql:result>
										<sparql:binding name="p"><sparql:uri><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></sparql:uri></sparql:binding>
										<sparql:binding name="o">
											<xsl:choose>
												<xsl:when test="exists(@rdf:resource)"><sparql:uri><xsl:value-of select="@rdf:resource"/></sparql:uri></xsl:when>
												<xsl:otherwise><sparql:literal><xsl:value-of select="."/></sparql:literal></xsl:otherwise>
											</xsl:choose>
										</sparql:binding>
									</sparql:result>
								</xsl:for-each>
							</xsl:for-each-group>
						</sparql:results>
					</sparql:sparql>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="result"/>
	</p:processor>
	
	<!-- Debugging: store result -->
	<!--
	<p:processor name="oxf:xml-converter">
		<p:input name="config">
			<config>
				<encoding>utf-8</encoding>
			</config>
		</p:input>
		<p:input name="data" href="#result"/>
		<p:output name="data" id="xmldoc"/>
	</p:processor>
	<p:processor name="oxf:file-serializer">
		<p:input name="config">
			<config>
				<scope>session</scope>
			</config>
		</p:input>
		<p:input name="data" href="#xmldoc"/>
		<p:output name="data" id="url-written"/>
	</p:processor>
	-->
	
	<p:processor name="oxf:xml-serializer">
		<p:input name="config">
			<config>
				<content-type>application/sparql-results+xml</content-type>
			</config>
		</p:input>
		<!--<p:input name="data" href="aggregate('root',#url-written,#result)#xpointer(root/sparql:sparql)"/>-->
		<p:input name="data" href="#result"/>
	</p:processor>
	
</p:config>
