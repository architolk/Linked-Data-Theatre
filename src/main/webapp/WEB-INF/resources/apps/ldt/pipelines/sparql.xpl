<!--

    NAME     sparql.xpl
    VERSION  1.8.1-SNAPSHOT
    DATE     2016-06-21

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
    Pipeline to facilitate sparql query
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
		  xmlns:xforms="http://www.w3.org/2002/xforms"
          xmlns:oxf="http://www.orbeon.com/oxf/processors"
		  xmlns:sparql="http://www.w3.org/2005/sparql-results#"
		  xmlns:ev="http://www.w3.org/2001/xml-events"
		  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		  xmlns:sql="http://orbeon.org/oxf/xml/sql"
		  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		  xmlns:elmo="http://bp4mc2.org/elmo/def#"
		  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
		  xmlns:xs="http://www.w3.org/2001/XMLSchema">

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

	<!-- Get credentials and user roles -->
	<p:processor name="oxf:request-security">
		<p:input name="config" transform="oxf:xslt" href="#instance">        
			<config xsl:version="2.0">
				<xsl:for-each select="theatre/roles/role">
					<role><xsl:value-of select="."/></role>
				</xsl:for-each>
			</config>    
		</p:input>
		<p:output name="data" id="roles"/>
	</p:processor>	
	
	<!-- Create context -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="aggregate('croot',#instance,#request,#roles)"/>
		<p:input name="config" href="../transformations/context.xsl"/>
		<p:output name="data" id="context"/>
	</p:processor>

	<p:choose href="#context">
		<!--backstage should be available, or else - show 404 -->
		<p:when test="(context/back-of-stage!='' and matches(context/url,'backstage/sparql$')) or (context/@sparql='yes' and matches(context/url,'/sparql$'))">
	
			<p:choose href="#context">
				<p:when test="context/parameters/parameter[name='query']/value!=''">
					<p:processor name="oxf:xforms-submission">
						<p:input name="submission" transform="oxf:xslt" href="#context">
							<xforms:submission method="get" xsl:version="2.0" action="{context/local-endpoint}">
								<xforms:header>
									<xforms:name>Accept</xforms:name>
									<xforms:value>application/sparql-results+xml</xforms:value>
								</xforms:header>
								<xforms:header>
									<xforms:name>Accept</xforms:name>
									<xforms:value>application/rdf+xml</xforms:value>
								</xforms:header>
								<xforms:setvalue ev:event="xforms-submit-error" ref="error" value="event('response-body')"/>
								<xforms:setvalue ev:event="xforms-submit-error" ref="error/@type" value="event('error-type')"/>
							</xforms:submission>
						</p:input>
						<p:input name="request" transform="oxf:xslt" href="#context">
							<parameters xsl:version="2.0">
								<query><xsl:value-of select="context/parameters/parameter[name='query']/value"/></query>
								<default-graph-uri/>
								<error type=""/>
							</parameters>
						</p:input>
						<p:output name="response" id="sparql"/>
					</p:processor>
				</p:when>
				<p:otherwise>
					<p:processor name="oxf:identity">
						<p:input name="data">
							<rdf:RDF />
						</p:input>
						<p:output name="data" id="sparql"/>
					</p:processor>
				</p:otherwise>
			</p:choose>
			
			<p:choose href="#context">
				<!-- XML -->
				<p:when test="context/format='application/xml'">
					<p:processor name="oxf:xml-serializer">
						<p:input name="config">
							<config/>
						</p:input>
						<p:input name="data" href="#sparql"/>
					</p:processor>
				</p:when>
				<!-- XLSX -->
				<p:when test="context/format='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'">
					<!-- Convert sparql to rdfa -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="aggregate('root',#sparql,#context)"/>
						<p:input name="config" href="../transformations/sparql2rdfa.xsl"/>
						<p:output name="data" id="rdfa"/>
					</p:processor>
					<!-- Transform -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="aggregate('results',#rdfa)"/>
						<p:input name="config" href="../transformations/rdf2xls.xsl"/>
						<p:output name="data" id="xlsxml"/>
					</p:processor>
					<!-- Serialize -->
					<p:processor name="oxf:excel-serializer">
						<p:input name="config">
							<config>
								<content-type>application/vnd.openxmlformats-officedocument.spreadsheetml.sheet</content-type>
								<header>
									<name>Content-Disposition</name>
									<value>attachment; filename=result.xlsx</value>
								</header>
							</config>
						</p:input>
						<p:input name="data" href="#xlsxml"/>
					</p:processor>
				</p:when>
				<p:otherwise>
					<!-- Get possible examples queries -->
					<p:processor name="oxf:xforms-submission">
						<p:input name="submission" transform="oxf:xslt" href="#context">
							<xforms:submission method="get" xsl:version="2.0" action="{context/configuration-endpoint}">
								<xforms:header>
									<xforms:name>Accept</xforms:name>
									<xforms:value>application/rdf+xml</xforms:value>
								</xforms:header>
								<xforms:setvalue ev:event="xforms-submit-error" ref="error" value="event('response-body')"/>
								<xforms:setvalue ev:event="xforms-submit-error" ref="error/@type" value="event('error-type')"/>
							</xforms:submission>
						</p:input>
						<p:input name="request" transform="oxf:xslt" href="#context">
							<parameters xsl:version="2.0">
								<query>
								<![CDATA[
									PREFIX elmo: <http://bp4mc2.org/elmo/def#>
									CONSTRUCT {
										?q rdfs:label ?qlabel.
										?q rdf:value ?query
									}
									WHERE {
										GRAPH <]]><xsl:value-of select="context/representation-graph/@uri"/><![CDATA[> {
											?q rdf:type elmo:Query.
											?q rdfs:label ?qlabel.
											?q elmo:query ?query
										}
									}
								]]>
								</query>
								<default-graph-uri/>
								<error type=""/>
							</parameters>
						</p:input>
						<p:output name="response" id="queries"/>
					</p:processor>
					<!-- Get predefined representation from LDT for SPARQL endpoint -->
					<p:processor name="oxf:url-generator">
						<p:input name="config" transform="oxf:xslt" href="#context">
							<config xsl:version="2.0">
								<url>../representations/SPARQLRepresentation.xml</url>
								<content-type>application/xml</content-type>
							</config>
						</p:input>
						<p:output name="data" id="sparqlrep"/>
					</p:processor>
					<!-- Convert sparql to rdfa -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="aggregate('root',#sparql,#context,aggregate('representation',#sparqlrep),aggregate('queries',#queries))"/>
						<p:input name="config" href="../transformations/sparql2rdfaform.xsl"/>
						<p:output name="data" id="rdfa"/>
					</p:processor>
