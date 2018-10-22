<!--

    NAME     ChartAppearance.xsl
    VERSION  1.23.1-SNAPSHOT
    DATE     2018-10-22

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
	ChartAppearance, add-on of rdf2html.xsl

	Show linked data as a Chart.

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:qb="http://purl.org/linked-data/cube#"
>

<xsl:output method="xml" indent="yes"/>

<xsl:template match="rdf:RDF" mode="ChartAppearance">
	<!-- Find measurements and dimensions -->
	<xsl:variable name="measures" select="qb:MeasureProperty|rdf:Description[rdf:type/@rdf:resource='http://purl.org/linked-data/cube#MeasureProperty']"/>
	<xsl:variable name="dimensions" select="qb:DimensionProperty|rdf:Description[rdf:type/@rdf:resource='http://purl.org/linked-data/cube#DimensionProperty']"/>
	<!-- Get observations -->
	<xsl:variable name="observations">
		<xsl:for-each select="rdf:Description">
			<xsl:variable name="filters">
				<xsl:for-each select="*">
					<xsl:variable name="uri" select="concat(namespace-uri(),local-name())"/>
					<xsl:if test="exists($dimensions[@rdf:about=$uri])">
						<dimension><xsl:value-of select="$uri"/></dimension>
					</xsl:if>
					<xsl:if test="exists($measures[@rdf:about=$uri])">
						<measure><xsl:value-of select="$uri"/></measure>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			<xsl:choose>
				<!-- Using dimensions and measures -->
				<xsl:when test="exists($filters/dimension) and exists($filters/measure)">
					<xsl:variable name="dimension" select="*[$filters/dimension[1]=concat(namespace-uri(),local-name())][1]"/>
					<xsl:variable name="measure" select="*[$filters/measure[1]=concat(namespace-uri(),local-name())][1]"/>
					<observation dimension="{$dimension}" dimension-datatype="{$dimension/@rdf:datatype}" measure-datatype="{$measure/@rdf:datatype}">
						<xsl:value-of select="$measure"/>
					</observation>
				</xsl:when>
				<!-- Fallback: using rdfs:label for dimension and rdf:value for measure -->
				<xsl:otherwise>
					<xsl:if test="exists(rdfs:label) and exists(rdf:value)">
						<xsl:variable name="label">
							<xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdfs:label"/></xsl:call-template>
						</xsl:variable>
						<observation dimension="{$label}" dimension-datatype="string" measure-datatype="{rdf:value[1]/@rdf:datatype}"><xsl:value-of select="rdf:value[1]"/></observation>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:variable>
	<div class="panel panel-primary">
		<div class="panel-heading"/>
		<div id="chart" class="panel-body">
		</div>
	</div>
	<script src="{$staticroot}/js/chart.min.js" type="text/javascript"/>
	<script>
		<xsl:text>var data=[</xsl:text>
		<xsl:for-each select="$observations/observation">
			<xsl:if test="position()!=1">,</xsl:if>
			<xsl:text>{d:</xsl:text>
			<xsl:if test="@dimension-datatype='http://www.w3.org/2001/XMLSchema#dateTime'">new Date(</xsl:if>
			<xsl:if test="@dimension-datatype!='http://www.w3.org/2001/XMLSchema#decimal' and @dimension-datatype!='http://www.w3.org/2001/XMLSchema#integer'">"</xsl:if>
			<xsl:value-of select="@dimension"/>
			<xsl:if test="@dimension-datatype!='http://www.w3.org/2001/XMLSchema#decimal' and @dimension-datatype!='http://www.w3.org/2001/XMLSchema#integer'">"</xsl:if>
			<xsl:if test="@dimension-datatype='http://www.w3.org/2001/XMLSchema#dateTime'">)</xsl:if>
			<xsl:text>,m:</xsl:text><xsl:value-of select="."/>
			<xsl:text>}</xsl:text>
		</xsl:for-each>
		<xsl:text>];</xsl:text>

		plotChart(data,"<xsl:value-of select="substring-after(@elmo:appearance,'#')"/>","<xsl:value-of select="substring-after($observations/observation[1]/@dimension-datatype,'#')"/>","<xsl:value-of select="substring-after($observations/observation[1]/@measure-datatype,'#')"/>")

	</script>
</xsl:template>

</xsl:stylesheet>
