<!--

    NAME     XPLTranslator.xsl
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
	Translates XPL to corresponding linked data
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xmi="http://schema.omg.org/spec/XMI/2.1"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:p="http://www.orbeon.com/oxf/pipeline"
	xmlns:pp="http://www.orbeon.com/oxf/pipeline#"
>

<xsl:variable name="prefix">http://elmo.localhost/ldt/id/</xsl:variable>

<xsl:template match="p:processor">
	<xsl:param name="context"/>
	<xsl:variable name="lcontext"><xsl:value-of select="$context"/><xsl:value-of select="position()"/></xsl:variable>
	<pp:Processor rdf:about="{$prefix}{$lcontext}">
		<rdfs:label><xsl:value-of select="$lcontext"/>. <xsl:value-of select="@name"/></rdfs:label>
	</pp:Processor>
</xsl:template>

<xsl:template match="p:choose">
	<xsl:param name="context"/>
	<xsl:variable name="lcontext"><xsl:value-of select="$context"/><xsl:value-of select="position()"/></xsl:variable>
	<pp:Choose rdf:about="{$prefix}{$lcontext}">
		<rdfs:label><xsl:value-of select="$lcontext"/>. choose</rdfs:label>
		<xsl:for-each select="p:when|p:otherwise"><pp:branche rdf:resource="{$prefix}{$lcontext}.{position()}"/></xsl:for-each>
	</pp:Choose>
	<xsl:apply-templates select="p:when|p:otherwise">
		<xsl:with-param name="context"><xsl:value-of select="$lcontext"/>.</xsl:with-param>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="p:when|p:otherwise">
	<xsl:param name="context"/>
	<xsl:variable name="lcontext"><xsl:value-of select="$context"/><xsl:value-of select="position()"/></xsl:variable>
	<pp:Branche rdf:about="{$prefix}{$lcontext}">
		<rdfs:label><xsl:value-of select="$lcontext"/>. branche</rdfs:label>
		<xsl:for-each select="p:processor|p:choose"><pp:filter rdf:resource="{$prefix}{$lcontext}.{position()}"/></xsl:for-each>
	</pp:Branche>
	<xsl:apply-templates select="p:processor|p:choose">
		<xsl:with-param name="context"><xsl:value-of select="$lcontext"/>.</xsl:with-param>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="p:config">
	<pp:Config rdf:about="{$prefix}config">
		<rdfs:label>Config</rdfs:label>
		<xsl:for-each select="p:processor|p:choose"><pp:filter rdf:resource="{$prefix}{position()}"/></xsl:for-each>
	</pp:Config>
	<xsl:apply-templates select="p:processor|p:choose"/>
</xsl:template>

<xsl:template match="/">
	<rdf:RDF>
		<xsl:apply-templates select="p:config"/>
	</rdf:RDF>
</xsl:template>

</xsl:stylesheet>