<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config/>
	</p:input>
	<p:input name="data" href="#rdfa"/>
</p:processor>
-->
					<!-- Transform rdfa to html -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#rdfa"/>
						<p:input name="config" href="../transformations/rdf2html.xsl"/>
						<p:output name="data" id="html"/>
					</p:processor>
					<!-- Convert XML result to HTML -->
					<p:processor name="oxf:html-converter">
						<p:input name="config">
							<config>
								<encoding>utf-8</encoding>
								<public-doctype>-//W3C//DTD XHTML 1.0 Strict//EN</public-doctype>
							</config>
						</p:input>
						<p:input name="data" href="#html" />
						<p:output name="data" id="htmlres" />
					</p:processor>
					<!-- Serialize -->
					<p:processor name="oxf:http-serializer">
						<p:input name="config">
							<config>
								<cache-control><use-local-cache>false</use-local-cache></cache-control>
							</config>
						</p:input>
						<p:input name="data" href="#htmlres"/>
					</p:processor>
				</p:otherwise>
			</p:choose>
	
		</p:when>
		<p:otherwise>
			<!-- Container doesn't exist in definition: 404 return code -->
			<p:processor name="oxf:xslt">
				<p:input name="data">
					<results>
						<parameters>
							<error>Het antwoord op uw verzoek kan niet worden gevonden.</error>
						</parameters>
					</results>
				</p:input>
				<p:input name="config" href="../transformations/error2html.xsl"/>
				<p:output name="data" id="html"/>
			</p:processor>
			<p:processor name="oxf:html-converter">
				<p:input name="config">
					<config>
						<encoding>utf-8</encoding>
						<public-doctype>-//W3C//DTD XHTML 1.0 Strict//EN</public-doctype>
					</config>
				</p:input>
				<p:input name="data" href="#html"/>
				<p:output name="data" id="htmlres" />
			</p:processor>
			<!-- Serialize -->
			<p:processor name="oxf:http-serializer">
				<p:input name="config">
					<config>
						<cache-control><use-local-cache>false</use-local-cache></cache-control>
						<status-code>404</status-code>
					</config>
				</p:input>
				<p:input name="data" href="#htmlres"/>
			</p:processor>
		</p:otherwise>
	</p:choose>
	
</p:config>
