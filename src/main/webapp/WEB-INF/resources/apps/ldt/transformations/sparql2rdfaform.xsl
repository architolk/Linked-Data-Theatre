<!--

    NAME     sparql2rdfaform.xsl
    VERSION  1.6.0
    DATE     2016-03-13

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

<xsl:template match="rdf:RDF">
	<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#ContentAppearance">
		<xsl:copy-of select="*"/>
	</rdf:RDF>
</xsl:template>

<xsl:template match="res:sparql">
	<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#TableAppearance">
		<rdf:Description rdf:nodeID="rset">
			<rdf:type rdf:resource="http://www.w3.org/2005/sparql-results#ResultSet"/>
			<xsl:for-each select="res:head/res:variable">
				<res:resultVariable><xsl:value-of select="@name"/></res:resultVariable>
			</xsl:for-each>
			<xsl:for-each select="res:results/res:result">
				<xsl:variable name="row" select="position()-1"/>
				<res:solution rdf:nodeID="r{$row}">
					<xsl:for-each select="res:binding">
						<xsl:variable name="column" select="position()-1"/>
						<res:binding rdf:nodeID="r{$row}c{$column}">
							<res:variable><xsl:value-of select="@name"/></res:variable>
							<res:value>
								<xsl:if test="exists(res:uri)"><xsl:attribute name="rdf:resource"><xsl:value-of select="res:uri"/></xsl:attribute></xsl:if>
								<xsl:if test="exists(res:literal)"><xsl:attribute name="datatype"><xsl:value-of select="res:literal/@datatype"/></xsl:attribute><xsl:value-of select="res:literal"/></xsl:if>
							</res:value>
						</res:binding>
					</xsl:for-each>
				</res:solution>
			</xsl:for-each>
		</rdf:Description>
	</rdf:RDF>
</xsl:template>

<xsl:template match="/">
	<results>
		<xsl:copy-of select="root/context"/>
		<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#FormAppearance">
			<rdf:Description rdf:nodeID="form">
				<rdfs:label>Query</rdfs:label>
			</rdf:Description>
			<xsl:if test="exists(root/parameters/error)">
				<rdf:Description rdf:nodeID="f2">
					<rdfs:label>Error</rdfs:label>
					<elmo:applies-to>error</elmo:applies-to>
					<elmo:valueDatatype rdf:resource="http://www.w3.org/2001/XMLSchema#String"/>
					<rdf:value><xsl:value-of select="root/parameters/error"/></rdf:value>
					<html:stylesheet>height:40px; background:red; color:white;</html:stylesheet>
				</rdf:Description>
			</xsl:if>
			<rdf:Description rdf:nodeID="f3">
				<rdfs:label>Query</rdfs:label>
				<elmo:applies-to>query</elmo:applies-to>
				<elmo:valueDatatype rdf:resource="http://www.w3.org/2001/XMLSchema#String"/>
				<elmo:appearance rdf:resource="http://bp4mc2.org/elmo/def#SparqlEditor"/>
				<rdf:value><xsl:value-of select="root/context/parameters/parameter[name='query']/value"/></rdf:value>
			</rdf:Description>
			<rdf:Description rdf:nodeID="f4">
				<rdfs:label>Go!</rdfs:label>
				<elmo:appearance rdf:resource="http://bp4mc2.org/elmo/def#SubmitAppearance"/>
			</rdf:Description>
		</rdf:RDF>
		<xsl:apply-templates select="root/rdf:RDF|root/res:sparql"/>
	</results>
</xsl:template>

</xsl:stylesheet>