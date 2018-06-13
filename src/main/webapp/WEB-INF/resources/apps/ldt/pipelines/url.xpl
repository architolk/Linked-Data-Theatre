<!--

    NAME     url.xpl
    VERSION  1.22.0
    DATE     2018-06-13

    Copyright 2012-2018

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
	The subject-resource is then requested from its original location
	
	Two situation are recognized:
	1. SELECT * WHERE {<URL> ?p ?o}
	2. SELECT * WHERE { GRAPH <URL> {?s ?p ?o}}

	The triple selection may be filtered by adding more triple patterns (query is parsed by an in memory ARQ engine)
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
	
	<!-- Services info -->
	<p:processor name="oxf:url-generator">
		<p:input name="config">
			<config>
				<url>../services.xml</url>
				<content-type>application/xml</content-type>
			</config>
		</p:input>
		<p:output name="data" id="services"/>
	</p:processor>

	<!-- Parse SPARQL query -->
	<p:processor name="oxf:sparql-parser">
		<p:input name="data" transform="oxf:xslt" href="#instance">
			<sparql xsl:version="2.0"><xsl:value-of select="/theatre/query"/></sparql>
		</p:input>
		<p:output name="data" id="query"/>
	</p:processor>
	
	<!-- Translate to file context -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="aggregate('root',#instance,#query,#services)"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0">
			<xsl:template match="parameter" mode="replace">
				<xsl:param name="text"/>
				<xsl:variable name="value">
					<xsl:value-of select="encode-for-uri(value[1])"/>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="exists(following-sibling::*[1])">
						<xsl:variable name="service">
							<xsl:apply-templates select="following-sibling::*[1]" mode="replace">
								<xsl:with-param name="text" select="$text"/>
							</xsl:apply-templates>
						</xsl:variable>
						<xsl:value-of select="replace($service,concat('@',upper-case(name),'@'),$value)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="replace($text,concat('@',upper-case(name),'@'),$value)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:template>
			<xsl:template match="/">
					<xsl:variable name="subject">
						<xsl:value-of select="root/query/group[1]/triple[1]/subject/@uri"/>
						<xsl:value-of select="root/query/group[1]/group[1]/triple[1]/subject/@uri"/>
						<xsl:value-of select="root/query/group[1]/graph[1]/group[1]/triple[1]/subject/@uri"/>
					</xsl:variable>
					<xsl:variable name="graph">
						<xsl:value-of select="root/query/group[1]/graph[1]/@uri"/>
					</xsl:variable>
					<xsl:variable name="service-url">
						<xsl:value-of select="$graph"/>
						<xsl:if test="$graph=''"><xsl:value-of select="$subject"/></xsl:if>
					</xsl:variable>
					<filecontext>
						<type>
							<xsl:choose>
								<xsl:when test="$subject!=''">resource</xsl:when>
								<xsl:when test="$graph!=''">dataset</xsl:when>
								<xsl:otherwise>unknown</xsl:otherwise>
							</xsl:choose>
						</type>
						<graph><xsl:value-of select="$service-url"/></graph>
						<subject><xsl:value-of select="$subject"/></subject>
						<query>
							<xsl:choose>
								<xsl:when test="$graph!=''">select * where {<xsl:value-of select="root/query/group[1]/graph[1]"/>}</xsl:when>
								<xsl:otherwise><xsl:value-of select="root/theatre/query"/></xsl:otherwise>
							</xsl:choose>
						</query>
						<xsl:variable name="service" select="root/services/service[@applies-to=$service-url]"/>
						<output>
							<xsl:choose>
								<xsl:when test="$service/@accept='text/plain'">txt</xsl:when>
								<xsl:when test="$service/@accept='application/xml'">xml</xsl:when>
								<xsl:when test="$service/@accept='application/json'">json</xsl:when>
								<xsl:when test="$service/@applies-to!=''">json-ld</xsl:when>
								<xsl:otherwise>rdf</xsl:otherwise>
							</xsl:choose>
						</output>
						<xsl:variable name="params">
							<xsl:for-each select="root/query/group[1]/triple[subject/@uri=$graph]">
								<xsl:variable name="name"><xsl:value-of select="substring-after(predicate/@uri,'#')"/></xsl:variable>
								<xsl:if test="$name!='' and object!=''">
									<parameter>
										<name><xsl:value-of select="$name"/></name>
										<value><xsl:value-of select="object"/></value>
									</parameter>
								</xsl:if>
							</xsl:for-each>
						</xsl:variable>
						<params>
							<xsl:apply-templates select="$params/parameter[1]" mode="replace">
								<xsl:with-param name="text" select="$service/@query"/>
							</xsl:apply-templates>
							<xsl:if test="not(exists($params/parameter))"><xsl:value-of select="$service/@query"/></xsl:if>
						</params>
						<xsl:if test="$service/@translator!=''"><translator><xsl:value-of select="$service/@translator"/></translator></xsl:if>
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
				<output-type><xsl:value-of select="filecontext/output"/></output-type>
				<tidy>yes</tidy> <!-- Tidy output in case of html (html pages on the internet don't always follow the rules...). HTML result should be a valid XML file. tidy does that for us. -->
				<url>
					<xsl:value-of select="filecontext/graph"/>
					<xsl:if test="filecontext/params!=''">?<xsl:value-of select="filecontext/params"/></xsl:if>
				</url>
				<method>get</method>
				<xsl:if test="filecontext/output='rdf'"><accept>application/rdf+xml, text/rdf+n3, text/rdf+ttl, text/rdf+turtle, text/turtle, application/turtle, application/x-turtle, application/xml, */*</accept></xsl:if> <!-- Accept almost anything, but we prefer something RDF -->
			</config>
		</p:input>
		<p:output name="data" id="output"/>
	</p:processor>

	<p:choose href="#filecontext">
		<p:when test="filecontext/translator!=''">
			<p:processor name="oxf:url-generator">
				<p:input name="config" transform="oxf:xslt" href="#filecontext">
					<config xsl:version="2.0">
						<url>../translators/<xsl:value-of select="filecontext/translator"/>.xsl</url>
						<content-type>application/xml</content-type>
					</config>
				</p:input>
				<p:output name="data" id="translator"/>
			</p:processor>
			<!-- Translate -->
			<p:processor name="oxf:xslt">
				<p:input name="config" href="#translator"/>
				<p:input name="data" href="#output"/>
				<p:output name="data" id="rdf"/>
			</p:processor>
			<!-- Process federated query from in memory triplestore -->
			<p:processor name="oxf:sparql-processor">
				<p:input name="config" transform="oxf:xslt" href="#filecontext">
					<sparql xsl:version="2.0"><xsl:value-of select="filecontext/query"/></sparql>
				</p:input>
				<p:input name="data" href="#rdf"/>
				<p:output name="data" id="result"/>
			</p:processor>
		</p:when>
		<p:otherwise>
			<!-- Process federated query from in memory triplestore -->
			<p:processor name="oxf:sparql-processor">
				<p:input name="config" transform="oxf:xslt" href="#filecontext">
					<sparql xsl:version="2.0"><xsl:value-of select="filecontext/query"/></sparql>
				</p:input>
				<p:input name="data" href="#output#xpointer(response/rdf:RDF)"/>
				<p:output name="data" id="result"/>
			</p:processor>
		</p:otherwise>
	</p:choose>
	
<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config/>
	</p:input>
	<p:input name="data" href="#filecontext"/>
</p:processor>
-->
	
	<p:processor name="oxf:xml-serializer">
		<p:input name="config">
			<config>
				<content-type>application/sparql-results+xml</content-type>
			</config>
		</p:input>
		<p:input name="data" href="#result"/>
	</p:processor>
	
</p:config>
