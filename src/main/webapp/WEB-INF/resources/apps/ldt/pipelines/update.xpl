<!--

    NAME     update.xpl
    VERSION  1.16.0
    DATE     2017-02-08

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
    Pipeline to manage the production of new data, using sparql-update protocol

-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
		  xmlns:xforms="http://www.w3.org/2002/xforms"
          xmlns:oxf="http://www.orbeon.com/oxf/processors"
		  xmlns:sparql="http://www.w3.org/2005/sparql-results#"
		  xmlns:ev="http://www.w3.org/2001/xml-events"
		  xmlns:xxforms="http://orbeon.org/oxf/xml/xforms"
		  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		  xmlns:sql="http://orbeon.org/oxf/xml/sql"
		  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		  xmlns:elmo="http://bp4mc2.org/elmo/def#"
		  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
		  xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
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
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>

	<!-- To have access, you need to be an editor -->
	<p:processor name="oxf:request-security">
		<p:input name="config">        
			<config>
				<role>editor</role>
			</config>    
		</p:input>
		<p:output name="data" id="roles"/>
	</p:processor>
	
	<!-- Create context -->
	<p:processor name="oxf:unsafe-xslt">
		<p:input name="data" href="aggregate('croot',#instance,#request,#roles)"/>
		<p:input name="config" href="../transformations/context.xsl"/>
		<p:output name="data" id="context"/>
	</p:processor>

	<!-- Look for production definition in configuration -->
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
						<]]><xsl:value-of select="context/subject"/><![CDATA[> rdf:type ?type.
						<]]><xsl:value-of select="context/subject"/><![CDATA[> ?p ?s.
						?s ?sp ?so.
						?so ?sop ?soo.
						?soo ?soop ?sooo.
					}
					WHERE {
						GRAPH <]]><xsl:value-of select="context/representation-graph/@uri"/><![CDATA[> {
							<]]><xsl:value-of select="context/subject"/><![CDATA[> rdf:type ?type.
							<]]><xsl:value-of select="context/subject"/><![CDATA[> ?p ?s.
							FILTER (?type = elmo:Production)
							OPTIONAL {
								?s ?sp ?so.
								OPTIONAL {
									?so ?sop ?soo
									OPTIONAL {
										?soo ?soop ?sooo
									}
								}
							}
						}
					}
				]]>
				</query>
				<default-graph-uri/>
				<error type=""/>
			</parameters>
		</p:input>
		<p:output name="response" id="defquery"/>
	</p:processor>
	
	<!-- Query from graph representation -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="aggregate('root',#defquery,#context)"/>
		<p:input name="config" href="../transformations/rdf2view.xsl"/>
		<p:output name="data" id="querytext"/>
	</p:processor>
<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config/>
	</p:input>
	<p:input name="data" href="#defquery"/>
