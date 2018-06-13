<!--

    NAME     rdf2jsonld.xsl
    VERSION  1.22.0
    DATE     2018-06-13

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
    Transformation of RDF document to json-ld format
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"

	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="fn"
	exclude-result-prefixes="xs fn"
>

<xsl:variable name="dblquote">"</xsl:variable>
<xsl:variable name="dblquote-escaped">\\"</xsl:variable>

<xsl:variable name="spaces">. .</xsl:variable>

<xsl:function name="fn:spaces" as="xs:string">
	<xsl:param name="tab" as="xs:integer"/>
	<xsl:variable name="result">
		<xsl:for-each select="2 to $tab"><xsl:value-of select="substring($spaces,2,1)"/></xsl:for-each>
	</xsl:variable>
	<xsl:value-of select="$result"/>
</xsl:function>

<xsl:key name="bnodes" match="/results/rdf:RDF[1]/rdf:Description" use="@rdf:nodeID"/>

<xsl:variable name="prefix">
	<!-- Prefixes used in properties -->
	<xsl:for-each-group select="results/rdf:RDF[1]/rdf:Description/*" group-by="substring-before(name(),':')">
		<xsl:variable name="prefix" select="substring-before(name(),':')"/>
		<xsl:if test="$prefix!=''">
			<prefix name="{$prefix}"><xsl:value-of select="namespace-uri()"/></prefix>
		</xsl:if>
	</xsl:for-each-group>
	<!-- Prefixes used in local xlmns properties -->
	<xsl:for-each-group select="results/rdf:RDF[1]/rdf:Description/*[substring-before(name(),':')='']" group-by="namespace-uri()">
		<xsl:variable name="prefix" select="replace(namespace-uri(),'.*/([^/]*)(#|/)','$1')"/>
		<xsl:choose>
			<xsl:when test="$prefix!=''"><prefix name="{$prefix}"><xsl:value-of select="namespace-uri()"/></prefix></xsl:when>
			<xsl:otherwise><prefix name="n{position()}"><xsl:value-of select="namespace-uri()"/></prefix></xsl:otherwise>
		</xsl:choose>
	</xsl:for-each-group>
</xsl:variable>

<xsl:template match="*" mode="literalvalue">
	<xsl:value-of select="replace(replace(replace(.,'\\','\\\\'),$dblquote,$dblquote-escaped),'[&#13;&#10;|&#13;|&#10;|&#10;&#13;]','\\n')"/>
</xsl:template>

<xsl:template match="*" mode="constructliteral">
	<xsl:choose>
		<xsl:when test="exists(@rdf:resource)">"<xsl:value-of select="@rdf:resource"/>"</xsl:when>
		<xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#integer'"><xsl:value-of select="."/></xsl:when>
		<xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#decimal'"><xsl:value-of select="."/></xsl:when>
		<xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#boolean'"><xsl:value-of select="."/></xsl:when>
		<xsl:otherwise>"<xsl:apply-templates select="." mode="literalvalue"/>"</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="selectliteral">
	<xsl:choose>
		<xsl:when test="exists(res:uri)">"<xsl:value-of select="res:uri"/>"</xsl:when>
		<xsl:when test="res:literal/@datatype='http://www.w3.org/2001/XMLSchema#integer'"><xsl:value-of select="."/></xsl:when>
		<xsl:when test="res:literal/@datatype='http://www.w3.org/2001/XMLSchema#decimal'"><xsl:value-of select="."/></xsl:when>
		<xsl:when test="res:literal/@datatype='http://www.w3.org/2001/XMLSchema#boolean'"><xsl:value-of select="."/></xsl:when>
		<xsl:otherwise>"<xsl:apply-templates select="res:literal" mode="literalvalue"/>"</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Select -->
<xsl:template match="res:sparql">{"@context":
	{"graph":"@graph"<xsl:for-each-group select="res:results/res:result/res:binding" group-by="@name">
	,"<xsl:value-of select="@name"/>":{"@id":"urn:<xsl:value-of select="@name"/>"<xsl:if test="exists(res:uri)">,"@type":"@id"</xsl:if>}</xsl:for-each-group>
	}
,"graph":
[<xsl:for-each select="res:results/res:result"><xsl:if test="position()!=1">,</xsl:if>
	{<xsl:for-each select="res:binding"><xsl:if test="position()!=1">
	,</xsl:if>"<xsl:value-of select="@name"/>": <xsl:apply-templates select="." mode="selectliteral"/></xsl:for-each>
	}</xsl:for-each>
]
}
</xsl:template>

