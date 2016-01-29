<!--

    NAME     container.xpl
    VERSION  1.5.1-SNAPSHOT
    DATE     2016-01-29

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
    Pipeline to manage updating an inserting triples into a container

	TWO Problems at this moment:
	1) Error handling from stored procedure isn't nice: default error page. Errors should be handled before any stored procedure call is made
	2) When a zip contains multiple files, only the last file will get into the container!
	
	Structure of this pipeline:
	1. Process the http request, results in context and containercontext pipes
	2. Check if a container exists in the configuration, if not: return 404 (resource not found)
	3. Check if authorization is required, and if so, check authorization. If not authorized: return 403.
	4. Check situation: (A) new data has been uploaded, or (B) the container itself is request
	|
	+~~~A. (New data is uploaded)
	|	1. Check the file or form:
	|	+~~~A. (It's a zip)
	|	|	Unpack zip and return references to files in filelist pipe
	|	+~~~B. (It's not a zip, but a simple file)
	|	|	Put reference to file into filelist pipe
	|	+~~~C. (It's a form)
	|	|	Dump content into file, and put reference of file into filelist pipe
	|	+~~~D. (Otherwise)
	|		Create an empty filelist
	|
	|	2. For each filename in the filelist pipe, do:
	|		1. Check if a translator is defined (A), a form has been used (B), or not (C)
	|		+~~~A. (Translator is defined)
	|		|	1. Check format of file
	|		|	+~~~A. (Excel format)
	|		|	|	Load excel document, Convert into XML format, put it in xmldata pipe
	|		|	|
	|		|	+~~~B. (CSV format)
	|		|	|	Load CSV document, convert into XML format, put it in xmldata pipe
	|		|	|
	|		|	+~~~C. (XML format)
	|		|	|	Load XML document, put in xmldata pipe
	|		|	|
	|		|	+~~~D. (Other formats)
	|		|		Put empty xml document in xmldata pipe
	|		|
	|		|	2. Load translator and translate xmldata, save it to disc and put reference into rdffile pipe
	|		|
	|		+~~~B. (No translator is defined)
	|			1. Put reference into rdffile pipe
	|
	|		2. Check the format of the rdffile (A: XML, B: TTL, C: Something else)
	|		+~~~A. (XML format)
	|		|	Upload XML format to triplestore, store message in results pipe
	|		+~~~B. (TTL format)
	|		|	Upload TTL format to triplestore, store message in results pipe
	|		+~~~C. (Something else)
	|			Store error message in results pipe
	|
	|	3. Show messages from results pipe to user (html or json)
	|
	+~~~B. (Container itself is request)
		Check what the request wants: html or json, and return appropriate result.
	
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
	<p:processor name="oxf:xslt">
		<p:input name="data" href="aggregate('croot',#instance,#request,#roles)"/>
		<p:input name="config" href="../transformations/context.xsl"/>
		<p:output name="data" id="context"/>
	</p:processor>

	<!-- Look for container definition in configuration -->
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
					}
					WHERE {
						GRAPH <]]><xsl:value-of select="context/representation-graph/@uri"/><![CDATA[> {
							<]]><xsl:value-of select="context/subject"/><![CDATA[> rdf:type ?type.
							<]]><xsl:value-of select="context/subject"/><![CDATA[> ?p ?s.
							FILTER (?type = elmo:Container or ?type = elmo:VersionContainer)
						}
					}
				]]>
				</query>
				<default-graph-uri/>
				<error type=""/>
			</parameters>
		</p:input>
		<p:output name="response" id="container"/>
	</p:processor>

	<!-- Create container URL (subject or version-based) -->
	<p:processor name="oxf:xslt">
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:variable name="returns"><xsl:text>&#10;&#13;</xsl:text></xsl:variable>
				<xsl:variable name="noreturns">  </xsl:variable>
				<xsl:template name="versionformat">
					<xsl:param name="dt"/>
					<xsl:value-of select="year-from-dateTime($dt)"/>-<xsl:value-of select="month-from-dateTime($dt)"/>-<xsl:value-of select="day-from-dateTime($dt)"/>-<xsl:value-of select="hours-from-dateTime($dt)"/>-<xsl:value-of select="minutes-from-dateTime($dt)"/>-<xsl:value-of select="seconds-from-dateTime($dt)"/>
				</xsl:template>
				<xsl:template match="/">
					<container>
						<xsl:for-each select="rdf:RDF/rdf:Description[1]">
							<label><xsl:value-of select="rdfs:label"/></label>
							<url><xsl:value-of select="@rdf:about"/></url>
							<user-role><xsl:value-of select="elmo:user-role"/></user-role>
							<translator><xsl:value-of select="elmo:translator/@rdf:resource"/></translator>
							<version-url>
								<xsl:value-of select="@rdf:about"/>
								<xsl:if test="rdf:type/@rdf:resource='http://bp4mc2.org/elmo/def#VersionContainer'">#<xsl:call-template name="versionformat"><xsl:with-param name="dt" select="current-dateTime()"/></xsl:call-template></xsl:if>
							</version-url>
							<xsl:choose>
								<xsl:when test="elmo:updates/@rdf:resource!=''"><target-graph action="update"><xsl:value-of select="elmo:updates/@rdf:resource"/></target-graph></xsl:when>
								<xsl:when test="elmo:partOf/@rdf:resource!=''"><target-graph action="part"><xsl:value-of select="elmo:partOf/@rdf:resource"/></target-graph></xsl:when>
								<xsl:when test="elmo:replaces/@rdf:resource!=''"><target-graph action="replace"><xsl:value-of select="elmo:replaces/@rdf:resource"/></target-graph></xsl:when>
								<xsl:otherwise/>
							</xsl:choose>
							<representation><xsl:value-of select="elmo:representation/@rdf:resource"/></representation>
							<postquery><xsl:value-of select="normalize-space(translate(elmo:query,$returns,$noreturns))"/></postquery>
						</xsl:for-each>
					</container>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:input name="data" href="#container"/>
		<p:output name="data" id="containercontext"/>
	</p:processor>
	
	<p:choose href="#containercontext">
		<!-- Container should exist in configuration, or return 404 -->
		<p:when test="exists(container/url)">
			<!-- Container exists -->
			<p:choose href="aggregate('root',#context,#containercontext)">
				<!-- When a user-role is defined, the user should have that role -->
				<p:when test="root/container/user-role!='' and root/context/user-role!=root/container/user-role">
					<!-- User-role incorrect: 403 return code -->
					<p:processor name="oxf:xslt">
						<p:input name="data">
							<parameters>
								<error>Forbidden.</error>
							</parameters>
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
								<status-code>403</status-code>
							</config>
						</p:input>
						<p:input name="data" href="#htmlres"/>
					</p:processor>
				</p:when>
				<!-- Submission of new data, result of this branche = new data is uploaded -->
				<p:when test="root/context/parameters/parameter[name='container']/value=root/context/subject">
					<p:choose href="#context">
						<!-- Upload file, zip -->
						<p:when test="ends-with(context/parameters/parameter[name='file']/filename,'.zip') or context/parameters/parameter[name='file']/content-type='multipart/x-zip'">
							<!-- Fetch zipfile -->
							<p:processor name="oxf:url-generator">
								<p:input name="config" transform="oxf:xslt" href="#context">
									<config xsl:version="2.0">
										<url><xsl:value-of select="context/parameters/parameter[name='file']/value"/></url>
										<content-type>multipart/x-zip</content-type>
									</config>
								</p:input>
								<p:output name="data" id="zip"/>
							</p:processor>
							<p:processor name="oxf:unzip">
								<p:input name="data" href="#zip"/>
								<p:output name="data" id="filelist"/>
							</p:processor>
						</p:when>
						<!-- Upload file, not a zip -->
						<p:when test="context/parameters/parameter[name='file']/filename!=''">
							<!-- Put filename in filelist -->
							<p:processor name="oxf:xslt">
								<p:input name="config">
									<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
										<xsl:template match="/">
											<files>
												<file name="{context/parameters/parameter[name='file']/filename}"><xsl:value-of select="context/parameters/parameter[name='file']/value"/></file>
											</files>
										</xsl:template>
									</xsl:stylesheet>
								</p:input>
								<p:input name="data" href="#context"/>
								<p:output name="data" id="filelist"/>
							</p:processor>
						</p:when>
						<!-- Upload form -->
						<p:when test="exists(context/parameters/parameter[name='content']/value)">
							<p:processor name="oxf:xslt">
								<p:input name="config">
									<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
										<xsl:template match="/">
											<!-- standaard prefixes -->
											<!--
											<xsl:text>@prefix elmo: &lt;http://bp4mc2.org/elmo/def#></xsl:text>
											<xsl:text>@prefix rdf: &lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#></xsl:text>
											<xsl:text>@prefix rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#></xsl:text>
											<xsl:text>@prefix xhtml: &lt;http://www.w3.org/1999/xhtml/vocab#></xsl:text>
											-->
											<xsl:value-of select="context/parameters/parameter[name='content']/value"/>
										</xsl:template>
									</xsl:stylesheet>
								</p:input>
								<p:input name="data" href="#context"/>
								<p:output name="data" id="turtle"/>
							</p:processor>
							<p:processor name="oxf:text-converter">
								<p:input name="config">
									<config>
										<encoding>utf-8</encoding>
									</config>
								</p:input>
								<p:input name="data" href="#turtle" />
								<p:output name="data" id="converted" />
							</p:processor>
							<p:processor name="oxf:file-serializer">
								<p:input name="config">
									<config>
										<scope>session</scope>
									</config>
								</p:input>
								<p:input name="data" href="#converted"/>
								<p:output name="data" id="urlfile"/>
							</p:processor>
							<!-- Put filename in filelist -->
							<p:processor name="oxf:xslt">
								<p:input name="config">
									<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
										<xsl:template match="/">
											<files>
												<file name="content.ttl"><xsl:value-of select="url"/></file>
											</files>
										</xsl:template>
									</xsl:stylesheet>
								</p:input>
								<p:input name="data" href="#urlfile"/>
								<p:output name="data" id="filelist"/>
							</p:processor>
						</p:when>
						<!-- Something else, just create an empty filelist -->
						<p:otherwise>
							<p:processor name="oxf:identity">
								<p:input name="data">
									<files />
								</p:input>
								<p:output name="data" id="filelist"/>
							</p:processor>
						</p:otherwise>
					</p:choose>
