<!--

    NAME     rdf2doc.xsl
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
	Transformation of RDF to Word docx (uses the WordSerializer)
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
>

<xsl:template match="/">
	<xsl:choose>
		<xsl:when test="exists(results/rdf:RDF[1]/rdf:Description/@rdf:about)">
			<xsl:apply-templates select="results/rdf:RDF[1]" mode="construct"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="results/rdf:RDF[1]" mode="select"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Select query -->
<xsl:template match="rdf:RDF" mode="select">
	<xsl:for-each select="rdf:Description[1]">
		<doc>
			<p>SELECT query - not supported yet</p>
		</doc>
	</xsl:for-each>
</xsl:template>

<xsl:template match="rdf:RDF" mode="construct">
	<!-- Make the XML word file -->
	<doc>
		<xsl:for-each-group select="rdf:Description" group-by="@rdf:about">
			<xsl:variable name="maxroot" select="replace(@rdf:about,'(/|#|\\)[0-9A-Za-z-._~()@]*$','$1')"/>
			<xsl:variable name="term" select="substring-after(@rdf:about,$maxroot)"/>
			<p>Begrip: <b id="{$term}"><xsl:value-of select="rdfs:label"/></b></p>
			<xsl:for-each select="*[local-name()!='label']">
				<p><xsl:value-of select="."/></p>
			</xsl:for-each>
			<p>Verwijst naar: <a href="{$term}">zichzelf</a>, duh!</p>
		</xsl:for-each-group>
	</doc>
</xsl:template>

</xsl:stylesheet>