<xsl:template match="*" mode="property">
	<xsl:choose>
		<xsl:when test="matches(name(),':')"><xsl:value-of select="name()"/></xsl:when>
		<xsl:otherwise>
			<xsl:variable name="namespace" select="namespace-uri()"/>
			<xsl:variable name="aprefix" select="$prefix/prefix[.=$namespace]"/>
			<xsl:if test="count($aprefix)=1"><xsl:value-of select="$aprefix/@name"/>:</xsl:if>
			<xsl:value-of select="name()"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Construct -->
<xsl:template match="*" mode="triple"><xsl:param name="tab"/><xsl:param name="cnt" select="1"/>
	<xsl:choose><xsl:when test="position()=1"><xsl:text>"</xsl:text><xsl:apply-templates select="." mode="property"/>": <xsl:if test="$cnt!=1">[</xsl:if></xsl:when><xsl:otherwise>,</xsl:otherwise></xsl:choose>
	<xsl:apply-templates select="." mode="objectpart"><xsl:with-param name="tab" select="$tab"/></xsl:apply-templates>
	<xsl:if test="$cnt=position() and $cnt!=1">]</xsl:if>
</xsl:template>

<xsl:template match="*" mode="objectpart"><xsl:param name="tab" as="xs:integer"/>
<xsl:choose><xsl:when test="exists(@rdf:nodeID)"><xsl:text>
</xsl:text><xsl:value-of select="fn:spaces($tab)"/>{<xsl:for-each select="key('bnodes',@rdf:nodeID)/*"><xsl:if test="position()!=1"><xsl:text>
</xsl:text><xsl:value-of select="fn:spaces($tab)"/>,</xsl:if><xsl:apply-templates select="." mode="triple"><xsl:with-param name="tab" select="$tab+4"/></xsl:apply-templates></xsl:for-each><xsl:text>
</xsl:text><xsl:value-of select="fn:spaces($tab)"/>}</xsl:when><xsl:otherwise><xsl:apply-templates select="." mode="constructliteral"/></xsl:otherwise></xsl:choose>
</xsl:template>

<xsl:template match="rdf:RDF">{"@context":
	{"id":"@id"
	,"graph":"@graph"<xsl:for-each-group select="$prefix/prefix" group-by="@name"><xsl:if test="count(current-group())=1">
	,"<xsl:value-of select="@name"/>":"<xsl:value-of select="."/>"</xsl:if></xsl:for-each-group>
	<xsl:for-each-group select="rdf:Description/*[exists(@rdf:resource)]" group-by="name()">
	,"<xsl:apply-templates select="." mode="property"/>":{"@type":"@id"}</xsl:for-each-group>
	}
<xsl:choose>
	<xsl:when test="count(rdf:Description/@rdf:about)!=1">,"graph":
[<xsl:for-each-group select="rdf:Description" group-by="@rdf:about"><xsl:if test="position()!=1">,</xsl:if>
    {"id":"<xsl:value-of select="@rdf:about"/>"<xsl:for-each-group select="current-group()/*" group-by="name()">
    ,<xsl:apply-templates select="current-group()" mode="triple"><xsl:with-param name="tab" select="8"/><xsl:with-param name="cnt" select="count(current-group())"/></xsl:apply-templates></xsl:for-each-group>
    }</xsl:for-each-group>
]
}</xsl:when>
	<xsl:otherwise>
		<xsl:for-each-group select="rdf:Description" group-by="@rdf:about">,"@id":"<xsl:value-of select="@rdf:about"/>"<xsl:for-each-group select="current-group()/*" group-by="name()">
,<xsl:apply-templates select="current-group()" mode="triple"><xsl:with-param name="tab" select="4"/><xsl:with-param name="cnt" select="count(current-group())"/></xsl:apply-templates></xsl:for-each-group>
		</xsl:for-each-group>
}</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:template match="/">
	<xsl:apply-templates select="(results/res:sparql|results/rdf:RDF)[1]"/>
</xsl:template>

</xsl:stylesheet>