<!--

    NAME     TreeAppearance.xsl
    VERSION  1.9.1-SNAPSHOT
    DATE     2016-07-26

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
	TreeAppearance, add-on of rdf2html.xsl
	
	A TreeAppearance shows triples as a hierarchical tree, at the left side of the screen.
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
>

<xsl:output method="xml" indent="yes"/>

<xsl:template match="rdf:Description" mode="makeTree">
	<!-- To avoid cycles, a resource can be present only ones -->
	<xsl:param name="done"/>
	<xsl:variable name="uri" select="@rdf:about"/>
	<xsl:variable name="resource-uri">
		<xsl:call-template name="resource-uri">
			<xsl:with-param name="uri" select="$uri"/>
			<xsl:with-param name="var" select=".."/> <!-- Was rdf:Description, maar dit lijkt beter -->
		</xsl:call-template>
	</xsl:variable>
	<li>
		<a href="{$resource-uri}">
			<xsl:choose>
				<xsl:when test="rdfs:label!=''"><xsl:value-of select="rdfs:label"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="@rdf:about"/></xsl:otherwise>
			</xsl:choose>
			<xsl:call-template name="cross-site-marker">
				<xsl:with-param name="url" select="$resource-uri"/>
			</xsl:call-template>
		</a>
		<xsl:variable name="new">
			<xsl:for-each select="../rdf:Description[*/@rdf:resource=$uri]">
				<xsl:variable name="about" select="@rdf:about"/>
				<xsl:if test="not(exists($done[uri=$about]))">
					<uri><xsl:value-of select="."/></uri>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="exists($new/uri)">
			<ul style="display: none"> <!-- Default: collapsed tree -->
				<xsl:for-each select="../rdf:Description[*/@rdf:resource=$uri]">
					<xsl:variable name="about" select="@rdf:about"/>
					<xsl:if test="not(exists($done[uri=$about]))">
						<xsl:apply-templates select="." mode="makeTree">
							<xsl:with-param name="done">
								<xsl:copy-of select="$done"/>
								<xsl:copy-of select="$new"/>
							</xsl:with-param>
						</xsl:apply-templates>
					</xsl:if>
				</xsl:for-each>
			</ul>
		</xsl:if>
	</li>
</xsl:template>

<xsl:template match="rdf:RDF" mode="TreeAppearance">
	<div class="tree">
		<ul>
			<xsl:variable name="done">
				<xsl:for-each select="rdf:Description[not(exists(*/@rdf:resource))]/@rdf:about">
					<uri><xsl:value-of select="."/></uri>
				</xsl:for-each>
			</xsl:variable>
			<xsl:apply-templates select="rdf:Description[not(exists(*/@rdf:resource))]" mode="makeTree"><xsl:with-param name="done" select="$done"/></xsl:apply-templates>
		</ul>
	</div>
	<link rel="stylesheet" href="{$staticroot}/css/treestyle.min.css"/>
	<script src="{$staticroot}/js/MultiNestedList.min.js"></script>
</xsl:template>

</xsl:stylesheet>