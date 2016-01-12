<!--

    NAME     container.xpl
    VERSION  1.5.1-SNAPSHOT
    DATE     2016-01-12

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
	
		<p:when test="exists(container/url)">
	
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
				<!-- Submission of new data -->
				<p:when test="root/context/parameters/parameter[name='container']/value=root/context/subject">
<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config/>
	</p:input>
	<p:input name="data" href="#containercontext"/>
</p:processor>
-->
					<p:choose href="#context">
						<!-- Upload file, xml -->
						<p:when test="context/parameters/parameter[name='file']/content-type='text/xml'">
							<p:choose href="#containercontext">
								<!-- non-rdf XML, use translator to convert to rdf/xml -->
								<p:when test="container/translator!=''">
									<!-- Fetch file -->
									<p:processor name="oxf:url-generator">
										<p:input name="config" transform="oxf:xslt" href="#context">
											<config xsl:version="2.0">
												<url><xsl:value-of select="context/parameters/parameter[name='file']/value"/></url>
												<content-type>application/xml</content-type>
											</config>
										</p:input>
										<p:output name="data" id="xmldata"/>
									</p:processor>
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
									<!-- Verwerken bestand: via aanroep van stored procedure in Virtuoso -->
									<!-- Let op: autorisatie in virtuoso.ini moet goed staan: -->
									<!--         DirsAllowed			= ., ../vad, ../../Tomcat/temp -->
									<p:processor name="oxf:sql">
										<p:input name="data" href="aggregate('root',#url-written,#containercontext)"/>
										<p:input name="config">
											<sql:config>
												<response>Bestand is ingeladen</response>
												<sql:connection>
													<sql:datasource>virtuoso</sql:datasource>
													<sql:execute>
														<sql:call>
															{call ldt.update_container(<sql:param type="xs:string" select="substring-after(root/url,'file:/')"/>,'xml',<sql:param type="xs:string" select="root/container/url"/>,<sql:param type="xs:string" select="root/container/version-url"/>,<sql:param type="xs:string" select="root/container/target-graph"/>,<sql:param type="xs:string" select="root/container/target-graph/@action"/>,<sql:param type="xs:string" select="root/container/postquery"/>)}
														</sql:call>
													</sql:execute>
												</sql:connection>
											</sql:config>
										</p:input>
										<p:output name="data" id="result"/>
									</p:processor>
								</p:when>
								<!-- Upload of file, asume rdf/xml -->
								<p:otherwise>
									<!-- Verwerken bestand: via aanroep van stored procedure in Virtuoso -->
									<!-- Let op: autorisatie in virtuoso.ini moet goed staan: -->
									<!--         DirsAllowed			= ., ../vad, ../../Tomcat/temp -->
									<p:processor name="oxf:sql">
										<p:input name="data" href="aggregate('root',#context,#containercontext)"/>
										<p:input name="config">
											<sql:config>
												<response>Bestand is ingeladen</response>
												<sql:connection>
													<sql:datasource>virtuoso</sql:datasource>
													<sql:execute>
														<sql:call>
															{call ldt.update_container(<sql:param type="xs:string" select="substring-after(root/context/parameters/parameter[name='file']/value,'file:/')"/>,'xml',<sql:param type="xs:string" select="root/container/url"/>,<sql:param type="xs:string" select="root/container/version-url"/>,<sql:param type="xs:string" select="root/container/target-graph"/>,<sql:param type="xs:string" select="root/container/target-graph/@action"/>,<sql:param type="xs:string" select="root/container/postquery"/>)}
														</sql:call>
													</sql:execute>
												</sql:connection>
											</sql:config>
										</p:input>
										<p:output name="data" id="result"/>
									</p:processor>
								</p:otherwise>
							</p:choose>
						</p:when>
						<!-- Upload of file, excel -->
						<p:when test="ends-with(context/parameters/parameter[name='file']/filename,'.xlsx') or context/parameters/parameter[name='file']/content-type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'">
							<!-- Fetch file -->
							<p:processor name="oxf:url-generator">
								<p:input name="config" transform="oxf:xslt" href="#context">
									<config xsl:version="2.0">
										<url><xsl:value-of select="context/parameters/parameter[name='file']/value"/></url>
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
								<p:input name="data" href="aggregate('root',#containercontext,#xmldata)"/>
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
							<!-- Verwerken bestand: via aanroep van stored procedure in Virtuoso -->
							<!-- Let op: autorisatie in virtuoso.ini moet goed staan: -->
							<!--         DirsAllowed			= ., ../vad, ../../Tomcat/temp -->
							<p:processor name="oxf:sql">
								<p:input name="data" href="aggregate('root',#url-written,#containercontext)"/>
								<p:input name="config">
									<sql:config>
										<response>Bestand is ingeladen</response>
										<sql:connection>
											<sql:datasource>virtuoso</sql:datasource>
											<sql:execute>
												<sql:call>
													{call ldt.update_container(<sql:param type="xs:string" select="substring-after(root/url,'file:/')"/>,'xml',<sql:param type="xs:string" select="root/container/url"/>,<sql:param type="xs:string" select="root/container/version-url"/>,<sql:param type="xs:string" select="root/container/target-graph"/>,<sql:param type="xs:string" select="root/container/target-graph/@action"/>,<sql:param type="xs:string" select="root/container/postquery"/>)}
												</sql:call>
											</sql:execute>
										</sql:connection>
									</sql:config>
								</p:input>
								<p:output name="data" id="result"/>
							</p:processor>
						</p:when>
						<!-- Upload of file, asume ttl -->
						<p:when test="context/parameters/parameter[name='file']/filename!=''">
							<!-- Verwerken bestand: via aanroep van stored procedure in Virtuoso -->
							<!-- Let op: autorisatie in virtuoso.ini moet goed staan: -->
							<!--         DirsAllowed			= ., ../vad, ../../Tomcat/temp -->
							<p:processor name="oxf:sql">
								<p:input name="data" href="aggregate('root',#context,#containercontext)"/>
								<p:input name="config">
									<sql:config>
										<response>Bestand is ingeladen</response>
										<sql:connection>
											<sql:datasource>virtuoso</sql:datasource>
											<sql:execute>
												<sql:call>
													{call ldt.update_container(<sql:param type="xs:string" select="substring-after(root/context/parameters/parameter[name='file']/value,'file:/')"/>,'ttl',<sql:param type="xs:string" select="root/container/url"/>,<sql:param type="xs:string" select="root/container/version-url"/>,<sql:param type="xs:string" select="root/container/target-graph"/>,<sql:param type="xs:string" select="root/container/target-graph/@action"/>,<sql:param type="xs:string" select="root/container/postquery"/>)}
												</sql:call>
											</sql:execute>
										</sql:connection>
									</sql:config>
								</p:input>
								<p:output name="data" id="result"/>
							</p:processor>
						</p:when>
						<!-- Content inline in text block -->
						<p:otherwise>
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
							<!-- Verwerken bestand: via aanroep van stored procedure in Virtuoso -->
							<!-- Let op: autorisatie in virtuoso.ini moet goed staan: -->
							<!--         DirsAllowed			= ., ../vad, ../../Tomcat/temp -->
							<p:processor name="oxf:sql">
								<p:input name="data" href="aggregate('root',#urlfile,#context,#containercontext)"/>
								<p:input name="config">
									<sql:config>
										<response>Bestand is ingeladen</response>
										<sql:connection>
											<sql:datasource>virtuoso</sql:datasource>
											<sql:execute>
												<sql:call>
													{call ldt.update_container(<sql:param type="xs:string" select="substring-after(root/url,'file:/')"/>,'ttl',<sql:param type="xs:string" select="root/container/url"/>,<sql:param type="xs:string" select="root/container/version-url"/>,<sql:param type="xs:string" select="root/container/target-graph"/>,<sql:param type="xs:string" select="root/container/target-graph/@action"/>,<sql:param type="xs:string" select="root/container/postquery"/>)}
												</sql:call>
											</sql:execute>
										</sql:connection>
									</sql:config>
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
					<p:choose href="#context">
						<p:when test="context/format='application/json'">
							<p:processor name="oxf:xslt">
								<p:input name="config">
									<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
										<xsl:template match="/">{"response":"<xsl:value-of select="root/response"/>"}</xsl:template>
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
										<body><p><xsl:value-of select="root/response"/></p></body>
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
<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config/>
	</p:input>
	<p:input name="data" href="#sparql"/>
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
