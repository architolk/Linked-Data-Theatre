<!--

    NAME     ttl2rdfaform.xsl
    VERSION  1.23.0
    DATE     2018-10-20

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
    Transforms container content (turtle format) to rdfa for presentation in the UI (and further processing by container.xpl pipeline and rdfa2html.xsl)

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:dcterms="http://purl.org/dc/terms/"
>

<xsl:key name="bnode" match="/root/rdf:RDF/*[exists(@rdf:nodeID)]" use="@rdf:nodeID"/>
<xsl:key name="node" match="/root/rdf:RDF/*[exists(@rdf:about)]" use="@rdf:about"/>

<xsl:template match="rdf:Description" mode="data">
	<xsl:copy-of select="."/>
	<xsl:apply-templates select="key('bnode',elmo:data/@rdf:nodeID)" mode="data"/>
	<xsl:apply-templates select="key('node',elmo:data/@rdf:resource)" mode="data"/>
</xsl:template>

<xsl:template match="elmo:data" mode="data">
	<rdf:Description rdf:nodeID="{generate-id()}">
		<xsl:copy-of select="* except elmo:data"/>
		<xsl:for-each select="elmo:data">
			<elmo:data rdf:nodeID="{generate-id()}"/>
		</xsl:for-each>
	</rdf:Description>
	<xsl:apply-templates select="elmo:data[@rdf:parseType='Resource']" mode="data"/>
</xsl:template>

<xsl:template match="/">
	<results>
		<xsl:copy-of select="root/context"/>
		<!--
		<context docroot="{root/context/@docroot}" staticroot="{root/context/@staticroot}">
			<xsl:copy-of select="root/context/*"/>
		</context>
		-->
		<xsl:for-each select="root/rdf:RDF/*[exists(elmo:appearance)]">
			<rdf:RDF elmo:appearance="{elmo:appearance/@rdf:resource}" elmo:query="{@rdf:about}" elmo:index="{position()}">
				<xsl:apply-templates select="key('bnode',elmo:data/@rdf:nodeID)" mode="data"/>
				<xsl:apply-templates select="key('node',elmo:data/@rdf:resource)" mode="data"/>
				<xsl:apply-templates select="elmo:data[@rdf:parseType='Resource']" mode="data"/>
			</rdf:RDF>
		</xsl:for-each>
		<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#FormAppearance" elmo:index="0">
			<rdf:Description rdf:nodeID="form">
				<rdfs:label>
					<xsl:value-of select="root/container/label"/>
					<xsl:if test="root/container/label=''">Container</xsl:if>
				</rdfs:label>
			</rdf:Description>
			<rdf:Description rdf:nodeID="f0">
				<elmo:applies-to>container</elmo:applies-to>
				<elmo:appearance rdf:resource="http://bp4mc2.org/elmo/def#HiddenAppearance"/>
				<rdf:value><xsl:value-of select="root/context/subject"/></rdf:value>
			</rdf:Description>
			<xsl:if test="root/container/response='succes'">
				<rdf:Description rdf:nodeID="f1">
					<rdfs:label>Result</rdfs:label>
					<elmo:applies-to>result</elmo:applies-to>
					<elmo:appearance rdf:resource="http://bp4mc2.org/elmo/def#ReadOnly"/>
					<rdf:value>Upload succesful</rdf:value>
				</rdf:Description>
			</xsl:if>
			<xsl:if test="root/container/representation!='http://bp4mc2.org/elmo/def#DownloadRepresentation'">
				<rdf:Description rdf:nodeID="f2">
					<rdfs:label>Upload</rdfs:label>
					<elmo:applies-to>file</elmo:applies-to>
					<elmo:valueDatatype rdf:resource="http://purl.org/dc/dcmitype/Dataset"/>
				</rdf:Description>
			</xsl:if>
			<xsl:if test="root/container/representation='http://bp4mc2.org/elmo/def#DownloadRepresentation'">
				<rdf:Description rdf:nodeID="f3">
					<rdfs:label>URL</rdfs:label>
					<elmo:applies-to>url</elmo:applies-to>
				</rdf:Description>
			</xsl:if>
			<xsl:if test="exists(root/response/error)">
				<rdf:Description rdf:nodeID="f4">
					<rdfs:label>Error</rdfs:label>
					<elmo:applies-to>error</elmo:applies-to>
					<rdf:value><xsl:value-of select="root/response/error"/></rdf:value>
					<elmo:appearance rdf:resource="http://bp4mc2.org/elmo/def#Message"/>
				</rdf:Description>
			</xsl:if>
			<xsl:for-each select="root/container/fragments/fragment">
				<xsl:variable name="param" select="@id"/>
				<rdf:Description rdf:nodeID="f5-{$param}">
					<elmo:applies-to><xsl:value-of select="$param"/></elmo:applies-to>
					<xsl:copy-of select="*"/>
				</rdf:Description>
			</xsl:for-each>
			<xsl:if test="root/container/representation!='http://bp4mc2.org/elmo/def#UploadRepresentation' and root/container/representation!='http://bp4mc2.org/elmo/def#DownloadRepresentation'">
				<rdf:Description rdf:nodeID="f6">
					<rdfs:label>Content</rdfs:label>
					<elmo:applies-to>content</elmo:applies-to>
					<elmo:valueDatatype rdf:resource="http://www.w3.org/2001/XMLSchema#String"/>
					<elmo:appearance rdf:resource="http://bp4mc2.org/elmo/def#TurtleEditor"/>
					<rdf:value><xsl:value-of select="root/turtle"/></rdf:value>
				</rdf:Description>
			</xsl:if>
			<rdf:Description rdf:nodeID="f7">
				<xsl:choose>
					<xsl:when test="root/container/representation='http://bp4mc2.org/elmo/def#UploadRepresentation'">
						<rdfs:label>Upload</rdfs:label>
					</xsl:when>
					<xsl:otherwise>
						<rdfs:label>Opslaan</rdfs:label>
					</xsl:otherwise>
				</xsl:choose>
				<elmo:appearance rdf:resource="http://bp4mc2.org/elmo/def#SubmitAppearance"/>
			</rdf:Description>
		</rdf:RDF>
		<xsl:if test="root/container/representation='http://bp4mc2.org/elmo/def#UploadRepresentation' and root/container/url!=root/container/version-url">
			<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#TableAppearance">
				<rdf:Description rdf:nodeID="rset">
					<rdf:type rdf:resource="http://www.w3.org/2005/sparql-results#ResultSet"/>
					<res:resultVariable elmo:label="Versie">v</res:resultVariable>
					<xsl:for-each select="root/sparql/rdf:RDF/rdf:Description/dcterms:hasVersion"><xsl:sort select="@rdf:resource"/>
						<res:solution rdf:nodeID="r{position()}">
							<res:binding rdf:nodeID="r{position()}c0">
								<res:variable>v</res:variable>
								<res:value><xsl:value-of select="@rdf:resource"/></res:value>
							</res:binding>
						</res:solution>
					</xsl:for-each>
				</rdf:Description>
			</rdf:RDF>
		</xsl:if>
	</results>
</xsl:template>

</xsl:stylesheet>
