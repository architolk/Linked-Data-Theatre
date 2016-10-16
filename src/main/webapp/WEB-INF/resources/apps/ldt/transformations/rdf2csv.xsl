<!--

    NAME     rdf2csv.xsl
    VERSION  1.12.0
    DATE     2016-10-16

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
	Transformation of RDF document to csv format
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
>

<xsl:variable name="dblquote">"</xsl:variable>
<xsl:variable name="dbldblquote">""</xsl:variable>

<xsl:template match="rdf:RDF" mode="construct">
	<xsl:variable name="columns">
		<xsl:for-each-group select="rdf:Description[exists(@rdf:about)]/*" group-by="local-name()">
			<column name="{local-name()}"/>
		</xsl:for-each-group>
	</xsl:variable>
	<xsl:for-each select="$columns/column">
		<xsl:if test="position()!=1">,</xsl:if>
		<xsl:text>"</xsl:text><xsl:value-of select="@name"/><xsl:text>"</xsl:text>
	</xsl:for-each><xsl:text>
</xsl:text>
	<xsl:for-each-group select="rdf:Description" group-by="@rdf:about">
		<xsl:if test="exists(current-group()/*[name()!='rdfs:label'])">
			<xsl:variable name="group" select="current-group()"/>
			<xsl:for-each select="$columns/column">
				<xsl:if test="position()!=1">,</xsl:if>
				<xsl:variable name="column" select="@name"/>
				<xsl:if test="exists($group/*[local-name()=$column])">
					<xsl:text>"</xsl:text>
					<xsl:value-of select="replace($group/*[local-name()=$column][1],$dblquote,$dbldblquote)"/>
					<xsl:value-of select="$group/*[local-name()=$column][1]/@rdf:resource"/>
					<xsl:text>"</xsl:text>
				</xsl:if>
			</xsl:for-each><xsl:text>
</xsl:text>
		</xsl:if>
	</xsl:for-each-group>
</xsl:template>

<xsl:template match="rdf:RDF" mode="select">
	<xsl:for-each select="rdf:Description[1]">
		<xsl:for-each select="res:resultVariable[substring-after(.,'_')!='label']">
			<xsl:if test="position()!=1">,</xsl:if>
			<xsl:text>"</xsl:text><xsl:value-of select="."/><xsl:text>"</xsl:text>
		</xsl:for-each><xsl:text>
</xsl:text>
		<xsl:for-each select="res:solution">
			<xsl:variable name="binding" select="res:binding"/>
			<xsl:for-each select="../res:resultVariable[substring-after(.,'_')!='label']">
				<xsl:if test="position()!=1">,</xsl:if>
				<xsl:variable name="var" select="."/>
				<xsl:variable name="label"><xsl:value-of select="replace($binding[res:variable=concat($var,'_label')]/res:value,$dblquote,$dbldblquote)"/></xsl:variable>
				<xsl:variable name="value" select="$binding[res:variable=$var]"/>
				<xsl:if test="exists($value/res:value)">
					<xsl:text>"</xsl:text>
					<xsl:choose>
						<xsl:when test="$value/res:value!=''"><xsl:value-of select="replace($value/res:value,$dblquote,$dbldblquote)"/></xsl:when>
						<xsl:when test="$value/res:value/@rdf:resource!=''">
							<xsl:value-of select="$label"/>
							<xsl:if test="$label=''"><xsl:value-of select="$value/res:value/@rdf:resource"/></xsl:if>
						</xsl:when>
						<xsl:otherwise></xsl:otherwise>
					</xsl:choose>
					<xsl:text>"</xsl:text>
				</xsl:if>
			</xsl:for-each><xsl:text>
</xsl:text>
		</xsl:for-each>
	</xsl:for-each>
</xsl:template>

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

</xsl:stylesheet>