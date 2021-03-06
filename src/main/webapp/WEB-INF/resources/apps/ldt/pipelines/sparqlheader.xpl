<!--

    NAME     sparqlheader.xpl
    VERSION  1.25.0
    DATE     2020-07-19

    Copyright 2012-2020

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
    Debug option to show header information
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
		  xmlns:xforms="http://www.w3.org/2002/xforms"
          xmlns:oxf="http://www.orbeon.com/oxf/processors"
		  xmlns:sparql="http://www.w3.org/2005/sparql-results#"
		  xmlns:ev="http://www.w3.org/2001/xml-events"
		  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		  xmlns:xs="http://www.w3.org/2001/XMLSchema">

	<!-- Configuration> -->
	<p:param type="input" name="instance"/>

	<!-- Header information needed for Cool-URI implementation -->
	<p:processor name="oxf:request">
	  <p:input name="config">
		<config stream-type="xs:anyURI">
		  <include>/request</include>
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

	<p:choose href="#instance">
		<!-- Only show header information in development-mode -->
		<p:when test="theatre/@env='dev'">

			<p:processor name="oxf:xml-converter">
				<p:input name="config">
					<config>
						<encoding>utf-8</encoding>
					</config>
				</p:input>
				<p:input name="data" href="#request"/>
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

			<!-- Translate to sparql-result -->
			<p:processor name="oxf:xslt">
				<p:input name="config">
					<xsl:stylesheet version="2.0">
						<xsl:template match="/root">
							<sparql:sparql>
								<sparql:head>
									<sparql:variable name="p"/>
									<sparql:variable name="o"/>
								</sparql:head>
								<sparql:results distinct="false" ordered="true">
									<sparql:result>
										<sparql:binding name="p">
											<sparql:uri>urn:property</sparql:uri>
										</sparql:binding>
										<sparql:binding name="o">
											<sparql:literal>blub</sparql:literal>
										</sparql:binding>
									</sparql:result>
								</sparql:results>
							</sparql:sparql>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:input name="data" href="aggregate('root',#request,#roles,#url-written)"/>
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
		</p:when>
		<p:otherwise>
			<p:processor name="oxf:http-serializer">
				<p:input name="config">
					<config>
						<cache-control><use-local-cache>false</use-local-cache></cache-control>
						<status-code>404</status-code>
					</config>
				</p:input>
				<p:input name="data">
					<document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string" content-type="text/plain"/>
				</p:input>
			</p:processor>
		</p:otherwise>
	</p:choose>
	
</p:config>
