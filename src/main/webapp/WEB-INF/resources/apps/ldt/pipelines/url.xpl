<!--

    NAME     url.xpl
    VERSION  1.13.0
    DATE     2016-12-06

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
    Virtual sparql endpoint. This service looks at the query, and distilles the subject-resource from the query.
	The subject-resource is then requested from its original location
	
	Two possible queries are allowed:
	1. SELECT ?s?p?o WHERE {?s rdfs:isDefinedBy <URL>. ?s?p?o} => Show all resources at <URL>
	2. SELECT ?s?p?o WHERE {<URL> ?p ?o} => Show triples at <URL> (deferenced URI)
	
	The first statement is more appropiate for vocabulaires, the latter for simple resources.
	
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
	
	<!-- Parse SPARQL query -->
	<p:processor name="oxf:sparql-parser">
		<p:input name="data" transform="oxf:xslt" href="#instance">
			<sparql xsl:version="2.0"><xsl:value-of select="/theatre/query"/></sparql>
		</p:input>
		<p:output name="data" id="query"/>
	</p:processor>
	
	<!-- Translate to file context -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="#query"/>
		<!--
		<p:input name="config">
			<xsl:stylesheet version="2.0">
				<xsl:template match="/">
					<xsl:variable name="firstsubject"><xsl:value-of select="replace(theatre/query,'^[^&lt;]*&lt;([^&gt;]*)&gt;[^@]*$','$1')"/></xsl:variable>
					<filecontext>
						<type>
							<xsl:choose>
								<xsl:when test="$firstsubject='http://www.w3.org/2000/01/rdf-schema#isDefinedBy'">dataset</xsl:when>
								<xsl:otherwise>resource</xsl:otherwise>
							</xsl:choose>
						</type>
						<subject>
							<xsl:choose>
								<xsl:when test="$firstsubject='http://www.w3.org/2000/01/rdf-schema#isDefinedBy'">
									<xsl:value-of select="replace(substring-after(theatre/query,'&lt;http://www.w3.org/2000/01/rdf-schema#isDefinedBy&gt;'),'^[^&lt;]*&lt;([^&gt;]*)&gt;[^@]*$','$1')"/>
								</xsl:when>
								<xsl:otherwise><xsl:value-of select="$firstsubject"/></xsl:otherwise>
							</xsl:choose>
						</subject>
					</filecontext>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		-->
		<p:input name="config">
			<xsl:stylesheet version="2.0">
				<xsl:template match="/">
					<xsl:variable name="subject">
						<xsl:value-of select="query/group[1]/triple[1]/subject/@uri"/>
						<xsl:value-of select="query/group[1]/graph[1]/group[1]/triple[1]/subject/@uri"/>
					</xsl:variable>
					<xsl:variable name="graph">
						<xsl:value-of select="query/group[1]/graph[1]/@uri"/>
					</xsl:variable>
					<filecontext>
						<type>
							<xsl:choose>
								<xsl:when test="$subject!=''">resource</xsl:when>
								<xsl:otherwise>dataset</xsl:otherwise>
							</xsl:choose>
						</type>
						<graph>
							<xsl:value-of select="$graph"/>
							<xsl:if test="$graph=''"><xsl:value-of select="$subject"/></xsl:if>
						</graph>
						<subject><xsl:value-of select="$subject"/></subject>
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
				<url><xsl:value-of select="filecontext/graph"/></url>
				<method>get</method>
				<accept>application/rdf+xml, text/rdf+n3, text/rdf+ttl, text/rdf+turtle, text/turtle, application/turtle, application/x-turtle, application/xml, */*</accept>
			</config>
		</p:input>
		<p:output name="data" id="output"/>
	</p:processor>

<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config/>
	</p:input>
	<p:input name="data" href="#output"/>
</p:processor>
-->
	
	<!-- Translate triples to sparql result -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="aggregate('root',#filecontext,#output)"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0">
				<xsl:template match="root">
					<xsl:variable name="uri" select="filecontext/subject"/>
					<xsl:variable name="type" select="filecontext/type"/>
					<sparql:sparql>
						<sparql:head>
							<xsl:if test="$type='dataset'"><sparql:variable name="s"/></xsl:if>
							<sparql:variable name="p"/>
							<sparql:variable name="o"/>
						</sparql:head>
						<sparql:results distinct="false" ordered="true">
							<xsl:for-each-group select="response/rdf:RDF/rdf:Description[$type='dataset' or @rdf:about=$uri]" group-by="@rdf:about|@rdf:nodeID">
								<xsl:for-each select="current-group()/*">
									<sparql:result>
										<xsl:if test="$type='dataset'">
											<sparql:binding name="s">
												<xsl:choose>
													<xsl:when test="exists(../@rdf:about)"><sparql:uri><xsl:value-of select="../@rdf:about"/></sparql:uri></xsl:when>
													<xsl:when test="exists(../@rdf:nodeID)"><sparql:uri>urn:bnode:<xsl:value-of select="../@rdf:nodeID"/></sparql:uri></xsl:when>
													<xsl:otherwise />
												</xsl:choose>
											</sparql:binding>
										</xsl:if>
										<sparql:binding name="p">
											<sparql:uri><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></sparql:uri>
										</sparql:binding>
										<sparql:binding name="o">
											<xsl:choose>
												<xsl:when test="exists(@rdf:resource)"><sparql:uri><xsl:value-of select="@rdf:resource"/></sparql:uri></xsl:when>
												<xsl:when test="exists(@rdf:nodeID)"><sparql:uri>urn:bnode:<xsl:value-of select="@rdf:nodeID"/></sparql:uri></xsl:when>
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
	
	<p:processor name="oxf:xml-serializer">
		<p:input name="config">
			<config>
				<content-type>application/sparql-results+xml</content-type>
			</config>
		</p:input>
		<p:input name="data" href="#result"/>
	</p:processor>
	
</p:config>
