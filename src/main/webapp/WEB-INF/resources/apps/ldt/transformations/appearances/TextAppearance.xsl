<!--

    NAME     TextAppearance.xsl
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
	TextAppearance, add-on of rdf2html.xsl
	
	A TextAppearance creates a textual representation of a linked data document
	
	The document may contain:
	- xhtml:section, linked to other sections with xhtml:subsection property
	- rdf:value, containing the actual text, a rdf:list of text elements is also possible, including references to other sections
	- dc:title, containing the title of a xhtml:section
	- geosparql:Feature, containing some features (which will be presented on a map)
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:xhtml="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:geosparql="http://www.opengis.net/ont/geosparql#"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:xlink="http://www.w3.org/1999/xlink"
>

<xsl:output method="xml" indent="yes"/>

<xsl:template match="rdf:Description[exists(xhtml:subsection)]" mode="makedoc">
	<xsl:param name="parent"/>
	
	<xsl:if test="dc:title!='' and not($parent='root' or $parent='li')">
		<p class="title"><xsl:value-of select="dc:title"/></p>
	</xsl:if>
	<xsl:for-each select="xhtml:subsection"><xsl:sort select="@rdf:resource"/>
		<xsl:variable name="fragment" select="@rdf:resource"/>
		<xsl:apply-templates select="../../rdf:Description[@rdf:about=$fragment]" mode="makedoc"/>
	</xsl:for-each>
</xsl:template>

<xsl:template match="rdf:Description[rdf:type/@rdf:resource='http://www.opengis.net/ont/geosparql#Feature']" mode="makedoc">
	<xsl:variable name="mapid">map<xsl:value-of select="generate-id()"/></xsl:variable>
	<div class="map">
		<div class="maptitle"><xsl:value-of select="dc:title"/></div>
		<div class="maplegend">
			<table>
				<xsl:for-each select="geosparql:sfContains">
					<xsl:variable name="location" select="@rdf:resource"/>
					<xsl:for-each select="../../rdf:Description[@rdf:about=$location and exists(xhtml:stylesheet) and exists(dc:title)]">
						<tr>
							<td>
								<svg width="25" height="20">
									<xsl:if test="exists(xhtml:icon)">
										<defs>
											<pattern id="{xhtml:stylesheet}" patternUnits="userSpaceOnUse" width="48" height="48">
												<image xlink:href="/images/patterns/{xhtml:icon}" x="0" y="0" width="48" height="48" />
											</pattern>
										</defs>
									</xsl:if>
									<rect x="2" y="5" width="20" height="15" class="s{xhtml:stylesheet}"/>
								</svg>
							</td>
							<td><xsl:value-of select="dc:title"/></td>
						</tr>
					</xsl:for-each>
				</xsl:for-each>
			</table>
		</div>
		<div class="mapbody" id="{$mapid}"/>
		<script>
			<xsl:value-of select="$mapid"/>=initMap('<xsl:value-of select="$mapid"/>');
			<xsl:if test="rdf:value!=''">addWKT(<xsl:value-of select="$mapid"/>,'<xsl:value-of select="rdf:value"/>');</xsl:if>
			<xsl:for-each select="geosparql:sfContains">
				<xsl:variable name="location" select="@rdf:resource"/>
				<xsl:for-each select="../../rdf:Description[@rdf:about=$location]/rdf:value">addWKT(<xsl:value-of select="$mapid"/>,'<xsl:value-of select="."/>','<xsl:if test="../xhtml:stylesheet!=''">s<xsl:value-of select="../xhtml:stylesheet"/></xsl:if>');</xsl:for-each>
			</xsl:for-each>
			<xsl:text>showMap(</xsl:text><xsl:value-of select="$mapid"/>);</script>
	</div>
</xsl:template>

<xsl:template match="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/1999/xhtml/vocab#list']" mode="makedoc">
	<ul class="fragment">
		<xsl:for-each select="xhtml:subsection"><xsl:sort select="@rdf:resource"/>
			<xsl:variable name="fragment" select="@rdf:resource"/>
			<li>
				<span class="marker"><xsl:value-of select="../../rdf:Description[@rdf:about=$fragment]/dc:title"/></span>
				<xsl:apply-templates select="../../rdf:Description[@rdf:about=$fragment]" mode="makedoc">
					<xsl:with-param name="parent">li</xsl:with-param>
				</xsl:apply-templates>
			</li>
		</xsl:for-each>
	</ul>
</xsl:template>

<xsl:template match="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/1999/xhtml/vocab#contents']" mode="makedoc">
	<xsl:variable name="head" select="rdf:value/@rdf:nodeID"/>
	<xsl:choose>
		<xsl:when test="$head!=''">
			<xsl:apply-templates select="../rdf:Description[@rdf:nodeID=$head]" mode="reclist"/>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="rdf:value"/></xsl:otherwise>
	</xsl:choose>
	<p class="break"/>
</xsl:template>
<xsl:template match="rdf:Description" mode="reclist">
	<xsl:variable name="uri" select="rdf:first/@rdf:resource"/>
	<xsl:variable name="link">
		<xsl:call-template name="resource-uri">
			<xsl:with-param name="uri" select="$uri"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$uri!=''">
			<a href="{$uri}" onclick="gotoFrame('{$link}');return false;"><xsl:value-of select="../rdf:Description[@rdf:about=$uri]/dc:title"/></a>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="rdf:first"/></xsl:otherwise>
	</xsl:choose>
	<xsl:variable name="tail" select="rdf:rest/@rdf:nodeID"/>
	<xsl:apply-templates select="../rdf:Description[@rdf:nodeID=$tail]" mode="reclist"/>
</xsl:template>

<!-- Failsafe -->
<xsl:template match="rdf:Description" mode="makedoc"/>

<xsl:template match="rdf:RDF" mode="TextAppearance">
	<xsl:variable name="doc">
		<xsl:for-each select="rdf:Description[exists(@rdf:about) and exists(xhtml:subsection)]">
			<xsl:variable name="uri" select="@rdf:about"/>
			<xsl:if test="not(exists(../rdf:Description[xhtml:subsection/@rdf:resource=$uri]))">
				<doc uri="{$uri}"><xsl:value-of select="dc:title"/></doc>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	<link rel="stylesheet" href="/css/leaflet.css{$ldtversion}" />
	<script src="/js/leaflet.js{$ldtversion}"></script>
	<script src="/js/proj4-compressed.js{$ldtversion}"></script>
	<script src="/js/proj4leaflet.js{$ldtversion}"></script>
	<script src="/js/rdfmap.min.js{$ldtversion}"></script>
	<style>
			<xsl:for-each select="rdf:Description[xhtml:stylesheet!='' and elmo:applies-to!='']">
				.s<xsl:value-of select="elmo:applies-to"/> {
				<xsl:value-of select="xhtml:stylesheet"/>
				}
			</xsl:for-each>
	</style>
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title"><a href="{$doc/doc[1]/@uri}"><xsl:value-of select="$doc/doc[1]"/></a></h3>
		</div>
		<div id="textdoc" class="panel-body">
			<xsl:apply-templates select="rdf:Description[@rdf:about=$doc/doc[1]/@uri]" mode="makedoc">
				<xsl:with-param name="parent">root</xsl:with-param>
			</xsl:apply-templates>
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>