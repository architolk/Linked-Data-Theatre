<!--

    NAME     result2rdfa.xsl
    VERSION  1.8.0
    DATE     2016-06-15

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
    Transformation of a conversion-result to a RDF document with mark-up annotations
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:dcterms="http://purl.org/dc/terms/"
>

<xsl:template match="/root">
	<results>
		<context docroot="{context/@docroot}">
			<!-- TODO: to much namespaces declarations in resulting XML due to copy-of statement -->
			<xsl:copy-of select="context/*"/>
		</context>
		<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#HtmlAppearance">
			<rdf:Description rdf:nodeID="b1">
				<rdfs:label>Resultaat</rdfs:label>
				<xsl:choose>
					<xsl:when test="exists(response)">
						<elmo:html><xsl:value-of select="response"/></elmo:html>
					</xsl:when>
					<xsl:when test="exists(result/errorMessage)">
						<elmo:html>ERROR: <xsl:value-of select="result/errorMessage"/></elmo:html>
					</xsl:when>
					<xsl:when test="exists(result/startMessage)">
						<elmo:html>Conversie gestart</elmo:html>
					</xsl:when>
					<xsl:otherwise>
						<elmo:html>Something went wrong</elmo:html>
					</xsl:otherwise>
				</xsl:choose>
			</rdf:Description>
		</rdf:RDF>
	</results>
</xsl:template>

</xsl:stylesheet>