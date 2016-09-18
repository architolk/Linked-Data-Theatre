<!--

    NAME     TextAppearance.xsl
    VERSION  1.11.0
    DATE     2016-09-18

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
	TextAppearance, add-on of rdf2html.xsl
	
	A TextAppearance creates a textual representation of an XML document. The TextAppearance only works
	with a specific XML document, and NOT a Linked Data dataset.
	
	TODO: TextAppearance is a depricated appearance, only available because of the previous LDT version. It should be deleted or updated.
	TODO: Including a <style> element within a <div> is not compliant to html5: this has to change
	
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

<!-- Fragment afhandeling -->
<xsl:template match="*[@class='container']">
	<xsl:param name="notitle"/>
	<xsl:if test="exists(*[@class='title']) and not($notitle)"><p class="title"><xsl:value-of select="*[@class='title']"/></p></xsl:if>
	<xsl:choose>
		<xsl:when test="exists(*[@class='marker'])">
			<li>
				<span class="marker"><xsl:value-of select="*[@class='marker']"/></span>
				<xsl:apply-templates select="*[@class='container' or @class='block']"/>
			</li>
		</xsl:when>
		<xsl:when test="exists(*[@class='container']/*[@class='marker'])">
			<ul class="fragment">
				<xsl:apply-templates select="*[@class='container' or @class='block']"/>
			</ul>
		</xsl:when>
		<!-- Hier mist nog een stuk voor de afhandeling van het tonen van tabellen. Dit staat wel in het verouderde stuk: nog overnemen dus! -->
		<xsl:otherwise>
			<xsl:apply-templates select="*[@class='container' or @class='block']"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*[@class='block']">
	<xsl:value-of select="text()"/>
	<xsl:apply-templates select="*[exists(@class)]"/><p class="break" />
</xsl:template>

<xsl:template match="*[@class='inline']">
	<xsl:choose>
		<xsl:when test="@ref!=''"><a href="{$docroot}/resource?subject={encode-for-uri(concat('http://wetten.overheid.nl/',@ref))}"><xsl:value-of select="."/></a></xsl:when>
		<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*[@class='annotation']">
	<i><xsl:text>[</xsl:text><xsl:value-of select="."/><xsl:text>]</xsl:text></i>
</xsl:template>

<xsl:template match="rdf:RDF" mode="TextAppearance">
	<style>
p.title {
	font-weight: bold;
}

tr.title {
	font-weight: bold;
}

p.break {
	margin-bottom: 0.5em;
}

ul.fragment {
	list-style-type: none;
}

table.fragment{
	margin-bottom: 10px;
}

table.fragment tr td{
	padding: 3px;
    border:1px solid #d9d9d9;
}
.marker {
	display:-moz-inline-block; display:-moz-inline-box; display:inline-block; 
	font-weight: bold;
	left: -40px;
	width: 40px;
	margin-right: -40px;
	position: relative;
}
	</style>
	<div class="panel panel-primary">
		<div id="graphtitle" class="panel-heading"><xsl:value-of select="xmldocs/xmldoc/document/*[1]/*[@class='title']"/></div>
		<div id="graph" class="panel-body">
			<xsl:for-each select="xmldocs/xmldoc/document">
				<xsl:choose>
					<xsl:when test="exists(*[@class='container']/*[@class='marker'])">
						<ul class="fragment">
							<xsl:apply-templates select="*[@class='container' or @class='block']"/>
						</ul>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="*[@class='container' or @class='block']">
							<xsl:with-param name="notitle">notitle</xsl:with-param>
						</xsl:apply-templates>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>