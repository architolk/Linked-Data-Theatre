<!--

    NAME     rdf2ttl.xsl
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
	Transformation of RDF document to turtle format
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
>

<xsl:key name="bnodes" match="results/rdf:RDF[1]/rdf:Description|xmlresult/rdf:RDF[1]/rdf:Description" use="@rdf:nodeID"/>

<xsl:variable name="spaces">.                                            .</xsl:variable>

<xsl:variable name="prefix">
	<!-- Default prefixes -->
	<xsl:choose>
		<xsl:when test="exists(xmlresult/container/stage)">
			<xsl:for-each select="xmlresult/container/stage">
				<prefix name="stage"><xsl:value-of select="."/>#</prefix>
				<prefix name="elmo">http://bp4mc2.org/elmo/def#</prefix>
			</xsl:for-each>
		</xsl:when>
		<xsl:otherwise>
			<xsl:for-each select="xmlresult/container/url">
				<prefix name="container"><xsl:value-of select="."/>/</prefix>
			</xsl:for-each>
		</xsl:otherwise>
	</xsl:choose>
	<!-- Prefixes used in properties -->
	<xsl:for-each-group select="results/rdf:RDF[1]/rdf:Description/*|xmlresult/rdf:RDF[1]/rdf:Description/*" group-by="substring-before(name(),':')">
		<prefix name="{substring-before(name(),':')}"><xsl:value-of select="namespace-uri()"/></prefix>
	</xsl:for-each-group>
	<!-- Prefixes used in about -->
	<xsl:for-each-group select="results/rdf:RDF[1]/rdf:Description|xmlresult/rdf:RDF[1]/rdf:Description" group-by="replace(@rdf:about,'(/|#|\\)[0-9A-Za-z-._~()@]*$','$1')">
		<xsl:variable name="prefix" select="replace(@rdf:about,'(/|#|\\)[0-9A-Za-z-._~()@]*$','$1')"/>
		<xsl:if test="$prefix!=''">
			<prefix name="n{position()}"><xsl:value-of select="$prefix"/></prefix>
		</xsl:if>
	</xsl:for-each-group>
</xsl:variable>

<xsl:template match="@rdf:about|@rdf:resource" mode="uri">
	<xsl:variable name="fulluri" select="."/>
	<xsl:variable name="uriprefix" select="$prefix/prefix[substring-after($fulluri,.)!=''][1]"/>
	<xsl:choose>
		<xsl:when test="$uriprefix/@name!=''">
			<xsl:value-of select="$uriprefix/@name"/>:<xsl:value-of select="substring-after($fulluri,$uriprefix)"/>
		</xsl:when>
		<xsl:otherwise>&lt;<xsl:value-of select="."/>></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="triple"><xsl:param name="tab"/>
<xsl:value-of select="name()"/><xsl:text> </xsl:text><xsl:choose><xsl:when test="exists(@rdf:resource)"><xsl:apply-templates select="@rdf:resource" mode="uri"/></xsl:when><xsl:when test="exists(@rdf:nodeID)">[
<xsl:for-each select="key('bnodes',@rdf:nodeID)/*"><xsl:if test="position()!=1">;
</xsl:if><xsl:value-of select="substring($spaces,2,$tab)"/><xsl:apply-templates select="." mode="triple"><xsl:with-param name="tab" select="$tab+4"/></xsl:apply-templates></xsl:for-each><xsl:text>
</xsl:text><xsl:value-of select="substring($spaces,2,-4+$tab)"/>]</xsl:when><xsl:when test="contains(.,'&#10;') or contains(.,'&quot;')">'''<xsl:value-of select="."/>'''<xsl:if test="@xml:lang!=''">@<xsl:value-of select="@xml:lang"/></xsl:if></xsl:when><xsl:otherwise>"<xsl:value-of select="."/>"<xsl:if test="@xml:lang!=''">@<xsl:value-of select="@xml:lang"/></xsl:if></xsl:otherwise></xsl:choose>
</xsl:template>

<xsl:template match="rdf:RDF">
<xsl:for-each-group select="$prefix/prefix" group-by=".">@prefix <xsl:value-of select="@name"/>: &lt;<xsl:value-of select="."/>>.
</xsl:for-each-group>
<xsl:for-each-group select="rdf:Description" group-by="@rdf:about">
<xsl:apply-templates select="@rdf:about" mode="uri"/><xsl:for-each select="current-group()/*"><xsl:choose><xsl:when test="position()!=1">;
    </xsl:when><xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise></xsl:choose><xsl:apply-templates select="." mode="triple"><xsl:with-param name="tab">8</xsl:with-param></xsl:apply-templates></xsl:for-each>
.
</xsl:for-each-group>
</xsl:template>

<xsl:template match="/">
	<xsl:apply-templates select="results/rdf:RDF[1]"/>
	<xsl:for-each select="xmlresult">
		<turtle>
			<xsl:apply-templates select="rdf:RDF[1]"/>
		</turtle>
	</xsl:for-each>
</xsl:template>

</xsl:stylesheet>