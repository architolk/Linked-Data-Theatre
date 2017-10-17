<!--

    NAME     rdf2view.xsl
    VERSION  1.19.1-SNAPSHOT
    DATE     2017-10-17

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
	Transforms RDF configuration result into a more manageable view XML document
-->

<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
>

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>

<xsl:key name="bnodes" match="root/rdf:RDF/rdf:Description" use="@rdf:nodeID"/>
<xsl:key name="resources" match="root/rdf:RDF/rdf:Description" use="@rdf:about"/>
<xsl:key name="parameters" match="root/context/parameters/parameter" use="name"/>

<xsl:template match="elmo:fragment">
	<xsl:if test="exists(@rdf:nodeID)">
		<xsl:variable name="appliesTo" select="key('bnodes',@rdf:nodeID)/elmo:applies-to"/>
		<xsl:variable name="satisfied">
			<xsl:for-each select="key('resources',key('bnodes',@rdf:nodeID)/elmo:valuesFrom/@rdf:resource)[elmo:with-parameter!=$appliesTo]">
				<xsl:if test="not(exists(key('parameters',elmo:with-parameter)))">N</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<fragment applies-to="{$appliesTo/@rdf:resource}{$appliesTo}" satisfied="{$satisfied}">
			<xsl:copy-of select="key('bnodes',@rdf:nodeID)/(* except elmo:applies-to)"/>
		</fragment>
	</xsl:if>
	<xsl:if test="exists(@rdf:resource)">
		<xsl:variable name="appliesTo" select="key('resources',@rdf:resource)/elmo:applies-to"/>
		<xsl:variable name="satisfied">
			<xsl:for-each select="key('resources',key('resources',@rdf:resource)/elmo:valuesFrom/@rdf:resource)[elmo:with-parameter!=$appliesTo]">
				<xsl:if test="not(exists(key('parameters',elmo:with-parameter)))">N</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<fragment applies-to="{$appliesTo/@rdf:resource}{$appliesTo}" satisfied="{$satisfied}">
			<xsl:copy-of select="key('resources',@rdf:resource)/(* except elmo:applies-to)"/>
		</fragment>
	</xsl:if>
</xsl:template>

<xsl:template match="elmo:queryForm[@rdf:resource='http://bp4mc2.org/elmo/def#GeoForm']">
	<xsl:variable name="satisfied">
		<xsl:if test="not(key('parameters','long')/value[1]!='')">N</xsl:if>
		<xsl:if test="not(key('parameters','lat')/value[1]!='')">N</xsl:if>
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
					<xsl:if test="$fragment/elmo:applies-to!='' and not(key('parameters',$fragment/elmo:applies-to)/value[1]!='')">N</xsl:if>
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

<xsl:template match="html:stylesheet">
	<stylesheet href="{.}"/>
</xsl:template>

<xsl:template match="*" mode="label">
	<xsl:variable name="language" select="/root/context/language"/>
	<xsl:choose>
		<xsl:when test="rdfs:label[@xml:lang=$language]!=''"><xsl:value-of select="rdfs:label[@xml:lang=$language]"/></xsl:when> <!-- First choice: language of browser -->
		<xsl:when test="rdfs:label[not(exists(@xml:lang))]!=''"><xsl:value-of select="rdfs:label[not(exists(@xml:lang))]"/></xsl:when> <!-- Second choice: no language -->
		<xsl:when test="rdfs:label[@xml:lang='nl']!=''"><xsl:value-of select="rdfs:label[@xml:lang='nl']"/></xsl:when> <!-- Third choice: dutch -->
		<xsl:when test="rdfs:label[@xml:lang='en']!=''"><xsl:value-of select="rdfs:label[@xml:lang='en']"/></xsl:when> <!-- Fourth choice: english -->
		<xsl:otherwise><xsl:value-of select="rdfs:label[1]"/></xsl:otherwise> <!-- If all fails, the first label -->
	</xsl:choose>
</xsl:template>