</p:processor>
-->
	<p:for-each href="#querytext" select="/view/(scene|representation)" root="results" id="sparql">
	
		<p:choose href="current()">
			<!-- queryForm constraint not satisfied, so query won't succeed: show form -->
			<p:when test="representation/queryForm/@satisfied!=''">
				<p:processor name="oxf:identity">
					<p:input name="data">
						<rdf:RDF/>
					</p:input>
					<p:output name="data" ref="sparql"/>
				</p:processor>
			</p:when>
			<p:otherwise>
				<!-- Create sparql update request -->
				<!-- TODO: Refactor: borrowed from query.xpl -->
				<p:processor name="oxf:xslt">
					<p:input name="config">
						<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
							<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
							<xsl:template match="parameter" mode="replace">
								<!-- Escape characters that could be used for SPARQL insertion -->
								<!-- The solution is quite harsh: all ', ", <, > and \ are deleted -->
								<!-- A better solution could be to know if a parameter is a literal or a URI -->
								<xsl:variable name="problems">("|'|&lt;|&gt;|\\|\$)</xsl:variable>
								<xsl:variable name="value">
									<xsl:value-of select="replace(value[1],$problems,'')"/>
								</xsl:variable>
								<xsl:choose>
									<xsl:when test="exists(following-sibling::*[1])">
										<xsl:variable name="query"><xsl:apply-templates select="following-sibling::*[1]" mode="replace"/></xsl:variable>
										<xsl:value-of select="replace($query,concat('@',upper-case(name),'@'),$value)"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="replace(/root/(scene|representation)/query,concat('@',upper-case(name),'@'),$value)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:template>
							<xsl:template match="/root">
								<parameters>
									<xsl:variable name="query1">
										<xsl:apply-templates select="/root/parameters/parameter[1]" mode="replace"/>
										<xsl:if test="not(exists(/root/parameters/parameter))"><xsl:value-of select="/root/(scene|representation)/query"/></xsl:if>
									</xsl:variable>
									<xsl:variable name="query2" select="replace($query1,'@LANGUAGE@',/root/context/language)"/>
									<xsl:variable name="query3" select="replace($query2,'@USER@',/root/context/user)"/>
									<xsl:variable name="query4" select="replace($query3,'@CURRENTMOMENT@',string(current-dateTime()))"/>
									<xsl:variable name="query5" select="replace($query4,'@STAGE@',/root/context/back-of-stage)"/>
									<xsl:variable name="query6" select="replace($query5,'@TIMESTAMP@',/root/context/timestamp)"/>
									<xsl:variable name="query7" select="replace($query6,'@DATE@',/root/context/date)"/>
									<query><xsl:value-of select="replace($query7,'@SUBJECT@',/root/context/subject)"/></query>
									<default-graph-uri />
									<error type=""/>
								</parameters>
							</xsl:template>
						</xsl:stylesheet>
					</p:input>
					<p:input name="data" href="aggregate('root',current(),#context,#context#xpointer(context/parameters))"/>
					<p:output name="data" id="query"/>
				</p:processor>
				
				<!-- Get endpoint -->
				<p:processor name="oxf:xslt">
					<p:input name="config">
						<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
							<xsl:template match="/root">
								<xsl:variable name="endpoint">
									<xsl:value-of select="(scene|representation)/@endpoint"/>
									<xsl:if test="not((scene|representation)/@endpoint!='')"><xsl:value-of select="context/local-endpoint"/></xsl:if>
								</xsl:variable>
								<endpoint>
									<url><xsl:value-of select="$endpoint"/></url>
									<xsl:for-each select="theatre/endpoint[@url=$endpoint]">
										<xsl:if test="exists(username)"><username><xsl:value-of select="username"/></username></xsl:if>
										<xsl:if test="exists(password)"><password><xsl:value-of select="password"/></password></xsl:if>
									</xsl:for-each>
								</endpoint>
							</xsl:template>
						</xsl:stylesheet>
					</p:input>
					<p:input name="data" href="aggregate('root',current(),#context,#instance)"/>
					<p:output name="data" id="endpoint"/>
				</p:processor>

				<!-- Execute SPARQL statement -->
				<!-- BIG problem: all namespaces that result in a digit as the first character of a local-name are ignored!!! -->
				<!-- No simple solution available :-( :-( :-( -->
				<p:processor name="oxf:xforms-submission">
					<p:input name="submission" transform="oxf:xslt" href="#endpoint">
						<xforms:submission method="post" xsl:version="2.0" action="{endpoint/url}" serialization="application/x-www-form-urlencoded">
							<xsl:if test="endpoint/username!=''"><xsl:attribute name="xxforms:username"><xsl:value-of select="endpoint/username"/></xsl:attribute></xsl:if>
							<xsl:if test="endpoint/password!=''"><xsl:attribute name="xxforms:password"><xsl:value-of select="endpoint/password"/></xsl:attribute></xsl:if>
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
					<p:input name="request" href="#query"/>
					<p:output name="response" id="sparqlres"/>
				</p:processor>
				<!-- Transform SPARQL to RDF -->
				<p:processor name="oxf:xslt">
					<p:input name="data" href="aggregate('root',#context,current(),#sparqlres)"/>
					<p:input name="config" href="../transformations/sparql2rdfa.xsl"/>
					<p:output name="data" ref="sparql"/>
				</p:processor>
			</p:otherwise>
		</p:choose>
	
	</p:for-each>

	<!-- Transform to annotated rdf -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="aggregate('root',#context,#querytext,#sparql)"/>
		<p:input name="config" href="../transformations/rdf2rdfa.xsl"/>
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

	<p:choose href="#sparql">
		<!-- Check for errors -->
		<p:when test="exists(results/parameters/error)">
			<!-- Transform error message to HTML -->
			<p:processor name="oxf:xslt">
				<p:input name="data" href="#sparql"/>
				<p:input name="config" href="../transformations/error2html.xsl"/>
				<p:output name="data" id="html"/>
			</p:processor>
			<!-- Convert XML result to HTML -->
			<p:processor name="oxf:html-converter">
				<p:input name="config">
					<config>
						<encoding>utf-8</encoding>
						<version>5.0</version>
					</config>
				</p:input>
				<p:input name="data" href="#html" />
				<p:output name="data" id="converted" />
			</p:processor>
			<!-- Serialize -->
			<p:processor name="oxf:http-serializer">
				<p:input name="config">
					<config>
						<cache-control><use-local-cache>false</use-local-cache></cache-control>
						<status-code>200</status-code>
					</config>
				</p:input>
				<p:input name="data" href="#converted"/>
			</p:processor>
		</p:when>
		<p:otherwise>
			<!-- Transform -->
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="data" href="#rdfa"/>
				<p:input name="config" href="../transformations/rdf2html.xsl"/>
				<p:output name="data" id="html"/>
			</p:processor>
			<!-- Convert XML result to HTML -->
			<p:processor name="oxf:html-converter">
				<p:input name="config">
					<config>
						<encoding>utf-8</encoding>
						<version>5.0</version>
					</config>
				</p:input>
				<p:input name="data" href="#html" />
				<p:output name="data" id="converted" />
			</p:processor>
			<!-- Serialize -->
			<p:processor name="oxf:http-serializer">
				<p:input name="config">
					<config>
						<cache-control><use-local-cache>false</use-local-cache></cache-control>
					</config>
				</p:input>
				<p:input name="data" href="#converted"/>
			</p:processor>
		</p:otherwise>
	</p:choose>
	
</p:config>
