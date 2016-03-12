<!--

    NAME     rdf2jsonld.xsl
    VERSION  1.5.2-SNAPSHOT
    DATE     2016-03-09

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
    Transformation of RDF document to json-ld format
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
>

<xsl:variable name="dblquote"><xsl:text>"&#10;&#13;</xsl:text></xsl:variable>
<xsl:variable name="quote">'  </xsl:variable>

<xsl:key name="bnodes" match="/results/rdf:RDF[1]/rdf:Description" use="@rdf:nodeID"/>

<!-- Select -->
<xsl:template match="res:sparql">
{"@context":
	{"graph":"@graph"<xsl:for-each-group select="res:results/res:result/res:binding[exists(res:uri)]" group-by="@name">
	,"<xsl:value-of select="@name"/>":{"@type":"@id"}</xsl:for-each-group>
	}
,"graph":
[<xsl:for-each select="res:results/res:result"><xsl:if test="position()!=1">,</xsl:if>
	{<xsl:for-each select="res:binding"><xsl:if test="position()!=1">
	,</xsl:if>"<xsl:value-of select="@name"/>": "<xsl:value-of select="translate(res:literal,$dblquote,$quote)"/><xsl:value-of select="res:uri"/>"</xsl:for-each>
	}</xsl:for-each>
]
}
</xsl:template>

<!-- Construct -->
<xsl:template match="rdf:RDF">
{"@context":
	{"id":"@id"
	,"graph":"@graph"<xsl:for-each-group select="rdf:Description/*" group-by="substring-before(name(),':')">
	,"<xsl:value-of select="substring-before(name(),':')"/>":"<xsl:value-of select="namespace-uri()"/>"</xsl:for-each-group>
	<xsl:for-each-group select="rdf:Description/*[exists(@rdf:resource)]" group-by="name()">
	,"<xsl:value-of select="name()"/>":{"@type":"@id"}</xsl:for-each-group>
	}
<xsl:choose>
	<xsl:when test="count(rdf:Description/@rdf:about)!=1">,"graph":
[<xsl:for-each-group select="rdf:Description" group-by="@rdf:about"><xsl:if test="position()!=1">,</xsl:if>
	{"id":"<xsl:value-of select="@rdf:about"/>"<xsl:for-each select="current-group()/*">
	,"<xsl:value-of select="name()"/>": <xsl:choose><xsl:when test="exists(@rdf:nodeID)">
		{<xsl:for-each select="key('bnodes',@rdf:nodeID)/*"><xsl:if test="position()!=1">
		,</xsl:if>"<xsl:value-of select="name()"/>": "<xsl:value-of select="."/>"</xsl:for-each>
		}</xsl:when><xsl:otherwise>"<xsl:value-of select="translate(.,$dblquote,$quote)"/><xsl:value-of select="@rdf:resource"/>"</xsl:otherwise></xsl:choose></xsl:for-each>
	}</xsl:for-each-group>
]
}</xsl:when>
	<xsl:otherwise>
		<xsl:for-each-group select="rdf:Description" group-by="@rdf:about">,"@id":"<xsl:value-of select="@rdf:about"/>"<xsl:for-each select="current-group()/*">
,"<xsl:value-of select="name()"/>": <xsl:choose><xsl:when test="exists(@rdf:nodeID)">
	{<xsl:for-each select="key('bnodes',@rdf:nodeID)/*"><xsl:if test="position()!=1">
	,</xsl:if>"<xsl:value-of select="name()"/>": "<xsl:value-of select="."/>"</xsl:for-each>
	}</xsl:when><xsl:otherwise>"<xsl:value-of select="translate(.,$dblquote,$quote)"/><xsl:value-of select="@rdf:resource"/>"</xsl:otherwise></xsl:choose></xsl:for-each>
		</xsl:for-each-group>
}</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:template match="/">
	<xsl:apply-templates select="(results/res:sparql|results/rdf:RDF)[1]"/>
</xsl:template>

</xsl:stylesheet>