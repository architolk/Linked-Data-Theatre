<!--

    NAME     MarkdownAppearance.xsl
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
	MarkdownAppearance, add-on of rdf2html.xsl
	
	A Markdown appearance assumes that the linked data contains literals as Markdown. It will present the Markdown within these literals.
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>

<xsl:output method="xml" indent="yes"/>

<xsl:template match="rdf:RDF" mode="MarkdownAppearance">
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title">
				<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description/rdfs:label"/></xsl:call-template></xsl:variable>
				<xsl:value-of select="$label"/>
			</h3>
		</div>
		<div class="panel-body htmlapp">
			<!-- HTML as part of a construct query -->
			<xsl:if test="exists(rdf:Description/elmo:md)">
				<xsl:variable name="markdown" as="xs:string"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description/elmo:md"/></xsl:call-template></xsl:variable>
				<xsl:variable name="html">&lt;div&gt;<xsl:value-of select="md2html:process($markdown)" xmlns:md2html="com.github.rjeschke.txtmark.Processor"/>&lt;/div&gt;</xsl:variable>
				<xsl:copy-of select="saxon:parse($html)" xmlns:saxon="http://saxon.sf.net/"/>
			</xsl:if>
			<!-- HTML as part of a select query -->
			<xsl:if test="rdf:Description/res:resultVariable='md'">
				<xsl:variable name="html">
					<xsl:text>&lt;div></xsl:text>
					<xsl:for-each select="rdf:Description/res:solution/res:binding[res:variable='md']/res:value">
						<xsl:variable name="markdown" as="xs:string" select="."/>
						<xsl:value-of select="md2html:process($markdown)" xmlns:md2html="com.github.rjeschke.txtmark.Processor"/>
					</xsl:for-each>
					<xsl:text>&lt;/div></xsl:text>
				</xsl:variable>
				<xsl:copy-of select="saxon:parse($html)" xmlns:saxon="http://saxon.sf.net/"/>
			</xsl:if>
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>