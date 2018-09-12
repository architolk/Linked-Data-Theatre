<!--

    NAME     container.xpl
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
    Pipeline to manage updating an inserting triples into a container

	(this file contains rdfs:label annotations. These annotations can be used to automatically create documentation)

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
	|	3. Check the format of the rdffile (A: XML or : TTL, B: Something else)
	|	+~~~A. (XML format)
	|	|	Upload XML/TTL format to triplestore, store (error)message in results pipe
	|	+~~~B. (Something else)
	|		Store error message in results pipe
	|
	|	4. Show messages from results pipe to user (html or json). Redirect to container when there's no error
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
		  xmlns:xs="http://www.w3.org/2001/XMLSchema"
		  xmlns:sh="http://www.w3.org/ns/shacl#"

		  rdfs:label="Container pipeline"
		  >

	<!-- Configuration> -->
	<p:param type="input" name="instance"/>
	<p:processor name="oxf:url-generator" rdfs:label="get config">
		<p:input name="config">
			<config>
				<url>../config.xml</url>
				<content-type>application/xml</content-type>
			</config>
		</p:input>
		<p:output name="data" id="config"/>
	</p:processor>

	<!-- Generate original request -->
	<p:processor name="oxf:request" rdfs:label="retrieve http-request">
		<p:input name="config">
			<config stream-type="xs:anyURI">
				<include>/request/content-type</include>
				<include>/request/headers/header</include>
				<include>/request/request-url</include>
				<include>/request/parameters/parameter</include>
				<include>/request/remote-user</include>
				<include>/request/method</include>
				<include>/request/request-path</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>

	<!-- Dirty fix when instance is not the configuration (in a particular case with upload) -->
	<p:processor name="oxf:xslt">
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:template match="/root">
					<xsl:choose>
						<xsl:when test="exists(input/theatre)"><xsl:copy-of select="input/theatre"/></xsl:when>
						<xsl:otherwise>
							<theatre>
								<xsl:copy-of select="theatre/@*"/>
								<xsl:copy-of select="theatre/(* except subdomain)"/>
								<subdomain><xsl:value-of select="substring-before(request/request-path,'/container')"/></subdomain>
							</theatre>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:input name="data" href="aggregate('root',aggregate('input',#instance),#request,#config)"/>
		<p:output name="data" id="instancefixed"/>
	</p:processor>

	<!-- /request/body can only be obtained when no parameters are serialized within the body! -->
	<p:choose href="#request" rdfs:label="get request body, if available">
		<p:when test="not(exists(/request/parameters))">
			<p:processor name="oxf:request">
				<p:input name="config">
					<config stream-type="xs:anyURI">
						<include>/request/body</include>
					</config>
				</p:input>
				<p:output name="data" id="requestbody"/>
			</p:processor>
		</p:when>
		<p:otherwise>
			<p:processor name="oxf:identity">
				<p:input name="data">
					<request />
				</p:input>
				<p:output name="data" id="requestbody"/>
			</p:processor>
		</p:otherwise>
	</p:choose>

	<!-- Get credentials and user roles -->
	<p:processor name="oxf:request-security" rdfs:label="get request security context">
		<p:input name="config" transform="oxf:xslt" href="#instancefixed">
			<config xsl:version="2.0">
				<xsl:for-each select="theatre/roles/role">
					<role><xsl:value-of select="."/></role>
				</xsl:for-each>
			</config>
		</p:input>
		<p:output name="data" id="roles"/>
	</p:processor>

	<!-- Default namespaces -->
	<p:processor name="oxf:url-generator" rdfs:label="get default namespaces">
		<p:input name="config">
			<config>
				<url>../namespaces.xml</url>
				<content-type>application/xml</content-type>
			</config>
		</p:input>
		<p:output name="data" id="namespaces"/>
	</p:processor>

	<!-- Create context -->
	<p:processor name="oxf:unsafe-xslt" rdfs:label="create context">
		<p:input name="data" href="aggregate('croot',#instancefixed,#request,#requestbody,#roles)"/>
		<p:input name="config" href="../transformations/context.xsl"/>
		<p:output name="data" id="context"/>
	</p:processor>

	<p:choose href="#context" rdfs:label="create container context">
		<p:when test="matches(context/subject,'backstage/rep$') and context/back-of-stage!=''" rdfs:label="backstage, edit representation">
			<!-- Special container: backstage! -->
			<p:processor name="oxf:xslt">
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
						<xsl:template match="/">
							<xsl:variable name="subject" select="context/parameters/parameter[name='SUBJECT']/value"/>
							<container>
								<label>Backstage of &lt;<xsl:value-of select="context/back-of-stage"/>></label>
								<url><xsl:value-of select="substring-before(context/subject,'/rep')"/></url>
								<stage><xsl:value-of select="context/back-of-stage"/></stage>
								<response><xsl:value-of select="context/parameters/parameter[name='RESPONSE']/value"/></response>
								<user-role/>
								<translator/>
								<version-url><xsl:value-of select="substring-before(context/subject,'/rep')"/></version-url>
								<target-graph action="update"><xsl:value-of select="context/back-of-stage"/></target-graph>
								<representation/>
								<postquery/>
								<fetchquery>
									<xsl:choose>
										<xsl:when test="$subject!=''">
										<![CDATA[
										CONSTRUCT {
											<]]><xsl:value-of select="$subject"/><![CDATA[>?p?o.
											?o?po?oo.
											?oo?poo?ooo.
											?ooo?pooo?oooo.
											?oooo?poooo?ooooo.
										}
										WHERE {
											GRAPH <]]><xsl:value-of select="context/back-of-stage"/><![CDATA[> {
												<]]><xsl:value-of select="$subject"/><![CDATA[>?p?o
												OPTIONAL {
													?o?po?oo
													OPTIONAL {
														?oo?poo?ooo
														OPTIONAL {
															?ooo?pooo?oooo
															OPTIONAL {
																?oooo?poooo?ooooo
															}
														}
													}
												}
											}
										}
										]]>
										</xsl:when>
										<xsl:otherwise>CONSTRUCT {?x?x?x} WHERE {?x?x?x}</xsl:otherwise>
									</xsl:choose>
								</fetchquery>
								<assertions/>
								<contains>
									<representation uri="http://bp4mc2.org/elmo/def#BackstageMenu"/>
								</contains>
							</container>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:input name="data" href="#context"/>
				<p:output name="data" id="containercontext"/>
			</p:processor>
		</p:when>
		<p:when test="matches(context/subject,'backstage/import$') and context/back-of-stage!=''" rdfs:label="backstage, import">
			<!-- Special container: backstage import! -->
			<p:processor name="oxf:xslt">
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
						<xsl:template match="/">
							<container>
								<label>Backstage of &lt;<xsl:value-of select="context/back-of-stage"/>></label>
								<url><xsl:value-of select="context/back-of-stage"/></url>
								<user-role/>
								<response><xsl:value-of select="context/parameters/parameter[name='RESPONSE']/value"/></response>
								<translator/>
								<version-url><xsl:value-of select="context/back-of-stage"/></version-url>
								<representation>http://bp4mc2.org/elmo/def#UploadRepresentation</representation>
								<postquery/>
								<fetchquery>CONSTRUCT {?x?x?x} WHERE {?x?x?x}</fetchquery>
								<assertions/>
								<contains>
									<representation uri="http://bp4mc2.org/elmo/def#BackstageMenu"/>
								</contains>
							</container>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:input name="data" href="#context"/>
				<p:output name="data" id="containercontext"/>
			</p:processor>
		</p:when>
		<p:otherwise rdfs:label="normal container">
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
							PREFIX sh: <http://www.w3.org/ns/shacl#>
							CONSTRUCT {
								<]]><xsl:value-of select="context/subject"/><![CDATA[> a ?type.
								<]]><xsl:value-of select="context/subject"/><![CDATA[> ?p ?s.
								<]]><xsl:value-of select="context/subject"/><![CDATA[> elmo:query ?query.
								<]]><xsl:value-of select="context/subject"/><![CDATA[> elmo:assertion ?assertion.
								?assertion ?assertionp ?assertiono.
								<]]><xsl:value-of select="context/subject"/><![CDATA[> elmo:fragment ?fragment.
								?fragment ?fragmentp ?fragmento.
								?shape a sh:NodeShape.
								?shape ?shapep ?shapeo.
								?pshape ?pshapep ?pshapeo.
							}
							WHERE {
								GRAPH <]]><xsl:value-of select="context/representation-graph/@uri"/><![CDATA[> {
									<]]><xsl:value-of select="context/subject"/><![CDATA[> a ?type.
									<]]><xsl:value-of select="context/subject"/><![CDATA[> ?p ?s.
									OPTIONAL { <]]><xsl:value-of select="context/subject"/><![CDATA[> elmo:query/elmo:query ?query }.
									OPTIONAL {
										<]]><xsl:value-of select="context/subject"/><![CDATA[> elmo:assertion ?assertion.
										?assertion ?assertionp ?assertiono
									}
									OPTIONAL {
										<]]><xsl:value-of select="context/subject"/><![CDATA[> elmo:fragment ?fragment.
										?fragment ?fragmentp ?fragmento
									}
									OPTIONAL {
										<]]><xsl:value-of select="context/subject"/><![CDATA[> elmo:shape ?shape.
										?shape ?shapep ?shapeo.
										?shape sh:property ?pshape.
										?pshape ?pshapep ?pshapeo.
									}
									FILTER (?type = elmo:Container || ?type = elmo:VersionContainer)
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
						<xsl:template match="parameter" mode="replace">
							<xsl:param name="text"/>
							<!-- Escape characters that could be used for SPARQL insertion -->
							<!-- The solution is quite harsh: all ', ", <, > and \ are deleted -->
							<!-- A better solution could be to know if a parameter is a literal or a URI -->
							<xsl:variable name="problems">("|'|&lt;|&gt;|\\|\$)</xsl:variable>
							<xsl:variable name="value">
								<xsl:value-of select="replace(value[1],$problems,'')"/>
							</xsl:variable>
							<xsl:choose>
								<xsl:when test="exists(following-sibling::*[1])">
									<xsl:variable name="query">
										<xsl:apply-templates select="following-sibling::*[1]" mode="replace">
											<xsl:with-param name="text" select="$text"/>
										</xsl:apply-templates>
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="name!='content'">
											<xsl:value-of select="replace($query,concat('@',upper-case(name),'@'),$value)"/>
										</xsl:when>
										<xsl:otherwise><xsl:value-of select="$query"/></xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<xsl:choose>
										<xsl:when test="name!='content'">
											<xsl:value-of select="replace($text,concat('@',upper-case(name),'@'),$value)"/>
										</xsl:when>
										<xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
									</xsl:choose>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:template>
						<xsl:template match="/">
							<xsl:variable name="container" select="/root/context/subject"/>
							<container>
								<xsl:for-each select="root/rdf:RDF/(elmo:Container|elmo:VersionContainer|rdf:Description)[@rdf:about=$container]">
									<label><xsl:value-of select="rdfs:label"/></label>
									<url><xsl:value-of select="@rdf:about"/></url>
									<user-role><xsl:value-of select="elmo:user-role"/></user-role>
									<response><xsl:value-of select="/root/context/parameters/parameter[name='RESPONSE']/value"/></response>
									<translator><xsl:value-of select="elmo:translator/@rdf:resource"/></translator>
									<version-url>
										<xsl:value-of select="@rdf:about"/>
										<xsl:if test="rdf:type/@rdf:resource='http://bp4mc2.org/elmo/def#VersionContainer'">#<xsl:call-template name="versionformat"><xsl:with-param name="dt" select="current-dateTime()"/></xsl:call-template></xsl:if>
									</version-url>
									<xsl:choose>
										<xsl:when test="elmo:updates/@rdf:resource!=''"><target-graph action="update"><xsl:value-of select="elmo:updates/@rdf:resource"/></target-graph></xsl:when>
										<xsl:when test="elmo:partOf/@rdf:resource!=''"><target-graph action="part"><xsl:value-of select="elmo:partOf/@rdf:resource"/></target-graph></xsl:when>
										<xsl:when test="elmo:replaces/@rdf:resource!=''"><target-graph action="replace"><xsl:value-of select="elmo:replaces/@rdf:resource"/></target-graph></xsl:when>
										<xsl:when test="/root/context/upload-file/@action='insert'"><target-graph action="insert"/></xsl:when>
										<xsl:otherwise/>
									</xsl:choose>
									<representation><xsl:value-of select="elmo:representation/@rdf:resource"/></representation>
									<!-- Create query (replace parameters and default settings) -->
									<xsl:variable name="query1">
										<xsl:apply-templates select="/root/context/parameters/parameter[1]" mode="replace">
											<xsl:with-param name="text" select="elmo:query[.!=''][1]"/>
										</xsl:apply-templates>
										<xsl:if test="not(exists(/root/context/parameters/parameter))"><xsl:value-of select="elmo:query[.!=''][1]"/></xsl:if>
									</xsl:variable>
									<xsl:variable name="query2" select="replace($query1,'@LANGUAGE@',/root/context/language)"/>
									<xsl:variable name="query3" select="replace($query2,'@USER@',/root/context/user)"/>
									<xsl:variable name="query4" select="replace($query3,'@CURRENTMOMENT@',string(current-dateTime()))"/>
									<xsl:variable name="query5" select="replace($query4,'@STAGE@',/root/context/back-of-stage)"/>
									<xsl:variable name="query6" select="replace($query5,'@TIMESTAMP@',/root/context/timestamp)"/>
									<xsl:variable name="query7" select="replace($query6,'@DATE@',/root/context/date)"/>
									<postquery><xsl:value-of select="normalize-space(translate(replace($query7,'@SUBJECT@',/root/context/subject),$returns,$noreturns))"/></postquery>
									<xsl:choose>
										<xsl:when test="elmo:representation/@rdf:resource='http://bp4mc2.org/elmo/def#UploadRepresentation' and not(rdf:type/@rdf:resource='http://bp4mc2.org/elmo/def#VersionContainer')">
											<fetchquery>CONSTRUCT {?x?x?x} WHERE {?x?x?x}</fetchquery>
										</xsl:when>
										<xsl:otherwise>
											<fetchquery>
												<![CDATA[
													CONSTRUCT {
														?s?p?o
													}
													WHERE {
														GRAPH <]]><xsl:value-of select="@rdf:about"/><![CDATA[> {
															?s?p?o
														}
													}
												]]>
											</fetchquery>
										</xsl:otherwise>
									</xsl:choose>
									<assertions>
										<xsl:for-each select="elmo:assertion">
											<xsl:variable name="assertion" select="@rdf:nodeID"/>
											<xsl:for-each select="../../rdf:Description[@rdf:nodeID=$assertion]/(elmo:assert|elmo:assert-not)">
												<xsl:variable name="label"><xsl:value-of select="../rdfs:label"/></xsl:variable>
												<xsl:variable name="nlabel">
													<xsl:value-of select="$label"/>
													<xsl:if test="$label=''">Assertion failed</xsl:if>
												</xsl:variable>
												<assert label="{$nlabel}" expected="{local-name()='assert'}"><xsl:value-of select="."/></assert>
											</xsl:for-each>
										</xsl:for-each>
									</assertions>
									<fragments>
										<xsl:for-each select="elmo:fragment">
											<xsl:variable name="fragment" select="@rdf:nodeID"/>
											<xsl:for-each select="../../rdf:Description[@rdf:nodeID=$fragment]">
												<fragment id="{elmo:applies-to}">
													<xsl:copy-of select="* except elmo:applies-to"/>
												</fragment>
											</xsl:for-each>
										</xsl:for-each>
									</fragments>
									<shapes>
										<xsl:for-each select="/root/rdf:RDF/rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/ns/shacl#NodeShape']">
											<shape uri="{@rdf:about}">
												<xsl:copy-of select="* except sh:property"/>
												<xsl:for-each select="sh:property">
													<xsl:variable name="property" select="@rdf:resource|@rdf:nodeID"/>
													<sh:property>
														<xsl:copy-of select="../../rdf:Description[@rdf:nodeID=$property or @rdf:about=$property]"/>
													</sh:property>
												</xsl:for-each>
											</shape>
										</xsl:for-each>
									</shapes>
									<contains>
										<xsl:for-each select="elmo:contains">
											<representation uri="{@rdf:resource}"/>
										</xsl:for-each>
									</contains>
								</xsl:for-each>
							</container>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:input name="data" href="aggregate('root',#context,#container)"/>
				<p:output name="data" id="containercontext"/>
			</p:processor>
		</p:otherwise>
	</p:choose>

	<p:choose href="#containercontext">
		<!-- Container should exist in configuration, or return 404 -->
		<p:when test="exists(container/url)" rdfs:label="container-configuration found">
			<!-- Container exists -->
			<p:choose href="aggregate('root',#context,#containercontext)">
				<!-- When a user-role is defined, the user should have that role -->
				<p:when test="root/container/user-role!='' and not(contains(root/context/user-role,root/container/user-role))" rdfs:label="unauthorized role: 403">
					<!-- User-role incorrect: 403 return code -->
					<p:processor name="oxf:identity">
						<p:input name="data">
							<parameters>
								<error-nr>403</error-nr>
								<error-title>Forbidden</error-title>
								<error>You are not autorised to access this page.</error>
							</parameters>
						</p:input>
						<p:output name="data" id="errortext"/>
					</p:processor>
					<p:processor name="oxf:xslt">
						<p:input name="data" href="aggregate('results',#context,#errortext)"/>
						<p:input name="config" href="../transformations/error2html.xsl"/>
						<p:output name="data" id="html"/>
					</p:processor>
					<p:processor name="oxf:html-converter">
						<p:input name="config">
							<config>
								<encoding>utf-8</encoding>
								<version>5.0</version>
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
				<p:when test="exists(root/context/upload-file/@action) or root/context/parameters/parameter[name='container']/value=root/context/subject" rdfs:label="upload via user-interface or REST service">
					<p:choose href="#context" rdfs:label="create upload filelist">
						<!-- Upload via REST service, zip -->
						<p:when test="exists(context/upload-file/@action) and context/upload-file/@type='multipart/x-zip'">
							<!-- Fetch zipfile -->
							<p:processor name="oxf:url-generator">
								<p:input name="config" transform="oxf:xslt" href="#context">
									<config xsl:version="2.0">
										<url><xsl:value-of select="context/upload-file"/></url>
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
						<!-- Upload via REST service, not a zip -->
						<p:when test="exists(context/upload-file/@action)">
							<!-- Put filename in filelist -->
							<p:processor name="oxf:xslt">
								<p:input name="config">
									<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
										<xsl:template match="/">
											<files>
												<xsl:variable name="type">
													<xsl:choose>
														<xsl:when test="root/context/upload-file/@type='application/xml'">xml</xsl:when>
														<xsl:when test="root/context/upload-file/@type='application/rdf+xml'">xml</xsl:when>
														<xsl:when test="root/context/upload-file/@type='application/ld+json'">jsonld</xsl:when>
														<xsl:when test="root/container/translator!=''">xml</xsl:when> <!-- A translator implies xml -->
														<xsl:otherwise>ttl</xsl:otherwise> <!-- If all fails, assume turtle -->
													</xsl:choose>
												</xsl:variable>
												<file name="content.{$type}"><xsl:value-of select="root/context/upload-file"/></file>
											</files>
										</xsl:template>
									</xsl:stylesheet>
								</p:input>
								<p:input name="data" href="aggregate('root',#context,#containercontext)"/>
								<p:output name="data" id="filelist"/>
							</p:processor>
						</p:when>
						<!-- Upload file, zip -->
						<p:when test="ends-with(context/parameters/parameter[name='file']/filename,'.zip') or context/parameters/parameter[name='file']/content-type='multipart/x-zip'" rdfs:label="upload zip file">
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
						<p:when test="context/parameters/parameter[name='file']/filename!=''" rdfs:label="upload file, not a zip">
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
						<!-- Download from URL -->
						<p:when test="context/parameters/parameter[name='url']/value!=''" rdfs:label="download file from url">
							<!-- Fetch file -->
							<p:processor name="oxf:httpclient-processor">
								<p:input name="config" transform="oxf:xslt" href="#context">
									<config xsl:version="2.0">
										<input-type>text</input-type>
										<output-type>rdf</output-type>
										<url><xsl:value-of select="context/parameters/parameter[name='url']/value"/></url>
										<method>get</method>
									</config>
								</p:input>
								<p:output name="data" id="output"/>
							</p:processor>
							<p:processor name="oxf:xml-converter">
								<p:input name="config">
									<config>
										<encoding>utf-8</encoding>
									</config>
								</p:input>
								<p:input name="data" href="#output#xpointer(response/rdf:RDF)" />
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
												<file name="content.xml"><xsl:value-of select="url"/></file>
											</files>
										</xsl:template>
									</xsl:stylesheet>
								</p:input>
								<p:input name="data" href="#urlfile"/>
								<p:output name="data" id="filelist"/>
							</p:processor>
						</p:when>
						<!-- Upload form -->
						<p:when test="exists(context/parameters/parameter[name='content']/value)" rdfs:label="upload via form">
							<p:processor name="oxf:xslt">
								<p:input name="config">
									<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
										<xsl:template match="/">
											<xsl:for-each select="root/namespaces/ns">
												<xsl:text>@prefix </xsl:text>
												<xsl:value-of select="@prefix"/>:&lt;<xsl:value-of select="."/>
												<xsl:text>>. </xsl:text>
											</xsl:for-each>
											<xsl:value-of select="root/context/parameters/parameter[name='content']/value"/>
										</xsl:template>
									</xsl:stylesheet>
								</p:input>
								<p:input name="data" href="aggregate('root',#namespaces,#context)"/>
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
						<p:otherwise rdfs:label="no valid situation, empty upload">
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
	<p:input name="data" href="#context"/>
</p:processor>
-->
					<p:for-each href="#filelist" select="/files/file" root="results" id="rdffile" rdfs:label="read and convert each file in filelist to rdf">
						<p:choose href="#containercontext">
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
									<p:when test="ends-with(file/@name,'.xml') or ends-with(file/@name,'.xpl') or ends-with(file/@name,'.graphml') or ends-with(file/@name,'.gc')">
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
									<p:input name="data" href="aggregate('root',#xmldata,#containercontext,current())"/>
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
									<p:output name="data" ref="rdffile"/>
								</p:processor>
							</p:when>
							<!-- No translator is used (file extension should be xml or ttl) -->
							<p:otherwise>
								<p:processor name="oxf:identity">
									<p:input name="data" href="current()"/>
									<p:output name="data" ref="rdffile"/>
								</p:processor>
							</p:otherwise>
						</p:choose>
					</p:for-each>
					<!-- Put rdffiles in one string -->
					<p:processor name="oxf:xslt" rdfs:label="combine rdf files">
						<p:input name="config">
							<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
								<xsl:template match="/">
									<filelist>
                    <xsl:variable name="extension"><xsl:value-of select="replace(results/file[1]/@name,'.*\.([^\.]+)$','$1')"/></xsl:variable>
                    <firstformat>
                      <xsl:choose>
                        <!-- Consider extensions owl and rdf as xml format -->
                        <xsl:when test="$extension='owl'">xml</xsl:when>
                        <xsl:when test="$extension='rdf'">xml</xsl:when>
                        <xsl:otherwise><xsl:value-of select="$extension"/></xsl:otherwise>
                      </xsl:choose>
  									</firstformat>
										<xsl:for-each select="results/file">
											<file name="{@name}">
												<xsl:value-of select="substring-after(.,'file:')"/>
											</file>
										</xsl:for-each>
									</filelist>
								</xsl:template>
							</xsl:stylesheet>
						</p:input>
						<p:input name="data" href="#rdffile"/>
						<p:output name="data" id="rdffilelist"/>
					</p:processor>

					<!-- Check if extension is xml or ttl, return error if not -->
					<p:choose href="#rdffilelist" rdfs:label="upload to virtuoso, check xml or ttl">
						<p:when test="filelist/firstformat='xml' or filelist/firstformat='ttl' or filelist/firstformat='jsonld'">
							<!-- NEW VERSION: Using rdf4j instead of jdbc connection -->
							<p:processor name="oxf:rdf4j-processor">
								<p:input name="config" transform="oxf:xslt" href="#containercontext">
									<config xsl:version="2.0">
										<action><xsl:value-of select="container/target-graph/@action"/></action>
										<cgraph><xsl:value-of select="container/version-url"/></cgraph> <!-- Version-url is same as url for normal containers -->
										<pgraph><xsl:value-of select="container/url"/></pgraph>
										<tgraph><xsl:value-of select="container/target-graph"/></tgraph>
										<!--<postquery><xsl:value-of select="container/postquery"/></postquery>-->
									</config>
								</p:input>
								<p:input name="data" href="#rdffilelist"/>
								<p:output name="data" id="uploadresult"/>
							</p:processor>
							<!-- Check assertions (uploadresult as part of assertions, otherwise parallisation errors might occur) -->
							<p:for-each href="#containercontext" select="/container/assertions/assert" root="results" id="aresults">
								<!-- Parse parameters for assertions-->
								<p:processor name="oxf:xslt">
									<p:input name="config" href="../transformations/param2query.xsl"/>
									<p:input name="data" href="aggregate('root',current(),aggregate('container',#containercontext#xpointer(container/url)),#context,#context#xpointer(context/parameters))"/>
									<p:output name="data" id="query"/>
								</p:processor>
								<!-- Execute assertion-check -->
								<p:processor name="oxf:xforms-submission">
									<p:input name="submission" transform="oxf:xslt" href="aggregate('root',#uploadresult,#context)">
										<xforms:submission method="get" xsl:version="2.0" action="{root/context/local-endpoint}">
											<xforms:header>
												<xforms:name>Accept</xforms:name>
												<xforms:value>application/sparql-results+xml</xforms:value>
											</xforms:header>
											<xforms:setvalue ev:event="xforms-submit-error" ref="error" value="event('response-body')"/>
											<xforms:setvalue ev:event="xforms-submit-error" ref="error/@type" value="event('error-type')"/>
										</xforms:submission>
									</p:input>
									<p:input name="request" href="#query"/>
									<p:output name="response" ref="aresults"/>
								</p:processor>
							</p:for-each>
							<!-- Analyse results -->
							<p:processor name="oxf:identity">
								<p:input name="data" transform="oxf:xslt" href="aggregate('root',#containercontext,#aresults)">
									<assertions xsl:version="2.0">
										<xsl:for-each select="root/container/assertions/assert">
											<xsl:variable name="expected" select="@expected"/>
											<xsl:variable name="position" select="position()"/>
											<xsl:choose>
												<xsl:when test="/root/results/sparql:sparql[$position]/sparql:boolean!=$expected">
													<assertion-failed><xsl:value-of select="@label"/></assertion-failed>
												</xsl:when>
												<xsl:otherwise/>
											</xsl:choose>
										</xsl:for-each>
									</assertions>
								</p:input>
								<p:output name="data" id="assertions"/>
							</p:processor>
							<p:choose href="aggregate('root',#assertions,#containercontext)">
								<p:when test="not(exists(root/assertions/assertion-failed)) and root/container/postquery!=''">
									<!-- Parse parameters -->
									<p:processor name="oxf:xslt">
										<p:input name="config" href="../transformations/param2query.xsl"/>
										<p:input name="data" href="aggregate('root',#containercontext,#context,#context#xpointer(context/parameters))"/>
										<p:output name="data" id="query"/>
									</p:processor>
									<!-- Execute postquery, if any -->
									<p:processor name="oxf:xforms-submission">
										<p:input name="submission" transform="oxf:xslt" href="#context">
											<xforms:submission method="get" xsl:version="2.0" action="{context/local-endpoint}">
												<xforms:header>
													<xforms:name>Accept</xforms:name>
													<xforms:value>application/sparql-results+xml</xforms:value>
												</xforms:header>
												<xforms:setvalue ev:event="xforms-submit-error" ref="error" value="event('response-body')"/>
												<xforms:setvalue ev:event="xforms-submit-error" ref="error/@type" value="event('error-type')"/>
											</xforms:submission>
										</p:input>
										<p:input name="request" href="#query"/>
										<p:output name="response" id="sparql"/>
									</p:processor>
									<!-- Combine -->
									<p:processor name="oxf:identity">
										<p:input name="data" transform="oxf:xslt" href="aggregate('root',#uploadresult,#sparql)">
											<response xsl:version="2.0">
												<xsl:copy-of select="root/response/scene"/>
												<xsl:for-each select="root/sparql:sparql/sparql:results/sparql:result">
													<scene><xsl:value-of select="sparql:binding/sparql:literal"/></scene>
												</xsl:for-each>
												<xsl:if test="exists(root/response/error) or exists(root/parameters/error)">
													<error>
														<xsl:value-of select="root/response/error"/>
														<xsl:value-of select="root/parameters/error"/>
													</error>
												</xsl:if>
											</response>
										</p:input>
										<p:output name="data" id="result"/>
									</p:processor>
								</p:when>
								<p:otherwise>
									<!-- Otherwise, combine with assertions -->
									<p:processor name="oxf:identity">
										<p:input name="data" transform="oxf:xslt" href="aggregate('root',#uploadresult,#assertions)">
											<response xsl:version="2.0">
												<xsl:copy-of select="root/response/scene"/>
												<xsl:for-each select="root/assertions/assertion-failed">
													<scene><xsl:value-of select="."/></scene>
												</xsl:for-each>
												<xsl:if test="exists(root/response/error) or exists(root/assertions/assertion-failed)">
													<error>
														<xsl:value-of select="root/response/error"/>
														<xsl:for-each select="root/assertions/assertion-failed">
															<xsl:value-of select="."/><xsl:text>
</xsl:text>
														</xsl:for-each>
													</error>
												</xsl:if>
											</response>
										</p:input>
										<p:output name="data" id="result"/>
									</p:processor>
								</p:otherwise>
							</p:choose>
						</p:when>
						<p:otherwise>
							<p:processor name="oxf:identity">
								<p:input name="data">
									<response>
										<error>Unknown format (use xml, ttl or jsonld)</error>
									</response>
								</p:input>
								<p:output name="data" id="result"/>
							</p:processor>
						</p:otherwise>
					</p:choose>
<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config/>
	</p:input>
	<p:input name="data" href="#result"/>
</p:processor>
-->
					<!-- Cool URI implementation: respond with HTML or with JSON -->
					<p:choose href="#context" rdfs:label="build userinterface / return result">
						<p:when test="context/format='application/xml'" rdfs:label="xml response">
							<p:processor name="oxf:xml-serializer">
								<p:input name="config" transform="oxf:xslt" href="#result">
									<config xsl:version="2.0">
										<cache-control><use-local-cache>false</use-local-cache></cache-control>
										<status-code>
											<xsl:choose>
												<xsl:when test="exists(response/error)">409</xsl:when>
												<xsl:otherwise>200</xsl:otherwise>
											</xsl:choose>
										</status-code>
									</config>
								</p:input>
								<p:input name="data" href="#result"/>
							</p:processor>
						</p:when>
						<p:when test="context/format='text/plain'" rdfs:label="plain text response">
							<!-- Convert XML result to plain text -->
							<p:processor name="oxf:text-converter">
								<p:input name="config">
									<config>
										<encoding>utf-8</encoding>
									</config>
								</p:input>
								<p:input name="data" transform="oxf:xslt" href="#result">
									<result xsl:version="2.0">
										<xsl:for-each select="response/scene">
											<xsl:value-of select="."/><xsl:text>
</xsl:text>
										</xsl:for-each>
										<xsl:value-of select="response/error"/>
									</result>
								</p:input>
								<p:output name="data" id="converted" />
							</p:processor>
							<!-- Serialize -->
							<p:processor name="oxf:http-serializer">
								<p:input name="config" transform="oxf:xslt" href="#result">
									<config xsl:version="2.0">
										<cache-control><use-local-cache>false</use-local-cache></cache-control>
										<status-code>
											<xsl:choose>
												<xsl:when test="exists(response/error)">409</xsl:when>
												<xsl:otherwise>200</xsl:otherwise>
											</xsl:choose>
										</status-code>
									</config>
								</p:input>
								<p:input name="data" href="#converted"/>
							</p:processor>
						</p:when>
						<p:when test="context/format='application/json'" rdfs:label="json response">
							<p:processor name="oxf:xslt">
								<p:input name="config">
									<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
										<xsl:template match="/">
											<xsl:text>{"response":"</xsl:text>
											<xsl:choose>
												<xsl:when test="exists(response/error)">error</xsl:when>
												<xsl:otherwise>succes</xsl:otherwise>
											</xsl:choose>
											<xsl:text>"</xsl:text>
											<xsl:for-each select="response">
												<xsl:text> ",scene":[</xsl:text>
												<xsl:for-each select="scene">
													<xsl:if test="position()!=1"> ,</xsl:if>
													<xsl:text>"</xsl:text><xsl:value-of select="."/><xsl:text>"</xsl:text>
												</xsl:for-each>
												<xsl:text> ]</xsl:text>
												<xsl:if test="exists(error)">,"error":"<xsl:value-of select="replace(error,'\n','\\n')"/>"</xsl:if>
											</xsl:for-each>
											<xsl:text>}</xsl:text>
										</xsl:template>
									</xsl:stylesheet>
								</p:input>
								<p:input name="data" href="#result"/>
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
								<p:input name="config" transform="oxf:xslt" href="#result">
									<config xsl:version="2.0">
										<cache-control><use-local-cache>false</use-local-cache></cache-control>
										<status-code>
											<xsl:choose>
												<xsl:when test="exists(response/error)">409</xsl:when>
												<xsl:otherwise>200</xsl:otherwise>
											</xsl:choose>
										</status-code>
									</config>
								</p:input>
								<p:input name="data" href="#htmlres"/>
							</p:processor>
						</p:when>
						<p:otherwise rdfs:label="html response">
							<p:choose href="#result">
								<!-- Succes, so redirect back to original site -->
								<p:when test="not(exists(response/error))" rdfs:label="succes, redirect back to original site">
									<p:processor name="oxf:html-converter">
										<p:input name="config">
											<config>
												<encoding>utf-8</encoding>
												<version>5.0</version>
											</config>
										</p:input>
										<p:input name="data" transform="oxf:xslt" href="#context">
											<html xsl:version="2.0">
												<xsl:variable name="returnURL">
													<xsl:choose>
														<xsl:when test="matches(context/subject,'backstage/rep$') and context/back-of-stage!=''">
															<xsl:value-of select="substring-before(context/subject,'/rep')"/>
														</xsl:when>
														<xsl:otherwise><xsl:value-of select="context/subject"/></xsl:otherwise>
													</xsl:choose>
												</xsl:variable>
												<meta http-equiv="refresh" content="0;URL={$returnURL}?RESPONSE=succes" />
												<body><p>Succes</p></body>
											</html>
										</p:input>
										<p:output name="data" id="htmlres" />
									</p:processor>
								</p:when>
								<p:otherwise rdfs:label="error: show error page">
									<!-- Convert result to turtle -->
									<!-- This branch is only active when an error occurs: not very nice, the code is a duplicate of the code in the other branch ("show old data") -->
									<p:processor name="oxf:xslt" rdfs:label="create data from form input">
										<p:input name="config">
											<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
												<xsl:template match="/">
													<turtle>
														<xsl:value-of select="context/parameters/parameter[name='content']/value"/>
													</turtle>
												</xsl:template>
											</xsl:stylesheet>
										</p:input>
										<p:input name="data" href="#context"/>
										<p:output name="data" id="turtle"/>
									</p:processor>

									<!-- If the container contains some representations, we should also get those representations! -->
									<!-- TODO: A better solution should be the integration of container.xpl and query.xpl, this needs refactoring -->
									<!-- TODO: The p:choose also exists in the "show old data" branch: duplicate code, this needs refactoring -->
									<p:choose href="#containercontext" rdfs:label="look for representations">
										<p:when test="substring-after(contains/representation[1]/@uri,'http://bp4mc2.org/elmo/def#')!=''" rdfs:label="load representation from file (LDT backstage)">
											<!-- Special case: representation is a file (LDT backstage) -->
											<p:processor name="oxf:url-generator">
												<p:input name="config" transform="oxf:xslt" href="#context">
													<config xsl:version="2.0">
														<url>../representations/<xsl:value-of select="substring-after(contains/representation[1]/@uri,'http://bp4mc2.org/elmo/def#')"/>.xml</url>
														<content-type>application/xml</content-type>
													</config>
												</p:input>
												<p:output name="data" id="representations"/>
											</p:processor>
										</p:when>
										<p:when test="exists(container/contains/representation)" rdfs:label="fetch representations specified in containerspec">
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
												<p:input name="request" transform="oxf:xslt" href="aggregate('root',#context,#containercontext)">
													<parameters xsl:version="2.0">
														<query>
														<![CDATA[
															PREFIX elmo: <http://bp4mc2.org/elmo/def#>
															CONSTRUCT {
																?rep ?p ?o.
																?data ?dp ?do.
																?do ?dop ?doo.
																?doo ?doop ?dooo.
															}
															WHERE {
																GRAPH <]]><xsl:value-of select="root/context/representation-graph/@uri"/><![CDATA[> {
																	<]]><xsl:value-of select="root/container/url"/><![CDATA[> elmo:contains ?rep.
																	?rep ?p ?o.
																	?rep elmo:data ?data.
																	?data ?dp ?do.
																	OPTIONAL {
																		?do ?dop ?doo.
																		OPTIONAL {
																			?doo ?doop ?dooo
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
												<p:output name="response" id="representations"/>
											</p:processor>
										</p:when>
										<p:otherwise rdfs:label="no representations, empty pipe">
											<p:processor name="oxf:identity">
												<p:input name="data">
													<representations />
												</p:input>
												<p:output name="data" id="representations"/>
											</p:processor>
										</p:otherwise>
									</p:choose>

									<!-- Convert turtle to rdfa -->
									<p:processor name="oxf:xslt" rdfs:label="convert data to rdfa">
										<p:input name="data" href="aggregate('root',#context,#turtle,#containercontext,#result,#representations)"/>
										<p:input name="config" href="../transformations/ttl2rdfaform.xsl"/>
										<p:output name="data" id="rdfa"/>
									</p:processor>

									<!-- Transform rdfa to html -->
									<p:processor name="oxf:unsafe-xslt" rdfs:label="convert rdfa to html">
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
										<p:output name="data" id="htmlres" />
									</p:processor>
								</p:otherwise>
							</p:choose>
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
				<p:otherwise rdfs:label="show container data, no upload">
					<p:processor name="oxf:xforms-submission" rdfs:label="fetch container content from triplestore">
						<p:input name="submission" transform="oxf:xslt" href="#context">
							<xforms:submission method="get" xsl:version="2.0" action="{context/local-endpoint}">
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
								<query><xsl:value-of select="container/fetchquery"/></query>
								<default-graph-uri/>
								<error type=""/>
							</parameters>
						</p:input>
						<p:output name="response" id="sparql"/>
					</p:processor>

					<p:choose href="#context">

						<p:when test="context/format='application/json'">
							<!-- Transform -->
							<p:processor name="oxf:xslt">
								<p:input name="data" href="aggregate('results',#sparql)"/>
								<p:input name="config" href="../transformations/rdf2jsonld.xsl"/>
								<p:output name="data" id="jsonld"/>
							</p:processor>
							<!-- Convert XML result to plain text -->
							<p:processor name="oxf:text-converter">
								<p:input name="config">
									<config>
										<encoding>utf-8</encoding>
										<content-type>application/ld+json</content-type>
									</config>
								</p:input>
								<p:input name="data" href="#jsonld" />
								<p:output name="data" id="converted" />
							</p:processor>
							<!-- Serialize -->
							<p:processor name="oxf:http-serializer">
								<p:input name="config" href="#instancefixed" transform="oxf:xslt">
									<config xsl:version="2.0">
										<cache-control><use-local-cache>false</use-local-cache></cache-control>
										<xsl:if test="not(theatre/@cors='no')">
											<header>
												<name>Access-Control-Allow-Origin</name>
												<value>*</value>
											</header>
										</xsl:if>
									</config>
								</p:input>
								<p:input name="data" href="#converted"/>
							</p:processor>
						</p:when>
						<p:when test="context/format='application/xml'">
							<p:processor name="oxf:xml-serializer">
								<p:input name="config">
									<config>
										<encoding>utf-8</encoding>
										<content-type>application/rdf+xml</content-type>
									</config>
								</p:input>
								<p:input name="data" href="#sparql#xpointer(rdf:RDF[1])"/>
							</p:processor>
						</p:when>
						<p:when test="context/format='text/turtle'">
							<p:processor name="oxf:xslt">
								<p:input name="data" href="aggregate('results',#sparql)"/>
								<p:input name="config" href="../transformations/rdf2ttl.xsl"/>
								<p:output name="data" id="ttl"/>
							</p:processor>
							<!-- Convert XML result to plain text -->
							<p:processor name="oxf:text-converter">
								<p:input name="config">
									<config>
										<encoding>utf-8</encoding>
										<content-type>text/turtle</content-type>
									</config>
								</p:input>
								<p:input name="data" href="#ttl" />
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
						</p:when>
						<p:otherwise>

							<!-- Convert result to turtle -->
							<p:processor name="oxf:xslt" rdfs:label="create data from container content">
								<p:input name="data" href="aggregate('xmlresult',#sparql,#containercontext)"/>
								<p:input name="config" href="../transformations/rdf2ttl.xsl"/>
								<p:output name="data" id="ttl"/>
							</p:processor>

							<!-- If the container contains some representations, we should also get those representations! -->
							<!-- TODO: A better solution should be the integration of container.xpl and query.xpl, this needs refactoring -->
							<p:choose href="#containercontext" rdfs:label="look for representations">
								<p:when test="substring-after(container/contains/representation[1]/@uri,'http://bp4mc2.org/elmo/def#')!=''">
									<!-- Special case: representation is a file (LDT backstage) -->
									<p:processor name="oxf:url-generator">
										<p:input name="config" transform="oxf:xslt" href="#containercontext">
											<config xsl:version="2.0">
												<url>../representations/<xsl:value-of select="substring-after(container/contains/representation[1]/@uri,'http://bp4mc2.org/elmo/def#')"/>.xml</url>
												<content-type>application/xml</content-type>
											</config>
										</p:input>
										<p:output name="data" id="representations"/>
									</p:processor>
								</p:when>
								<p:when test="exists(container/contains/representation)">
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
										<p:input name="request" transform="oxf:xslt" href="aggregate('root',#context,#containercontext)">
											<parameters xsl:version="2.0">
												<query>
												<![CDATA[
													PREFIX elmo: <http://bp4mc2.org/elmo/def#>
													CONSTRUCT {
														?rep ?p ?o.
														?data ?dp ?do.
														?do ?dop ?doo.
														?doo ?doop ?dooo.
													}
													WHERE {
														GRAPH <]]><xsl:value-of select="root/context/representation-graph/@uri"/><![CDATA[> {
															<]]><xsl:value-of select="root/container/url"/><![CDATA[> elmo:contains ?rep.
															?rep ?p ?o.
															?rep elmo:data ?data.
															?data ?dp ?do.
															OPTIONAL {
																?do ?dop ?doo.
																OPTIONAL {
																	?doo ?doop ?dooo
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
										<p:output name="response" id="representations"/>
									</p:processor>
								</p:when>
								<p:otherwise>
									<p:processor name="oxf:identity">
										<p:input name="data">
											<representations />
										</p:input>
										<p:output name="data" id="representations"/>
									</p:processor>
								</p:otherwise>
							</p:choose>

							<!-- Convert turtle to rdfa -->
							<p:processor name="oxf:xslt" rdfs:label="convert data to rdfa">
								<p:input name="data" href="aggregate('root',#context,#ttl,aggregate('sparql',#sparql),#containercontext,#representations)"/>
								<p:input name="config" href="../transformations/ttl2rdfaform.xsl"/>
								<p:output name="data" id="rdfa"/>
							</p:processor>
							<!-- Transform rdfa to html -->
							<p:processor name="oxf:unsafe-xslt" rdfs:label="convert rdfa to html">
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
				</p:otherwise>
			</p:choose>
		</p:when>
		<p:otherwise rdfs:label="container-configuration not found: 404">
			<!-- Container doesn't exist in definition: 404 return code -->
			<p:processor name="oxf:identity">
				<p:input name="data">
					<parameters>
							<error-nr>404</error-nr>
					</parameters>
				</p:input>
				<p:output name="data" id="errortext"/>
			</p:processor>
			<p:processor name="oxf:xslt">
				<p:input name="data" href="aggregate('results',#context,#errortext)"/>
				<p:input name="config" href="../transformations/error2html.xsl"/>
				<p:output name="data" id="html"/>
			</p:processor>
			<p:processor name="oxf:html-converter">
				<p:input name="config">
					<config>
						<encoding>utf-8</encoding>
						<version>5.0</version>
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
