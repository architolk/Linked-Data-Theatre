<!--

    NAME     HtmlAppearance.xsl
    VERSION  1.23.0
    DATE     2018-10-20

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

<xsl:template name="string-replace-all">
	<xsl:param name="text" />
	<xsl:param name="replace" />
	<xsl:param name="by" />
	<xsl:choose>
		<xsl:when test="contains($text, $replace)">
			<xsl:if test="not(contains(substring(substring-after($text, $replace),1,4),'amp;'))">
				<xsl:value-of select="substring-before($text,$replace)" />
				<xsl:value-of select="$by" />
				<xsl:call-template name="string-replace-all">
					<xsl:with-param name="text" select="substring-after($text,$replace)" />
					<xsl:with-param name="replace" select="$replace" />
					<xsl:with-param name="by" select="$by" />
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="contains(substring(substring-after($text, $replace),1,4),'amp;')">
				<xsl:value-of select="substring-before($text,'&amp;amp;')" />
				<xsl:value-of select="$by" />
					<xsl:call-template name="string-replace-all">
						<xsl:with-param name="text" select="substring-after($text,'&amp;amp;')" />
						<xsl:with-param name="replace" select="$replace" />
						<xsl:with-param name="by" select="$by" />
					</xsl:call-template>
			</xsl:if>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$text" />
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="rdf:RDF" mode="PlainHtmlAppearance">
	<!-- HTML as part of a construct query -->
	<xsl:if test="exists(rdf:Description/elmo:html)">
		<xsl:variable name="validHTML">
			<xsl:call-template name="string-replace-all">
		  <xsl:with-param name="text" select="rdf:Description/elmo:html" />
		  <xsl:with-param name="replace" select="'&amp;'" />
		  <xsl:with-param name="by" select="'&amp;amp;'" />
		</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="html">&lt;div>
			<xsl:call-template name="normalize-language">
				<xsl:with-param name="text" select="$validHTML"/>
			</xsl:call-template>&lt;/div>
		</xsl:variable>
		<xsl:copy-of select="saxon:parse($html)/div/*" xmlns:saxon="http://saxon.sf.net/"/>
	</xsl:if>
	<!-- HTML as part of a select query -->
	<xsl:if test="rdf:Description/res:resultVariable='html'">
		<xsl:variable name="html">
			<xsl:text>&lt;div></xsl:text>
			<xsl:for-each select="rdf:Description/res:solution">
				<xsl:value-of select="res:binding[res:variable='html']/res:value"/>
			</xsl:for-each>
			<xsl:text>&lt;/div></xsl:text>
		</xsl:variable>
		<xsl:copy-of select="saxon:parse($html)/div/*" xmlns:saxon="http://saxon.sf.net/"/>
	</xsl:if>
</xsl:template>

<xsl:template match="rdf:RDF" mode="HtmlAppearance">
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title">
				<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description/rdfs:label"/></xsl:call-template></xsl:variable>
				<xsl:value-of select="$label"/>
			</h3>
		</div>
		<div class="panel-body htmlapp">
			<xsl:apply-templates select="." mode="PlainHtmlAppearance"/>
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>
