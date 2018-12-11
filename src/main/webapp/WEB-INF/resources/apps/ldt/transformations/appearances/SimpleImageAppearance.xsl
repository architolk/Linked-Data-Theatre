<!--

    NAME     SimpleImageAppearance.xsl
    VERSION  1.23.1-SNAPSHOT
    DATE     2018-12-11

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
	HtmlAppearance, add-on of rdf2html.xsl

	A Html appearance assumes that the linked data contains literals as html. It will present the html within these literals.

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

<xsl:template match="rdf:RDF" mode="theimage">
	<xsl:for-each select="*/html:img[1]">
		<img src="{.}" usemap="#imgmap"/>
	</xsl:for-each>
	<map name="imgmap">
		<xsl:for-each select="*[exists(html:link)]">
			<xsl:variable name="subject" select="@rdf:about"/>
			<xsl:variable name="left" select="html:left"/>
			<xsl:variable name="top" select="html:top"/>
			<xsl:variable name="width" select="html:width"/>
			<xsl:variable name="height" select="html:height"/>
			<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdfs:label"/></xsl:call-template></xsl:variable>
				<area shape="rect" coords="{$left},{$top},{$left+$width},{$top+$height}" href="{html:link}?subject={encode-for-uri($subject)}" alt="{$label}"/>
		</xsl:for-each>
	</map>
</xsl:template>

<xsl:template match="rdf:RDF" mode="SimpleImageAppearance">
	<xsl:choose>
		<xsl:when test="exists(rdf:Description[exists(html:img)][1]/rdfs:label)">
			<div class="panel panel-primary">
				<div class="panel-heading">
					<h3 class="panel-title">
						<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description[exists(html:img)][1]/rdfs:label"/></xsl:call-template></xsl:variable>
						<xsl:value-of select="$label"/>
					</h3>
				</div>
				<div class="panel-body">
					<xsl:apply-templates select="." mode="theimage"/>
				</div>
			</div>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="." mode="theimage"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
