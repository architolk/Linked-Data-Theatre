<!--

    NAME     query.xpl
    VERSION  1.6.3
    DATE     2016-03-29

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
	Pipeline to proces read-request to the linked data theatre
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
		  xmlns:xforms="http://www.w3.org/2002/xforms"
		  xmlns:xxforms="http://orbeon.org/oxf/xml/xforms"
          xmlns:oxf="http://www.orbeon.com/oxf/processors"
		  xmlns:ev="http://www.w3.org/2001/xml-events"
		  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
		  xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
		  xmlns:res="http://www.w3.org/2005/sparql-results#"
          xmlns:sql="http://orbeon.org/oxf/xml/sql"
          xmlns:xs="http://www.w3.org/2001/XMLSchema"
		  xmlns:elmo="http://bp4mc2.org/elmo/def#"
>

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

	<!-- Create context -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="aggregate('root',#instance,#request)"/>
		<p:input name="config" href="../transformations/context.xsl"/>
		<p:output name="data" id="context"/>
	</p:processor>
	
	<!-- Look for possible query in query graph -->
	<!-- Execute SPARQL statement -->
	<p:choose href="#context">
		<p:when test="context/representation!=''">
			<!-- Explicitly defined representation, no query necessary -->
			<p:processor name="oxf:xslt">
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
						<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
						<xsl:template match="/context">
							<rdf:RDF>
								<rdf:Description rdf:about="{representation}"/>
							</rdf:RDF>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:input name="data" href="#context"/>
				<p:output name="data" id="representations"/>
			</p:processor>
		</p:when>
		<p:otherwise>
			<!-- Fetch query graphs from filter -->
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
								?rep rdf:type elmo:Representation.
								?rep elmo:layer ?layer.
							}
							WHERE {
								GRAPH <]]><xsl:value-of select="context/representation-graph/@uri"/><![CDATA[> {
									?rep rdf:type elmo:Representation
									OPTIONAL {?rep elmo:layer ?layer}
								}
								{
									{
										GRAPH <]]><xsl:value-of select="context/representation-graph/@uri"/><![CDATA[> {
											?rep elmo:url-pattern ?pattern.
											FILTER regex("]]><xsl:value-of select="context/url"/><![CDATA[",?pattern)
										}
									}
									UNION
									{
										GRAPH <]]><xsl:value-of select="context/representation-graph/@uri"/><![CDATA[> {
											?rep elmo:uri-pattern ?pattern.
											FILTER regex("]]><xsl:value-of select="context/subject"/><![CDATA[",?pattern)
										}
									}]]><xsl:if test="not(contains(context/subject,' '))"><![CDATA[
									UNION
									{
										GRAPH <]]><xsl:value-of select="context/representation-graph/@uri"/><![CDATA[> {
											?rep elmo:applies-to <]]><xsl:value-of select="context/subject"/><![CDATA[>
										}
									}
									UNION
									{
										GRAPH <]]><xsl:value-of select="context/representation-graph/@uri"/><![CDATA[> {
											?rep elmo:applies-to ?profile.
											?profile ?predicate ?object.
											FILTER isBlank(?profile)
										}
										{
											<]]><xsl:value-of select="context/subject"/><![CDATA[> ?predicate ?bobject
										}
										FILTER (str(?object)=str(?bobject))
									}]]></xsl:if><![CDATA[
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
		</p:otherwise>
	</p:choose>
	
	<p:choose href="#context">
		<!-- Use predefined representation from LDT for elmo-representations -->
		<p:when test="substring-after(context/representation,'http://bp4mc2.org/elmo/def#')!=''">
			<p:processor name="oxf:url-generator">
				<p:input name="config" transform="oxf:xslt" href="#context">
					<config xsl:version="2.0">
						<url>../representations/<xsl:value-of select="substring-after(context/representation,'http://bp4mc2.org/elmo/def#')"/>.xml</url>
						<content-type>application/xml</content-type>
					</config>
				</p:input>
				<p:output name="data" id="defquery"/>
			</p:processor>
		</p:when>
		<p:otherwise>
			<!-- Create query -->
			<p:processor name="oxf:xslt">
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:func="func" exclude-result-prefixes="func">
						<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
						<xsl:function name="func:order">
							<xsl:param name="layer"/>
							<xsl:choose>
								<xsl:when test="$layer='http://bp4mc2.org/elmo/def#TopLayer'">1</xsl:when>
								<xsl:when test="$layer='http://bp4mc2.org/elmo/def#DefaultLayer'">2</xsl:when>
								<xsl:when test="$layer='http://bp4mc2.org/elmo/def#BottomLayer'">3</xsl:when>
								<xsl:otherwise>9</xsl:otherwise>
							</xsl:choose>
						</xsl:function>
						<xsl:template match="/">
							<!-- First, find the right layer -->
							<xsl:variable name="layer1">
								<xsl:for-each select="/root/rdf:RDF/rdf:Description/elmo:layer"><xsl:sort select="func:order(@rdf:resource)"/>
									<xsl:if test="position()=1"><xsl:value-of select="@rdf:resource"/></xsl:if>
								</xsl:for-each>
							</xsl:variable>
							<xsl:variable name="layer">
								<xsl:choose>
									<xsl:when test="exists(/root/rdf:RDF/rdf:Description[not(exists(elmo:layer))])">
										<xsl:choose>
											<xsl:when test="$layer1='http://bp4mc2.org/elmo/def#TopLayer'"><xsl:value-of select="$layer1"/></xsl:when>
											<xsl:otherwise>http://bp4mc2.org/elmo/def#DefaultLayer</xsl:otherwise> <!-- No explicit layer means: defaultlayer (2) -->
										</xsl:choose>
									</xsl:when>
									<xsl:when test="$layer1=''">http://bp4mc2.org/elmo/def#DefaultLayer</xsl:when> <!-- No layer whatsoever means: defaultlayer (2) -->
									<xsl:otherwise><xsl:value-of select="$layer1"/></xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:variable name="representations">
								<xsl:choose>
									<!-- Show default representation if non exists -->
									<xsl:when test="root/context/query='' and not(exists(root/rdf:RDF/rdf:Description[elmo:layer/@rdf:resource=$layer or (not(exists(elmo:layer)) and $layer='http://bp4mc2.org/elmo/def#DefaultLayer')]))">
										<rep>&lt;rep://elmo.localhost/resource&gt;</rep>
									</xsl:when>
									<!-- Representations on the right layer -->
									<xsl:otherwise>
										<xsl:for-each select="root/rdf:RDF/rdf:Description[elmo:layer/@rdf:resource=$layer or (not(exists(elmo:layer)) and $layer='http://bp4mc2.org/elmo/def#DefaultLayer')]">
											<rep>&lt;<xsl:value-of select="@rdf:about"/>&gt;</rep>
										</xsl:for-each>
									</xsl:otherwise>
								</xsl:choose>
								<!-- Include explicitly included representations -->
								<xsl:for-each select="root/context/query[.!='']">
									<rep>&lt;<xsl:value-of select="."/>&gt;</rep>
								</xsl:for-each>
							</xsl:variable>
							<parameters layer="{$layer}">
								<query>
									<![CDATA[
									PREFIX elmo: <http://bp4mc2.org/elmo/def#>
									CONSTRUCT {
										?rep ?repp ?repo.
										?fragment ?fragmentp ?fragmento.
										?repchild ?repchildp ?repchildo.
										?fragmentchild ?fragmentchildp ?fragmentchildo.
										?form ?formp ?formo.
										?ff ?ffp ?ffo.
									}
									WHERE {
										GRAPH <]]><xsl:value-of select="root/context/representation-graph/@uri"/><![CDATA[>{
										]]><xsl:for-each select="$representations/rep">
											<xsl:if test="position()!=1">UNION</xsl:if>
											<![CDATA[{
												?rep ?repp ?repo.
												FILTER (?rep=]]><xsl:value-of select="."/><![CDATA[)
												OPTIONAL { ?rep elmo:fragment ?fragment. ?fragment ?fragmentp ?fragmento }
												OPTIONAL {
													?rep elmo:contains ?repchild.
													?repchild ?repchildp ?repchildo.
													OPTIONAL { ?repchild elmo:fragment ?fragmentchild. ?fragmentchild ?fragmentchildp ?fragmentchildo } 
												}
												OPTIONAL {
													?rep elmo:queryForm ?form.
													?form ?formp ?formo.
													?form elmo:fragment ?ff.
													?ff ?ffp ?ffo.
												}
											}]]></xsl:for-each><![CDATA[
										}
									}
									]]>
								</query>
								<default-graph-uri/>
								<error type=""/>
							</parameters>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:input name="data" href="aggregate('root',#context,#representations)"/>
				<p:output name="data" id="defquerytext"/>
			</p:processor>
			
			<!-- Fetch query definition(s) -->
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
				<p:input name="request" href="#defquerytext"/>
				<p:output name="response" id="defquery"/>
			</p:processor>
		</p:otherwise>
	</p:choose>
							
	<!-- Query from graph representation -->
	<p:processor name="oxf:xslt">
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
				<xsl:key name="bnodes" match="root/rdf:RDF/rdf:Description" use="@rdf:nodeID"/>
				<xsl:key name="resources" match="root/rdf:RDF/rdf:Description" use="@rdf:about"/>
				<xsl:key name="parameters" match="root/context/parameters/parameter" use="name"/>
				<xsl:template match="elmo:fragment">
					<xsl:if test="exists(@rdf:nodeID)">
						<xsl:variable name="appliesTo" select="key('bnodes',@rdf:nodeID)/elmo:applies-to"/>
						<fragment applies-to="{$appliesTo/@rdf:resource}{$appliesTo}">
							<xsl:copy-of select="key('bnodes',@rdf:nodeID)/(* except elmo:applies-to)"/>
						</fragment>
					</xsl:if>
					<xsl:if test="exists(@rdf:resource)">
						<xsl:variable name="appliesTo" select="key('resources',@rdf:resource)/elmo:applies-to"/>
						<fragment applies-to="{$appliesTo/@rdf:resource}{$appliesTo}">
							<xsl:copy-of select="key('resources',@rdf:resource)/(* except elmo:applies-to)"/>
						</fragment>
					</xsl:if>
				</xsl:template>
				<xsl:template match="elmo:queryForm[@rdf:resource='http://bp4mc2.org/elmo/def#GeoForm']">
					<xsl:variable name="satisfied">
						<xsl:if test="not(key('parameters','long')/value!='')">N</xsl:if>
						<xsl:if test="not(key('parameters','lat')/value!='')">N</xsl:if>
					</xsl:variable>
					<queryForm satisfied="{$satisfied}" geo="yes">
						<rdfs:label>TEST</rdfs:label>
						<elmo:fragment>
							<rdf:Description>
								<elmo:applies-to>long</elmo:applies-to>
								<elmo:constraint rdf:resource="http://bp4mc2.org/elmo/def#MandatoryConstraint"/>
							</rdf:Description>
						</elmo:fragment>
						<elmo:fragment>
							<rdf:Description>
								<elmo:applies-to>lat</elmo:applies-to>
								<elmo:constraint rdf:resource="http://bp4mc2.org/elmo/def#MandatoryConstraint"/>
							</rdf:Description>
						</elmo:fragment>
					</queryForm>
				</xsl:template>
				<xsl:template match="elmo:queryForm">
					<xsl:for-each select="key('resources',@rdf:resource)">
						<xsl:variable name="satisfied">
							<xsl:for-each select="elmo:fragment">
								<xsl:variable name="fragment" select="key('bnodes',@rdf:nodeID)"/>
								<xsl:if test="$fragment/elmo:constraint/@rdf:resource='http://bp4mc2.org/elmo/def#MandatoryConstraint'">
									<xsl:if test="$fragment/elmo:applies-to!='' and not(key('parameters',$fragment/elmo:applies-to)/value!='')">N</xsl:if>
								</xsl:if>
							</xsl:for-each>
						</xsl:variable>
						<queryForm satisfied="{$satisfied}">
							<xsl:copy-of select="rdfs:label"/>
							<xsl:apply-templates select="elmo:fragment"/>
						</queryForm>
					</xsl:for-each>
				</xsl:template>
				<xsl:template match="elmo:link">
					<link uri="{@rdf:resource}"/>
				</xsl:template>
				<xsl:template match="elmo:use">
					<parameter name="{substring-after(@rdf:resource,'#')}" uri="{@rdf:resource}"/>
				</xsl:template>
				<xsl:template match="html:stylesheet">
					<stylesheet href="{.}"/>
				</xsl:template>
				<xsl:template match="/root">
					<view>
						<xsl:apply-templates select="rdf:RDF/rdf:Description[rdf:type/@rdf:resource!='http://bp4mc2.org/elmo/def#fragment']/html:stylesheet"/>
						<xsl:for-each-group select="rdf:RDF/rdf:Description[exists(elmo:data[1]) or exists(elmo:query[1]) or exists(elmo:service[1]) or exists(elmo:operation[1])]" group-by="@rdf:about"><xsl:sort select="concat(elmo:index[1],'~')"/>
							<xsl:choose>
								<!-- Special: data is available in a file (used only for ELMO-LDT related content -->
								<xsl:when test="exists(elmo:file[1])">
									<representation uri="{@rdf:about}" index="{position()}">
										<xsl:if test="exists(elmo:appearance[1])"><xsl:attribute name="appearance"><xsl:value-of select="elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
										<xsl:apply-templates select="elmo:queryForm"/>
										<xsl:apply-templates select="elmo:fragment"/>
										<file><xsl:value-of select="elmo:file[1]"/></file>
									</representation>
								</xsl:when>
								<xsl:when test="exists(elmo:operation[1])">
									<representation uri="{@rdf:about}" index="{position()}">
										<xsl:if test="exists(elmo:appearance[1])"><xsl:attribute name="appearance"><xsl:value-of select="elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
										<xsl:apply-templates select="elmo:queryForm"/>
										<xsl:apply-templates select="elmo:fragment"/>
										<xsl:apply-templates select="elmo:use"/>
										<service uri="{elmo:operation[1]/@rdf:resource}"/>
									</representation>
								</xsl:when>
								<xsl:when test="exists(elmo:service[1])">
									<representation uri="{@rdf:about}" index="{position()}">
										<xsl:if test="exists(elmo:appearance[1])"><xsl:attribute name="appearance"><xsl:value-of select="elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
										<xsl:apply-templates select="elmo:queryForm"/>
										<xsl:apply-templates select="elmo:fragment"/>
										<xsl:apply-templates select="elmo:use"/>
										<service><xsl:value-of select="elmo:service[1]/@rdf:resource"/></service>
									</representation>
								</xsl:when>
								<xsl:when test="exists(elmo:data[1])">
									<!-- Als er letterlijke data wordt opgevraagd, dan deze straks ophalen via de query -->
									<representation uri="{@rdf:about}" index="{position()}" endpoint="{/root/context/configuration-endpoint}">
										<xsl:if test="exists(elmo:appearance[1])"><xsl:attribute name="appearance"><xsl:value-of select="elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
										<xsl:if test="exists(elmo:operation[1])"><xsl:attribute name="operation"><xsl:value-of select="elmo:operation[1]/@rdf:resource"/></xsl:attribute></xsl:if>
										<xsl:apply-templates select="elmo:queryForm"/>
										<xsl:apply-templates select="elmo:fragment"/>
										<query>
											<![CDATA[
											PREFIX elmo: <http://bp4mc2.org/elmo/def#>
											CONSTRUCT {
												?s?p?o.
												?sc?pc?oc.
												?scc?pcc?occ.
											}
											WHERE { GRAPH <]]><xsl:value-of select="/root/context/representation-graph/@uri"/><![CDATA[>
											{<]]><xsl:value-of select="@rdf:about"/><![CDATA[> elmo:data ?s.
												?s?p?o.
												OPTIONAL {
													?s elmo:data ?sc.
													?sc ?pc ?oc.
													OPTIONAL {
														?sc elmo:data ?scc.
														?scc ?pcc ?occ.
													}
												}
											}}
											]]>
										</query>
									</representation>
								</xsl:when>
								<xsl:when test="exists(elmo:query[1])">
									<representation uri="{@rdf:about}" index="{position()}">
										<xsl:if test="exists(elmo:endpoint[1])"><xsl:attribute name="endpoint"><xsl:value-of select="elmo:endpoint[1]/@rdf:resource"/></xsl:attribute></xsl:if>
										<xsl:if test="exists(elmo:appearance[1])"><xsl:attribute name="appearance"><xsl:value-of select="elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
										<xsl:if test="exists(elmo:operation[1])"><xsl:attribute name="operation"><xsl:value-of select="elmo:operation[1]/@rdf:resource"/></xsl:attribute></xsl:if>
										<xsl:if test="exists(elmo:container[1])"><xsl:attribute name="container"><xsl:value-of select="elmo:container[1]/@rdf:resource"/></xsl:attribute></xsl:if>
										<xsl:apply-templates select="elmo:queryForm"/>
										<xsl:apply-templates select="elmo:fragment"/>
										<query><xsl:value-of select="elmo:query[1]"/></query>
										<xsl:apply-templates select="elmo:link"/>
									</representation>
								</xsl:when>
								<!-- No data, no query -->
								<xsl:otherwise/>
							</xsl:choose>
						</xsl:for-each-group>
					</view>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:input name="data" href="aggregate('root',#defquery,#context)"/>
		<p:output name="data" id="querytext"/>
	</p:processor>
<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config/>
	</p:input>
	<p:input name="data" href="#querytext"/>
</p:processor>
-->
	<!-- More than one query is possible -->
	<p:for-each href="#querytext" select="/view/representation[not(exists(service))]" root="results" id="sparql">
	
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
			<!-- File content, elmo:query triple is ignored -->
			<p:when test="exists(representation/file)">
				<p:processor name="oxf:url-generator">
					<p:input name="config" transform="oxf:xslt" href="current()">
						<config xsl:version="2.0">
							<url>../data/<xsl:value-of select="representation/file"/>.xml</url>
							<content-type>application/xml</content-type>
						</config>
					</p:input>
					<p:output name="data" ref="sparql"/>
				</p:processor>
			</p:when>
			<!-- TextSearchAppearance is NOT a regular SPARQL query, but a specific SQL query. elmo:query triple is ignored -->
			<p:when test="representation/@appearance='http://bp4mc2.org/elmo/def#TextSearchAppearance'">
				<!-- Execute SQL -->
				<p:processor name="oxf:sql">
					<p:input name="data" href="#instance"/>
					<p:input name="config" transform="oxf:xslt" href="#context">
						<sql:config xsl:version="2.0">
							<xsl:variable name="term" select="context/parameters/parameter[name='term']/value"/>
							<xsl:variable name="termvector">
								<xsl:for-each select="tokenize($term,'\s+')">
									<xsl:if test="position()!=1">','</xsl:if>
									<xsl:value-of select="."/>
								</xsl:for-each>
							</xsl:variable>
							<xsl:variable name="termquery">
								<xsl:for-each select="tokenize($term,'\s+')">
									<xsl:if test="position()!=1"> and </xsl:if>
									<xsl:value-of select="."/>
								</xsl:for-each>
							</xsl:variable>
							<sqldata>
								<sql:connection>
								<sql:datasource>virtuoso</sql:datasource>
									<sql:execute>
										<sql:query>
											select publication_uri,search_excerpt(vector('<xsl:value-of select="$termvector"/>'),cast(tekst as varchar),10000,500,80) as tekst, xmltype(tekst).extract('@uri') as fragment_uri,publication_uri,xmltype(tekst).extract('*[@class="title"]/text()') as publication_label
											from gob.xmldoc
											where xcontains(document,'//*[exists(@uri) and text-contains(.,"<xsl:value-of select="$termquery"/>")]',tekst)
											and valid_from&lt;=curdate()
											and (valid_until&gt;curdate() or valid_until is null)
										</sql:query>
										<sql:result-set>
											<rows>
												<sql:row-iterator>
													<row>
														<column name="reg" type="rui"/>
														<column name="_uri" type="uri"><sql:get-column-value type="xs:string" column="publication_uri"/></column>
														<column name="res_label" type="label"><sql:get-column-value column="publication_label"/></column>
														<column name="res" type="uri"><sql:get-column-value type="xs:string" column="publication_uri"/>#<sql:get-column-value column="fragment_uri"/></column>
														<column name="tekst" type="label"><sql:get-column-value column="tekst"/></column>
													</row>
												</sql:row-iterator>
											</rows>
										</sql:result-set>
									</sql:execute>
								</sql:connection>
							</sqldata>
						</sql:config>
					</p:input>
					<p:output name="data" id="data"/>
				</p:processor>

				<!-- Get metadata for search results -->
				<p:processor name="oxf:xforms-submission">
					<p:input name="submission" transform="oxf:xslt" href="#context">
						<xforms:submission method="get" xsl:version="2.0" action="{context/configuration-endpoint}">
							<xforms:header>
								<xforms:name>Accept</xforms:name>
								<xforms:value>application/sparql-results+xml</xforms:value>
							</xforms:header>
							<xforms:setvalue ev:event="xforms-submit-error" ref="error" value="event('response-body')"/>
							<xforms:setvalue ev:event="xforms-submit-error" ref="error/@type" value="event('error-type')"/>
						</xforms:submission>
					</p:input>
					<p:input name="request" transform="oxf:xslt" href="#data">
						<parameters xsl:version="2.0">
							<query>
							<![CDATA[
								PREFIX elmo: <http://bp4mc2.org/elmo/def#>
								PREFIX md: <http://xmlns.org/2012/05/02/metadoc#>
								SELECT ?uri ?reg ?reg_label
								WHERE {
									GRAPH <http://wetten.overheid.nl#> {
										?reg rdfs:label ?reg_label.
										?exp md:realizes ?reg.
										?exp md:fragment ?uri.
										FILTER (?uri != ?uri]]>
										<xsl:for-each-group select="sqldata/rows/row/column[@name='_uri']" group-by=".">
											<xsl:text> or ?uri=&lt;</xsl:text><xsl:value-of select="."/><xsl:text>&gt;</xsl:text>
										</xsl:for-each-group>
										<![CDATA[)
									}
								}
							]]>
							</query>
							<default-graph-uri/>
							<error type=""/>
						</parameters>
					</p:input>
					<p:output name="response" id="metadata"/>
				</p:processor>
				
				<!-- Transform SQL to RDF -->
				<p:processor name="oxf:xslt">
					<p:input name="data" href="aggregate('root',#data,#metadata)"/>
					<p:input name="config" href="../transformations/sql2rdf.xsl"/>
					<p:output name="data" ref="sparql"/>
				</p:processor>
				
			</p:when>
			<p:otherwise>
				<!-- Create sparql request -->
				<p:processor name="oxf:xslt">
					<p:input name="config">
						<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
							<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
							<xsl:template match="parameter" mode="replace">
								<xsl:choose>
									<xsl:when test="exists(following-sibling::*[1])">
										<xsl:variable name="query"><xsl:apply-templates select="following-sibling::*[1]" mode="replace"/></xsl:variable>
										<xsl:value-of select="replace($query,concat('@',upper-case(name),'@'),value)"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="replace(/root/representation/query,concat('@',upper-case(name),'@'),value)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:template>
							<xsl:template match="/root">
								<parameters>
									<!-- Currentmoment kan nog beinvloed worden door de date-parameter, beetje raar, afkomstig uit andere implementatie -->
									<xsl:variable name="currentmoment">
										<xsl:value-of select="root/context/parameters/parameter[name='date']"/>
										<xsl:value-of select="substring(xs:string(current-dateTime()),1+string-length(root/context/parameters/parameter[name='date']),255)"/>
									</xsl:variable>
									<xsl:variable name="query1">
										<xsl:apply-templates select="/root/context/parameters/parameter[1]" mode="replace"/>
										<xsl:if test="not(exists(/root/context/parameters/parameter))"><xsl:value-of select="/root/representation/query"/></xsl:if>
									</xsl:variable>
									<xsl:variable name="query2" select="replace($query1,'@LANGUAGE@',/root/context/language)"/>
									<xsl:variable name="query3" select="replace($query2,'@USER@',/root/context/user)"/>
									<xsl:variable name="query4" select="replace($query3,'@CURRENTMOMENT@',format-dateTime($currentmoment,'[Y0001]/[M01]/[D01]/[H01]/[m01]/[s01]'))"/>
									<xsl:variable name="query5" select="replace($query4,'@STAGE@',/root/context/back-of-stage)"/>
									<query><xsl:value-of select="replace($query5,'@SUBJECT@',/root/context/subject)"/></query>
									<default-graph-uri />
									<error type=""/>
								</parameters>
							</xsl:template>
						</xsl:stylesheet>
					</p:input>
					<p:input name="data" href="aggregate('root',current(),#context)"/>
					<p:output name="data" id="query"/>
				</p:processor>
				
				<!-- Get endpoint -->
				<p:processor name="oxf:xslt">
					<p:input name="config">
						<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
							<xsl:template match="/root">
								<xsl:variable name="endpoint">
									<xsl:value-of select="representation/@endpoint"/>
									<xsl:if test="not(representation/@endpoint!='')"><xsl:value-of select="context/local-endpoint"/></xsl:if>
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

	<!-- Look up fragments if applicable (TextAppearance) -->
	<p:for-each href="#querytext" select="view/representation[@appearance='http://bp4mc2.org/elmo/def#TextAppearance']" root="docs" id="text">
		<!-- Splits document URL van fragment xpath -->
		<p:processor name="oxf:xslt">
			<p:input name="data" href="aggregate('root',current(),#sparql)"/>
			<p:input name="config">
				<xsl:stylesheet version="2.0">
					<xsl:template match="/root">
						<xsl:variable name="representation-uri" select="representation/@uri"/>
						<xsl:variable name="index" select="representation/@index"/>
						<xsl:variable name="fragment"><xsl:value-of select="results/rdf:RDF[position()=$index]/rdf:Description[1]/@rdf:about"/></xsl:variable>
						<params>
							<fragment>
								<xsl:text>//fragment</xsl:text>
								<xsl:if test="substring-after($fragment,'#')!=''">/<xsl:value-of select="substring-after($fragment,'#')"/></xsl:if>
							</fragment>
							<publication-uri>
								<xsl:value-of select="substring-before(concat($fragment,'#'),'#')"/>
							</publication-uri>
							<representation-uri>
								<xsl:value-of select="representation/@uri"/>
							</representation-uri>
						</params>
					</xsl:template>
				</xsl:stylesheet>
			</p:input>
			<p:output name="data" id="params"/>
		</p:processor>
		<!-- Ophalen document uit relationele database -->
		<p:processor name="oxf:sql">
			<p:input name="data" href="#params"/>
			<p:input name="config" transform="oxf:xslt" href="#params">
				<sql:config xsl:version="2.0">
					<xmldocs uri="{params/representation-uri}">
						<sql:connection>
						<sql:datasource>virtuoso</sql:datasource>
							<sql:execute>
								<sql:query>
									select publication_uri,publication_datetime,part from xmldoc
									where xpath_contains(document,<sql:param type="xs:string" select="params/fragment"/>,part)
									and publication_uri=<sql:param type="xs:string" select="params/publication-uri"/>
								</sql:query>
								<sql:result-set>
									<sql:row-iterator>
										<xmldoc>
											<publication-uri>
												<sql:get-column-value type="xs:string" column="publication_uri"/>
											</publication-uri>
											<publication-datetime>
												<sql:get-column-value type="xs:dateTime" column="publication_datetime"/>
											</publication-datetime>
											<document>
												<sql:get-column-value type="odt:xmlFragment" column="part" xmlns:odt="http://orbeon.org/oxf/xml/datatypes"/>
											</document>
										</xmldoc>
									</sql:row-iterator>
								</sql:result-set>
							</sql:execute>
						</sql:connection>
					</xmldocs>
				</sql:config>
			</p:input>
			<p:output name="data" ref="text"/>
		</p:processor>
	</p:for-each>
	
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
						<public-doctype>-//W3C//DTD XHTML 1.0 Strict//EN</public-doctype>
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
			<!-- Render to specific presentation format -->
			<p:choose href="#context">
				<!-- XML -->
				<p:when test="context/format='application/xml'">
					<p:processor name="oxf:xml-serializer">
						<p:input name="config">
							<config/>
						</p:input>
						<p:input name="data" href="aggregate('results',#sparql#xpointer(/results/*))"/>
					</p:processor>
				</p:when>
				<!-- RDF/XML -->
				<p:when test="context/format='application/rdf+xml'">
					<p:processor name="oxf:xml-serializer">
						<p:input name="config">
							<config/>
						</p:input>
						<p:input name="data" href="#sparql#xpointer((/results/res:sparql|/results/rdf:RDF)[1])"/>
					</p:processor>
				</p:when>
				<!-- Show query instead of the result -->
				<p:when test="context/format='application/x.elmo.query'">
					<p:processor name="oxf:xml-serializer">
						<p:input name="config">
							<config/>
						</p:input>
						<p:input name="data" href="#querytext"/>
					</p:processor>
				</p:when>
				<!-- Plain text -->
				<p:when test="context/format='text/plain'">
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#sparql"/>
						<p:input name="config" href="../transformations/rdf2txt.xsl"/>
						<p:output name="data" id="txt"/>
					</p:processor>
					<!-- Convert XML result to plain text -->
					<p:processor name="oxf:text-converter">
						<p:input name="config">
							<config>
								<encoding>utf-8</encoding>
							</config>
						</p:input>
						<p:input name="data" href="#txt" />
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
				<!-- Turtle -->
				<p:when test="context/format='text/turtle'">
					<!-- Transform -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#sparql"/>
						<p:input name="config" href="../transformations/rdf2ttl.xsl"/>
						<p:output name="data" id="ttl"/>
					</p:processor>
					<!-- Convert XML result to plain text -->
					<p:processor name="oxf:text-converter">
						<p:input name="config">
							<config>
								<encoding>utf-8</encoding>
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
				<!-- JSON (LD) -->
				<p:when test="context/format='application/json'">
					<!-- Transform -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#sparql"/>
						<p:input name="config" href="../transformations/rdf2jsonld.xsl"/>
						<p:output name="data" id="jsonld"/>
					</p:processor>
					<!-- Convert XML result to plain text -->
					<p:processor name="oxf:text-converter">
						<p:input name="config">
							<config>
								<encoding>utf-8</encoding>
							</config>
						</p:input>
						<p:input name="data" href="#jsonld" />
						<p:output name="data" id="converted" />
					</p:processor>
					<!-- Serialize -->
					<p:processor name="oxf:http-serializer">
						<p:input name="config">
							<config>
								<cache-control><use-local-cache>false</use-local-cache></cache-control>
								<header>
									<name>Access-Control-Allow-Origin</name>
									<value>*</value>
								</header>
							</config>
						</p:input>
						<p:input name="data" href="#converted"/>
					</p:processor>
				</p:when>
				<!-- Graphml -->
				<p:when test="context/format='application/graphml+xml'">
					<!-- Transform -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#sparql"/>
						<p:input name="config" href="../transformations/rdf2graphml.xsl"/>
						<p:output name="data" id="graphml"/>
					</p:processor>
					<!-- Convert XML result to XML document -->
					<p:processor name="oxf:xml-converter">
						<p:input name="config">
							<config>
								<encoding>utf-8</encoding>
							</config>
						</p:input>
						<p:input name="data" href="#graphml"/>
						<p:output name="data" id="converted"/>
					</p:processor>
					<!-- Serialize -->
					<p:processor name="oxf:http-serializer">
						<p:input name="config">
							<config>
								<content-type>application/xml</content-type>
								<header>
									<name>Content-Disposition</name>
									<value>attachment; filename=result.graphml</value>
								</header>
							</config>
						</p:input>
						<p:input name="data" href="#converted"/>
					</p:processor>
				</p:when>
				<!-- Graphml yed -->
				<p:when test="context/format='application/x.elmo.yed'">
					<!-- Transform -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="aggregate('root',#querytext,#sparql)"/>
						<p:input name="config" href="../transformations/rdf2yed.xsl"/>
						<p:output name="data" id="graphml"/>
					</p:processor>
					<!-- Convert XML result to XML document -->
					<p:processor name="oxf:xml-converter">
						<p:input name="config">
							<config>
								<encoding>utf-8</encoding>
							</config>
						</p:input>
						<p:input name="data" href="#graphml"/>
						<p:output name="data" id="converted"/>
					</p:processor>
					<!-- Serialize -->
					<p:processor name="oxf:http-serializer">
						<p:input name="config">
							<config>
								<content-type>application/xml</content-type>
								<header>
									<name>Content-Disposition</name>
									<value>attachment; filename=result.graphml</value>
								</header>
							</config>
						</p:input>
						<p:input name="data" href="#converted"/>
					</p:processor>
				</p:when>
				<!-- XMI -->
				<p:when test="context/format='application/vnd.xmi+xml'">
					<!-- Transform -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#sparql"/>
						<p:input name="config" href="../transformations/rdf2xmi.xsl"/>
						<p:output name="data" id="xmi"/>
					</p:processor>
					<!-- Convert XML result to XML document -->
					<p:processor name="oxf:xml-converter">
						<p:input name="config">
							<config>
								<encoding>utf-8</encoding>
							</config>
						</p:input>
						<p:input name="data" href="#xmi"/>
						<p:output name="data" id="converted"/>
					</p:processor>
					<!-- Serialize -->
					<p:processor name="oxf:http-serializer">
						<p:input name="config">
							<config>
								<content-type>application/xml</content-type>
								<header>
									<name>Content-Disposition</name>
									<value>attachment; filename=result.xmi.xml</value>
								</header>
							</config>
						</p:input>
						<p:input name="data" href="#converted"/>
					</p:processor>
				</p:when>
				<!-- Interactive SVG+HTML representation -->
				<p:when test="context/format='application/x.elmo.svg+xml'">
					<!-- Transform -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#context"/>
						<p:input name="config" href="../transformations/rdf2svgi.xsl"/>
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
				<!-- JSON data in D3 format for graph representation -->
				<p:when test="context/format='application/x.elmo.d3+json'">
					<!-- Transform -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="aggregate('root',#context,#sparql)"/>
						<p:input name="config" href="../transformations/rdf2graphjson.xsl"/>
						<p:output name="data" id="graphjson"/>
					</p:processor>
					<!-- Convert XML result to plain text -->
					<p:processor name="oxf:text-converter">
						<p:input name="config">
							<config>
								<encoding>utf-8</encoding>
							</config>
						</p:input>
						<p:input name="data" href="#graphjson" />
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
				<!-- XLSX -->
				<p:when test="context/format='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'">
					<!-- Transform -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#sparql"/>
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
				<!-- DOCX -->
				<p:when test="context/format='application/vnd.openxmlformats-officedocument.wordprocessingml.document'">
					<!-- Transform -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="#sparql"/>
						<p:input name="config" href="../transformations/rdf2doc.xsl"/>
						<p:output name="data" id="docxml"/>
					</p:processor>
					<!-- Serialize -->
					<p:processor name="oxf:word-serializer">
						<p:input name="config">
							<config>
								<content-type>application/vnd.openxmlformats-officedocument.wordprocessingml.document</content-type>
								<header>
									<name>Content-Disposition</name>
									<value>attachment; filename=result.docx</value>
								</header>
							</config>
						</p:input>
						<p:input name="data" href="#docxml"/>
					</p:processor>
				</p:when>
				<!-- HTML -->
				<p:otherwise>
					<!-- Transform to annotated rdf -->
					<p:processor name="oxf:xslt">
						<p:input name="data" href="aggregate('root',#context,#querytext,#sparql,#text)"/>
						<p:input name="config" href="../transformations/rdf2rdfa.xsl"/>
						<p:output name="data" id="rdfa"/>
					</p:processor>
					<p:choose href="#context">
						<p:when test="context/format='application/x.elmo.rdfa'">
							<p:processor name="oxf:xml-serializer">
								<p:input name="config">
									<config/>
								</p:input>
								<p:input name="data" href="#rdfa"/>
							</p:processor>
						</p:when>
						<p:otherwise>
							<!-- Transform -->
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
				</p:otherwise>
			</p:choose>
		</p:otherwise>
	</p:choose>

</p:config>
