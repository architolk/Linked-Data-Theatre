<!--

    NAME     rdf2plainjson.xsl
    VERSION  1.21.0
    DATE     2018-03-19

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
	Transformation of RDF document to json format for form processing
	
-->
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
>

<xsl:output method="text" encoding="utf-8" indent="yes" />

<xsl:variable name="dblquote"><xsl:text>"&#10;&#13;</xsl:text></xsl:variable>
<xsl:variable name="quote">'  </xsl:variable>

<xsl:template match="/root">
	<xsl:for-each select="results">
		<xsl:text>[</xsl:text>
		<xsl:for-each select="rdf:RDF[1]/rdf:Description"><xsl:sort select="rdfs:label[1]"/>
			<xsl:if test="position()!=1">,</xsl:if>
			<xsl:text>{"value":"</xsl:text><xsl:value-of select="@rdf:about"/>
			<xsl:text>","text":"</xsl:text><xsl:value-of select="translate(rdfs:label[1],$dblquote,$quote)"/>
			<xsl:text>"}</xsl:text>
		</xsl:for-each>
		<xsl:text>]</xsl:text>
	</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