<xsl:template match="/root">
	<view>
		<xsl:apply-templates select="rdf:RDF/rdf:Description[rdf:type/@rdf:resource!='http://bp4mc2.org/elmo/def#fragment']/html:stylesheet"/>
		<xsl:for-each-group select="rdf:RDF/rdf:Description[exists(elmo:data[1]) or exists(elmo:query[.!='']) or exists(elmo:service[1]) or exists(elmo:webpage[1]) or exists(elmo:queryForm[1]) or rdf:type/@rdf:resource='http://bp4mc2.org/elmo/def#Production']" group-by="@rdf:about"><xsl:sort select="concat(elmo:index[1],'~')"/>
			<xsl:variable name="with-filter-notok">
				<xsl:for-each select="elmo:with-parameter">
					<xsl:if test="not(exists(key('parameters', .)) or (.='subject' and /root/context/subject!=''))">x</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="without-filter-notok">
				<xsl:for-each select="elmo:without-parameter">
					<xsl:if test="exists(key('parameters', .)) or (.='subject' and /root/context/subject!='')">x</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			<xsl:if test="$with-filter-notok='' and $without-filter-notok=''">
				<xsl:choose>
					<!-- Production -->
					<xsl:when test="rdf:type/@rdf:resource='http://bp4mc2.org/elmo/def#Production'">
						<!-- production results in a special representation  -->
						<!-- it will contain the combined results of the scenes -->
						<production uri="{@rdf:about}" index="{position()}" appearance="http://bp4mc2.org/elmo/def#ShortTableAppearance">
							<xsl:if test="exists(elmo:endpoint[1])"><xsl:attribute name="endpoint"><xsl:value-of select="elmo:endpoint[1]/@rdf:resource"/></xsl:attribute></xsl:if>
							<xsl:apply-templates select="elmo:queryForm"/>
						</production>
					</xsl:when>
					<!-- Scene -->
					<xsl:when test="rdf:type/@rdf:resource='http://bp4mc2.org/elmo/def#Scene'">
						<xsl:if test="exists(elmo:query[.!=''])">
							<xsl:variable name="uri" select="@rdf:about"/>
							<xsl:variable name="queryForm">
								<xsl:apply-templates select="../rdf:Description[elmo:contains/@rdf:resource=$uri]/elmo:queryForm"/>
							</xsl:variable>
							<!-- Don't include the scene if the queryForm is not satisfied -->
							<xsl:if test="not($queryForm/queryForm/@satisfied!='')">
								<scene uri="{@rdf:about}" index="{position()}">
									<xsl:if test="exists(elmo:endpoint[1])"><xsl:attribute name="endpoint"><xsl:value-of select="elmo:endpoint[1]/@rdf:resource"/></xsl:attribute></xsl:if>
									<xsl:if test="exists(rdfs:label)"><xsl:attribute name="label"><xsl:apply-templates select="." mode="label"/></xsl:attribute></xsl:if>
									<query><xsl:value-of select="elmo:query[.!=''][1]"/></query>
								</scene>
							</xsl:if>
						</xsl:if>
					</xsl:when>
					<!-- Special: data is available in a file (used only for ELMO-LDT related content -->
					<xsl:when test="exists(elmo:file[1])">
						<representation uri="{@rdf:about}" index="{position()}">
							<xsl:if test="exists(elmo:appearance[1])"><xsl:attribute name="appearance"><xsl:value-of select="elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
							<xsl:if test="exists(elmo:name[1])"><xsl:attribute name="name"><xsl:value-of select="elmo:name[1]"/></xsl:attribute></xsl:if>
							<xsl:if test="exists(rdfs:label)"><xsl:attribute name="label"><xsl:apply-templates select="." mode="label"/></xsl:attribute></xsl:if>
							<xsl:apply-templates select="elmo:queryForm"/>
							<xsl:apply-templates select="elmo:fragment"/>
							<file><xsl:value-of select="elmo:file[1]"/></file>
						</representation>
					</xsl:when>
					<xsl:when test="exists(elmo:data[1])">
						<!-- Als er letterlijke data wordt opgevraagd, dan deze straks ophalen via de query -->
						<representation uri="{@rdf:about}" index="{position()}" endpoint="{/root/context/configuration-endpoint}">
							<xsl:if test="exists(elmo:appearance[1])"><xsl:attribute name="appearance"><xsl:value-of select="elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
							<xsl:if test="exists(elmo:name[1])"><xsl:attribute name="name"><xsl:value-of select="elmo:name[1]"/></xsl:attribute></xsl:if>
							<xsl:if test="exists(rdfs:label)"><xsl:attribute name="label"><xsl:apply-templates select="." mode="label"/></xsl:attribute></xsl:if>
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
					<xsl:when test="exists(elmo:query[.!=''])">
						<representation uri="{@rdf:about}" index="{position()}">
							<xsl:if test="exists(elmo:endpoint[1])"><xsl:attribute name="endpoint"><xsl:value-of select="elmo:endpoint[1]/@rdf:resource"/></xsl:attribute></xsl:if>
							<xsl:if test="exists(elmo:appearance[1])"><xsl:attribute name="appearance"><xsl:value-of select="elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
							<xsl:if test="exists(elmo:container[1])"><xsl:attribute name="container"><xsl:value-of select="elmo:container[1]/@rdf:resource"/></xsl:attribute></xsl:if>
							<xsl:if test="exists(elmo:name[1])"><xsl:attribute name="name"><xsl:value-of select="elmo:name[1]"/></xsl:attribute></xsl:if>
							<xsl:if test="exists(rdfs:label)"><xsl:attribute name="label"><xsl:apply-templates select="." mode="label"/></xsl:attribute></xsl:if>
							<xsl:apply-templates select="elmo:queryForm"/>
							<xsl:apply-templates select="elmo:fragment"/>
							<query><xsl:value-of select="elmo:query[.!=''][1]"/></query>
							<xsl:apply-templates select="elmo:link"/>
							<!-- Een service kan vooraf gaan aan een query, dus die hier ook meenemen -->
							<xsl:if test="exists(elmo:service[1])">
								<service>
									<url><xsl:value-of select="elmo:service[1]"/></url>
									<output>json</output>
									<xsl:if test="elmo:post[1]!=''"><body><xsl:value-of select="elmo:post[1]"/></body></xsl:if>
								</service>
							</xsl:if>
						</representation>
					</xsl:when>
					<xsl:when test="exists(elmo:service[1])">
						<representation uri="{@rdf:about}" index="{position()}">
							<xsl:if test="exists(elmo:appearance[1])"><xsl:attribute name="appearance"><xsl:value-of select="elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
							<xsl:if test="exists(elmo:name[1])"><xsl:attribute name="name"><xsl:value-of select="elmo:name[1]"/></xsl:attribute></xsl:if>
							<xsl:apply-templates select="elmo:queryForm"/>
							<xsl:apply-templates select="elmo:fragment"/>
							<service>
								<url><xsl:value-of select="elmo:service[1]"/></url>
								<output>
									<xsl:choose>
										<xsl:when test="elmo:accept[1]='text/plain'">txt</xsl:when>
										<xsl:when test="elmo:accept[1]='application/xml'">xml</xsl:when>
										<xsl:when test="elmo:accept[1]='application/json'">json</xsl:when>
										<xsl:otherwise>jsonld</xsl:otherwise>
									</xsl:choose>
								</output>
								<xsl:if test="elmo:post[1]!=''"><body><xsl:value-of select="elmo:post[1]"/></body></xsl:if>
								<xsl:if test="elmo:translator[1]/@rdf:resource!=''"><translator><xsl:value-of select="substring-after(elmo:translator[1]/@rdf:resource,'#')"/></translator></xsl:if>
							</service>
						</representation>
					</xsl:when>
					<xsl:when test="exists(elmo:webpage[1])">
						<representation uri="{@rdf:about}" index="{position()}">
							<xsl:if test="exists(elmo:appearance[1])"><xsl:attribute name="appearance"><xsl:value-of select="elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
							<xsl:if test="exists(elmo:name[1])"><xsl:attribute name="name"><xsl:value-of select="elmo:name[1]"/></xsl:attribute></xsl:if>
							<xsl:apply-templates select="elmo:queryForm"/>
							<xsl:apply-templates select="elmo:fragment"/>
							<service>
								<url><xsl:value-of select="elmo:webpage[1]"/></url>
								<output>rdf</output>
								<accept>application/rdf+xml, text/rdf+n3, text/rdf+ttl, text/rdf+turtle, text/turtle, application/turtle, application/x-turtle, application/xml, */*</accept>
							</service>
						</representation>
					</xsl:when>
					<!-- No data, no query -->
					<xsl:otherwise/>
				</xsl:choose>
			</xsl:if>
		</xsl:for-each-group>
	</view>
</xsl:template>

</xsl:stylesheet>
