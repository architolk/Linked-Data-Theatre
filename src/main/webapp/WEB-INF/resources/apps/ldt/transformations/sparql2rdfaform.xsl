<!--

    NAME     sparql2rdfaform.xsl
    VERSION  1.5.2-SNAPSHOT
    DATE     2016-03-06

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

<xsl:template match="/">
	<results>
		<context>
			<language>nl</language>
		</context>
		<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#FormAppearance">
			<rdf:Description rdf:nodeID="form">
				<rdfs:label>Query</rdfs:label>
			</rdf:Description>
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
		<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#TableAppearance">
			<xsl:copy-of select="root/rdf:RDF/*"/>
		</rdf:RDF>
	</results>
</xsl:template>

</xsl:stylesheet>