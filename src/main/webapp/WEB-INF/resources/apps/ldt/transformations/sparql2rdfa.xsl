<!--

    NAME     sparql2rdfa.xsl
    VERSION  1.19.0
    DATE     2017-10-16

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
    Transformation of a RDF document or SPARQL resultset to a RDF document

	TODO: Transfer functionality from sparql2rdfa
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
>

<xsl:key name="fragment" match="/root/representation/fragment" use="@applies-to"/>

<!-- ************************** -->
<!-- Annotation of RDF document -->
<!-- ************************** -->

<!-- RDF document -->
<xsl:template match="rdf:RDF">
	<!-- Order by identifier -->
	<rdf:RDF>
		<xsl:for-each-group select="rdf:Description" group-by="(@rdf:nodeID|@rdf:about)"><xsl:sort select="(@rdf:nodeID|@rdf:about)"/>
			<rdf:Description>
				<xsl:if test="exists(@rdf:nodeID)"><xsl:attribute name="rdf:nodeID" select="@rdf:nodeID"/></xsl:if>
				<xsl:if test="exists(@rdf:about)"><xsl:attribute name="rdf:about" select="@rdf:about"/></xsl:if>
				<xsl:copy-of select="current-group()/*"/>
			</rdf:Description>
		</xsl:for-each-group>
	</rdf:RDF>
</xsl:template>

<!-- ******************************* -->
<!-- Annotation of sparql result set -->
<!-- ******************************* -->