<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config/>
	</p:input>
	<p:input name="data" href="#filelist"/>
</p:processor>
-->
					<p:for-each href="#filelist" select="/files/file" root="results" id="result">
						<p:choose href="#context">
							<!-- Translator is used -->
							<p:when test="container/translator!=''">
								<p:choose href="current()">
									<!-- Upload excel file -->
									<p:when test="ends-with(file/@name,'.xlsx')">
										<!-- Fetch file -->
										<p:processor name="oxf:url-generator">
											<p:input name="config" transform="oxf:xslt" href="current()">
												<config xsl:version="2.0">
													<url><xsl:value-of select="file"/></url>
													<mode>binary</mode>
												</config>
											</p:input>
											<p:output name="data" id="xlsxdata"/>
										</p:processor>
										<!-- Transform -->
										<p:processor name="oxf:excel-converter">
											<p:input name="data" href="#xlsxdata"/>
											<p:output name="data" id="xmldata"/>
										</p:processor>
									</p:when>
									<!-- Upload CSV file -->
									<p:when test="ends-with(file/@name,'.csv')">
										<!-- Fetch file -->
										<p:processor name="oxf:url-generator">
											<p:input name="config" transform="oxf:xslt" href="current()">
												<config xsl:version="2.0">
													<url><xsl:value-of select="file"/></url>
													<content-type>text/csv</content-type>
												</config>
											</p:input>
											<p:output name="data" id="csvdata"/>
										</p:processor>
										<!-- CSV to XML transformation -->
										<p:processor name="oxf:xslt">
											<p:input name="config" href="../transformations/csv2xml.xsl"/>
											<p:input name="data" href="#csvdata"/>
											<p:output name="data" id="xmldata"/>
										</p:processor>
									</p:when>
									<!-- Upload XML file -->
									<p:when test="ends-with(file/@name,'.xml')">
										<!-- Fetch file -->
										<p:processor name="oxf:url-generator">
											<p:input name="config" transform="oxf:xslt" href="current()">
												<config xsl:version="2.0">
													<url><xsl:value-of select="file"/></url>
													<content-type>application/xml</content-type>
												</config>
											</p:input>
											<p:output name="data" id="xmldata"/>
										</p:processor>
									</p:when>
									<!-- Something else -->
									<p:otherwise>
										<p:processor name="oxf:identity">
											<p:input name="data">
												<empty />
											</p:input>
											<p:output name="data" id="xmldata"/>
										</p:processor>
									</p:otherwise>
								</p:choose>
								<!-- Fetch translator -->
								<p:processor name="oxf:url-generator">
									<p:input name="config" transform="oxf:xslt" href="#containercontext">
										<config xsl:version="2.0">
											<url>../translators/<xsl:value-of select="substring-after(/container/translator,'http://bp4mc2.org/elmo/def#')"/>.xsl</url>
											<content-type>application/xml</content-type>
										</config>
									</p:input>
									<p:output name="data" id="translator"/>
								</p:processor>
								<!-- Translate -->
								<p:processor name="oxf:xslt">
									<p:input name="config" href="#translator"/>
									<p:input name="data" href="#xmldata"/>
									<p:output name="data" id="rdfdata"/>
								</p:processor>
								<!-- Convert to xml document -->
								<p:processor name="oxf:xml-converter">
									<p:input name="config">
										<config>
											<encoding>utf-8</encoding>
										</config>
									</p:input>
									<p:input name="data" href="#rdfdata"/>
									<p:output name="data" id="xmldoc"/>
								</p:processor>
								<!-- Store translation in temporary file -->
								<p:processor name="oxf:file-serializer">
									<p:input name="config">
										<config>
											<scope>session</scope>
										</config>
									</p:input>
									<p:input name="data" href="#xmldoc"/>
									<p:output name="data" id="url-written"/>
								</p:processor>
								<!-- Merge temporary file with file description -->
								<p:processor name="oxf:xslt">
									<p:input name="config">
										<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
											<xsl:template match="/">
												<file name="conversion.xml"><xsl:value-of select="url"/></file>
											</xsl:template>
										</xsl:stylesheet>
									</p:input>
									<p:input name="data" href="#url-written"/>
									<p:output name="data" id="rdffile"/>
								</p:processor>
							</p:when>
							<!-- No translator is used (file extension should be xml or ttl) -->
							<p:otherwise>
								<p:processor name="oxf:identity">
									<p:input name="data" href="current()"/>
									<p:output name="data" id="rdffile"/>
								</p:processor>
							</p:otherwise>
						</p:choose>
						<!-- Upload of file: via Virtuoso stored procedure -->
						<!-- Please change authorization in virtuoso.ini: -->
						<!--         DirsAllowed			= ., ../vad, ../../Tomcat/temp -->
						
						<!-- Check if extension is xml or ttl, return error if not -->
						<p:choose href="#rdffile">
							<p:when test="ends-with(file/@name,'.xml')">
								<p:processor name="oxf:sql">
									<p:input name="data" href="aggregate('root',#rdffile,#containercontext)"/>
									<p:input name="config">
										<sql:config>
											<response>Bestand is ingeladen</response>
											<sql:connection>
												<sql:datasource>virtuoso</sql:datasource>
												<sql:execute>
													<sql:call>
														{call ldt.update_container(<sql:param type="xs:string" select="substring-after(root/file,'file:/')"/>,'xml',<sql:param type="xs:string" select="root/container/url"/>,<sql:param type="xs:string" select="root/container/version-url"/>,<sql:param type="xs:string" select="root/container/target-graph"/>,<sql:param type="xs:string" select="root/container/target-graph/@action"/>,<sql:param type="xs:string" select="root/container/postquery"/>)}
													</sql:call>
												</sql:execute>
											</sql:connection>
										</sql:config>
									</p:input>
									<p:output name="data" ref="result"/>
								</p:processor>
							</p:when>
							<p:when test="ends-with(file/@name,'.ttl')">
								<p:processor name="oxf:sql">
									<p:input name="data" href="aggregate('root',#rdffile,#containercontext)"/>
									<p:input name="config">
										<sql:config>
											<response>Bestand is ingeladen</response>
											<sql:connection>
												<sql:datasource>virtuoso</sql:datasource>
												<sql:execute>
													<sql:call>
														{call ldt.update_container(<sql:param type="xs:string" select="substring-after(root/file,'file:/')"/>,'ttl',<sql:param type="xs:string" select="root/container/url"/>,<sql:param type="xs:string" select="root/container/version-url"/>,<sql:param type="xs:string" select="root/container/target-graph"/>,<sql:param type="xs:string" select="root/container/target-graph/@action"/>,<sql:param type="xs:string" select="root/container/postquery"/>)}
													</sql:call>
												</sql:execute>
											</sql:connection>
										</sql:config>
									</p:input>
									<p:output name="data" ref="result"/>
								</p:processor>
							</p:when>
							<p:otherwise>
								<p:processor name="oxf:identity">
									<p:input name="data">
										<response>Unknown format (use xml or ttl)</response>
									</p:input>
									<p:output name="data" ref="result"/>
								</p:processor>
							</p:otherwise>
						</p:choose>
					</p:for-each>
					<!-- Cool URI implementation: respond with HTML or with JSON -->
					<p:choose href="#context">
						<p:when test="context/format='application/json'">
							<p:processor name="oxf:xslt">
								<p:input name="config">
									<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
										<xsl:template match="/">{"response":"<xsl:value-of select="root/results/response"/>"}</xsl:template>
									</xsl:stylesheet>
								</p:input>
								<p:input name="data" href="aggregate('root',#context,#result)"/>
								<p:output name="data" id="textres"/>
							</p:processor>
							<p:processor name="oxf:text-converter">
								<p:input name="config">
									<config>
										<encoding>utf-8</encoding>
									</config>
								</p:input>
								<p:input name="data" href="#textres">
								</p:input>
								<p:output name="data" id="htmlres" />
							</p:processor>
							<!-- Serialize -->
							<p:processor name="oxf:http-serializer">
								<p:input name="config">
									<config>
										<cache-control><use-local-cache>false</use-local-cache></cache-control>
										<status-code>200</status-code>
									</config>
								</p:input>
								<p:input name="data" href="#htmlres"/>
							</p:processor>
						</p:when>
						<p:otherwise>
							<p:processor name="oxf:html-converter">
								<p:input name="config">
									<config>
										<encoding>utf-8</encoding>
										<public-doctype>-//W3C//DTD XHTML 1.0 Strict//EN</public-doctype>
									</config>
								</p:input>
								<p:input name="data" transform="oxf:xslt" href="aggregate('root',#context,#result)">
									<html xsl:version="2.0">
										<meta http-equiv="refresh" content="0;URL={root/context/subject}" />
										<body><p><xsl:value-of select="root/results/response"/></p></body>
									</html>
								</p:input>
								<p:output name="data" id="htmlres" />
							</p:processor>
							<!-- Serialize -->
							<p:processor name="oxf:http-serializer">
								<p:input name="config">
									<config>
										<cache-control><use-local-cache>false</use-local-cache></cache-control>
										<status-code>200</status-code>
									</config>
								</p:input>
								<p:input name="data" href="#htmlres"/>
							</p:processor>
						</p:otherwise>
					</p:choose>
				</p:when>
				<!-- Show old data -->
				<p:otherwise>
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
						<p:input name="request" transform="oxf:xslt" href="#containercontext">
							<parameters xsl:version="2.0">
								<query>
								<![CDATA[
									CONSTRUCT {
										?s?p?o
									}
									WHERE {
										GRAPH <]]><xsl:value-of select="container/url"/><![CDATA[> {
											?s?p?o
										}
									}
								]]>
								</query>
								<default-graph-uri/>
								<error type=""/>
							</parameters>
						</p:input>
						<p:output name="response" id="sparql"/>
					</p:processor>

					<!-- Convert result to turtle -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="aggregate('xmlresult',#sparql,#containercontext)"/>
						<p:input name="config" href="../transformations/rdf2ttl.xsl"/>
						<p:output name="data" id="ttl"/>
					</p:processor>

					<!-- Convert turtle to rdfa -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="aggregate('root',#context,#ttl,#sparql,#containercontext)"/>
						<p:input name="config" href="../transformations/ttl2rdfaform.xsl"/>
						<p:output name="data" id="rdfa"/>
					</p:processor>
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
					<parameters>
						<error>Resource niet gevonden.</error>
					</parameters>
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
