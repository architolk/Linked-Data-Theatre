<!--

    NAME     conversion.xpl
    VERSION  1.17.0
    DATE     2017-04-16

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
    Pipeline to manage the conversion of an RDB datasource to Linked Data

	Both asynchronous and synchronous execution is supported. Please look at line 209
	Asynchronous execution will not return any error codes, just "in progress".
	Upload will be part of the RDB2RDF processor in case of asynchronous execution, just the same as the oxf:sql execution
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

	<!-- Look for conversion definition in configuration -->
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
							FILTER (?type = elmo:Conversion)
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
		<p:output name="response" id="conversion"/>
	</p:processor>
	
	<!-- Separate configuration from triplemaps -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="#conversion"/>
		<p:input name="config" href="../transformations/rdf2config.xsl"/>
		<p:output name="data" id="results"/>
	</p:processor>

	<!-- Check if a conversion exists, fail if not -->
	<p:choose href="#results">
		<p:when test="exists(results/conversion)">
	
			<!-- Morph RDB excepts only turtle r2rml configurations, so transform to ttl -->
			<p:processor name="oxf:xslt">
				<p:input name="data" href="#results"/>
				<p:input name="config" href="../transformations/rdf2ttl.xsl"/>
				<p:output name="data" id="ttl"/>
			</p:processor>

			<!-- Save to disk -->
			<p:processor name="oxf:text-converter">
				<p:input name="config">
					<config/>
				</p:input>
				<p:input name="data" href="#ttl"/>
				<p:output name="data" id="ttldoc"/>
			</p:processor>
			<p:choose href="#instance">
				<p:when test="exists(submission/@tempdir)">
					<p:processor name="oxf:unsafe-xslt">
						<p:input name="config">
							<xsl:stylesheet version="2.0">
								<xsl:template match="/">
									<xsl:variable name="uuid" xmlns:uuid="java.util.UUID" select="uuid:randomUUID()"/>
									<url>file:/<xsl:value-of select="submission/@tempdir"/>/<xsl:value-of select="$uuid"/>.tmp</url>
								</xsl:template>
							</xsl:stylesheet>
						</p:input>
						<p:input name="data" href="#instance"/>
						<p:output name="data" id="filename"/>
					</p:processor>
					<p:processor name="oxf:file-serializer">
						<p:input name="data" href="#ttldoc"/>
						<p:input name="config" transform="oxf:xslt" href="#filename">
							<config xsl:version="2.0">
								<url><xsl:value-of select="url"/></url>
								<make-directories>true</make-directories>
								<append>false</append>
							</config>
						</p:input>
					</p:processor>
					<p:processor name="oxf:identity">
						<p:input name="data" href="#filename"/>
						<p:output name="data" id="ttlfile"/>
					</p:processor>
				</p:when>
				<p:otherwise>
					<p:processor name="oxf:file-serializer">
						<p:input name="data" href="#ttldoc"/>
						<p:input name="config">
							<config>
								<scope>session</scope>
							</config>
						</p:input>
						<p:output name="data" id="ttlfile"/>
					</p:processor>
				</p:otherwise>
			</p:choose>

			<!-- Start working on the conversion -->
			<p:processor name="oxf:rdb2rdf-processor">
				<p:input name="config" transform="oxf:xslt" href="aggregate('root',#ttlfile,#results)">
					<config xsl:version="2.0">
						<mappingDocument><xsl:value-of select="substring-after(root/url,'file:/')"/></mappingDocument>
						<outputFile><xsl:value-of select="substring-after(root/url,'file:/')"/>_</outputFile>
						<database><xsl:value-of select="root/results/config/database"/></database>
						<driver><xsl:value-of select="root/results/config/driver"/></driver>
						<url><xsl:value-of select="root/results/config/url"/></url>
						<user><xsl:value-of select="root/results/config/user"/></user>
						<password><xsl:value-of select="root/results/config/password"/></password>
						<type><xsl:value-of select="root/results/config/type"/></type>
						<uriEncode><xsl:value-of select="root/results/config/uriEncode"/></uriEncode>
						<uriTransform><xsl:value-of select="root/results/config/uriTransform"/></uriTransform>
						<mode>synchronous</mode> <!-- asynchronous or synchronous -->
						<graph><xsl:value-of select="root/results/graph"/></graph>
					</config>
				</p:input>
				<p:output name="data" id="output"/>
			</p:processor>
			
			<!-- Check if conversion is succesfull -->
			<p:choose href="#output">
				<p:when test="exists(result/successMessage)">
					<!-- Upload file via stored procedure in Virtuoso -->
					<!-- REMARK: autorisatie in virtuoso.ini has to be set: -->
					<!--         DirsAllowed			= ., ../vad, ../../Tomcat/temp -->
					<p:processor name="oxf:sql">
						<p:input name="data" href="aggregate('root',#ttlfile,#results,#output)"/> <!-- Inclusion of output is technical: otherwise output is a result of this branche... -->
						<p:input name="config">
							<sql:config>
								<response>Conversie succesvol uitgevoerd</response>
								<sql:connection>
									<sql:datasource>virtuoso</sql:datasource>
									<sql:execute>
										<sql:call>
											{call ldt.upload_rdf(<sql:param type="xs:string" select="concat(substring-after(root/url,'file:/'),'_')"/>,<sql:param type="xs:string" select="root/results/graph"/>,'del','ttl')}
										</sql:call>
									</sql:execute>
								</sql:connection>
							</sql:config>
						</p:input>
						<p:output name="data" id="result"/>
					</p:processor>
				</p:when>
				<p:otherwise>
					<!-- Asynchronous execution or some error occured - show message -->
					<p:processor name="oxf:identity">
						<p:input name="data" href="#output"/>
						<p:output name="data" id="result"/>
					</p:processor>
				</p:otherwise>
			</p:choose>
		</p:when>
		<p:otherwise>
			<!-- Conversion doesn't exists - show error -->
			<p:processor name="oxf:identity">
				<p:input name="data">
					<result>
						<errorMessage>No conversion found</errorMessage>
					</result>
				</p:input>
				<p:output name="data" id="result"/>
			</p:processor>
		</p:otherwise>
	</p:choose>

	<!-- TODO: It's better to use the same subpipeline for query, container and conversion!! -->
	
	<!-- Transform result to annotated rdf -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="aggregate('root',#context,#result)"/>
		<p:input name="config" href="../transformations/result2rdfa.xsl"/>
		<p:output name="data" id="rdfa"/>
	</p:processor>

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

</p:config>