<!-- Sparql Header variables -->
<xsl:template match="res:variable">
	<res:resultVariable>
		<!-- variable name, no full uri -->
		<xsl:variable name="varname" select="@name"/>
		<xsl:variable name="fragment" select="key('fragment',$varname)"/>
		<!-- If the label of the property exists, include it (priority for a fragment, then the property-label in the query result -->
		<xsl:variable name="plabels">
			<xsl:copy-of select="$fragment/rdfs:label"/>
		</xsl:variable>
		<xsl:variable name="language" select="/root/context/language"/>
		<xsl:variable name="plabel">
			<xsl:choose>
				<xsl:when test="$plabels/rdfs:label[@xml:lang=$language]!=''"><xsl:value-of select="$plabels/rdfs:label[@xml:lang=$language]"/></xsl:when> <!-- First choice: language of browser -->
				<xsl:when test="$plabels/rdfs:label[not(exists(@xml:lang))]!=''"><xsl:value-of select="$plabels/rdfs:label[not(exists(@xml:lang))]"/></xsl:when> <!-- Second choice: no language -->
				<xsl:when test="$plabels/rdfs:label[@xml:lang='nl']!=''"><xsl:value-of select="$plabels/rdfs:label[@xml:lang='nl']"/></xsl:when> <!-- Third choice: dutch -->
				<xsl:when test="$plabels/rdfs:label[@xml:lang='en']!=''"><xsl:value-of select="$plabels/rdfs:label[@xml:lang='en']"/></xsl:when> <!-- Fourth choice: english -->
				<xsl:otherwise><xsl:value-of select="$plabels/rdfs:label[1]"/></xsl:otherwise> <!-- If all fails, the first label -->
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$plabel!=''"><xsl:attribute name="elmo:label"><xsl:value-of select="$plabel"/></xsl:attribute></xsl:if>
		<xsl:if test="$fragment/elmo:appearance[1]/@rdf:resource!=''"><xsl:attribute name="elmo:appearance"><xsl:value-of select="$fragment/elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
		<xsl:if test="$fragment/html:link[1]!=''"><xsl:attribute name="elmo:link"><xsl:value-of select="$fragment/html:link[1]"/></xsl:attribute></xsl:if>
		<xsl:if test="$fragment/elmo:name[1]!=''"><xsl:attribute name="elmo:name"><xsl:value-of select="$fragment/elmo:name[1]"/></xsl:attribute></xsl:if>
		<xsl:if test="$fragment/elmo:index[1]!=''"><xsl:attribute name="elmo:index"><xsl:value-of select="$fragment/elmo:index[1]"/></xsl:attribute></xsl:if>
		<xsl:if test="$fragment/html:glossary[1]/@rdf:resource!=''"><xsl:attribute name="html:glossary"><xsl:value-of select="$fragment/html:glossary[1]/@rdf:resource"/></xsl:attribute></xsl:if>
		<xsl:if test="$fragment/html:stylesheet[1]!=''"><xsl:attribute name="html:stylesheet"><xsl:value-of select="$fragment/html:stylesheet[1]"/></xsl:attribute></xsl:if>
		<xsl:if test="$fragment/elmo:template[1]!=''"><xsl:attribute name="elmo:template"><xsl:value-of select="normalize-space($fragment/elmo:template[1])"/></xsl:attribute></xsl:if>
		<xsl:value-of select="$varname"/>
	</res:resultVariable>
</xsl:template>

<!-- Sparql Results -->
<xsl:template match="res:result">
	<xsl:variable name="row" select="position()-1"/>
	<res:solution rdf:nodeID="r{$row}">
		<xsl:for-each select="res:binding">
			<xsl:variable name="varname" select="@name"/>
			<xsl:variable name="fragment" select="key('fragment',$varname)"/>
			<xsl:variable name="column" select="position()-1"/>
			<!-- Original binding -->
			<res:binding rdf:nodeID="r{$row}c{$column}">
				<res:variable><xsl:value-of select="$varname"/></res:variable>
				<res:value>
					<xsl:if test="exists(res:uri)"><xsl:attribute name="rdf:resource"><xsl:value-of select="res:uri"/></xsl:attribute></xsl:if>
					<xsl:if test="exists(res:literal)"><xsl:attribute name="datatype"><xsl:value-of select="res:literal/@datatype"/></xsl:attribute><xsl:value-of select="res:literal"/></xsl:if>
					<xsl:if test="exists(res:bnode)"><xsl:attribute name="rdf:nodeID"><xsl:value-of select="res:bnode"/></xsl:attribute></xsl:if>
				</res:value>
			</res:binding>
			<!-- Extra binding -->
			<xsl:if test="$fragment/rdf:value!=''">
				<xsl:variable name="language" select="/root/context/language"/>
				<xsl:variable name="rlabel">
					<xsl:choose>
						<xsl:when test="$fragment/rdf:value[@xml:lang=$language]!=''"><xsl:value-of select="$fragment/rdf:value[@xml:lang=$language]"/></xsl:when> <!-- First choice: language of browser -->
						<xsl:when test="$fragment/rdf:value[not(exists(@xml:lang))]!=''"><xsl:value-of select="$fragment/rdf:value[not(exists(@xml:lang))]"/></xsl:when> <!-- Second choice: no language -->
						<xsl:when test="$fragment/rdf:value[@xml:lang='nl']!=''"><xsl:value-of select="$fragment/rdf:value[@xml:lang='nl']"/></xsl:when> <!-- Third choice: dutch -->
						<xsl:when test="$fragment/rdf:value[@xml:lang='en']!=''"><xsl:value-of select="$fragment/rdf:value[@xml:lang='en']"/></xsl:when> <!-- Fourth choice: english -->
						<xsl:otherwise><xsl:value-of select="$fragment/rdf:value[1]"/></xsl:otherwise> <!-- If all fails, the first label -->
					</xsl:choose>
				</xsl:variable>
				<res:binding rdf:nodeID="r{$row}c{$column}l">
					<res:variable><xsl:value-of select="$varname"/>_label</res:variable>
					<res:value><xsl:value-of select="$rlabel"/></res:value>
				</res:binding>
			</xsl:if>
		</xsl:for-each>
	</res:solution>
</xsl:template>

<!-- Sparql -->
<xsl:template match="res:sparql">
	<rdf:RDF>
		<rdf:Description rdf:nodeID="rset">
			<rdf:type rdf:resource="http://www.w3.org/2005/sparql-results#ResultSet"/>
			<xsl:apply-templates select="res:head/res:variable"/>
			<xsl:apply-templates select="res:results/res:result"/>
		</rdf:Description>
	</rdf:RDF>
</xsl:template>

<!-- Drop specific UI appearances -->
<xsl:template match="rdf:RDF|res:sparql" mode="plain">
	<xsl:choose>
		<xsl:when test="/root/representation/@appearance='http://bp4mc2.org/elmo/def#HeaderAppearance'"/>
		<xsl:when test="/root/representation/@appearance='http://bp4mc2.org/elmo/def#NavbarAppearance'"/>
		<xsl:when test="/root/representation/@appearance='http://bp4mc2.org/elmo/def#NavbarSearchAppearance'"/>
		<xsl:when test="/root/representation/@appearance='http://bp4mc2.org/elmo/def#IndexAppearance'"/>
		<xsl:when test="/root/representation/@appearance='http://bp4mc2.org/elmo/def#TreeAppearance'"/>
		<xsl:otherwise><xsl:copy-of select="."/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- **** -->
<!-- ROOT -->
<!-- **** -->

<xsl:template match="/root">
	<xsl:choose>
		<!-- Sparql returned something unusual, maybe error, just return input -->
		<xsl:when test="not(exists(rdf:RDF|res:sparql))"><xsl:copy-of select="*"/></xsl:when>
		<!-- When the requested format is xml or json, don't do any annotations -->
		<xsl:when test="context/format='application/x.elmo.xml'"><xsl:copy-of select="rdf:RDF|res:sparql"/></xsl:when>
		<xsl:when test="context/format='application/xml'"><xsl:apply-templates select="rdf:RDF|res:sparql" mode="plain"/></xsl:when>
		<xsl:when test="context/format='application/rdf+xml'"><xsl:apply-templates select="rdf:RDF|res:sparql" mode="plain"/></xsl:when>
		<xsl:when test="context/format='application/json'"><xsl:apply-templates select="rdf:RDF|res:sparql" mode="plain"/></xsl:when>
		<xsl:when test="context/format='application/ld+json'"><xsl:apply-templates select="rdf:RDF|res:sparql" mode="plain"/></xsl:when>
		<xsl:when test="context/format='text/turtle'"><xsl:apply-templates select="rdf:RDF|res:sparql" mode="plain"/></xsl:when>
		<xsl:when test="context/format='application/sparql-results+xml'"><xsl:apply-templates select="rdf:RDF|res:sparql" mode="plain"/></xsl:when>
		<xsl:otherwise><xsl:apply-templates select="rdf:RDF|res:sparql"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>