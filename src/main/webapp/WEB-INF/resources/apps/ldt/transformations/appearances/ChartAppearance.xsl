<!--

    NAME     ChartAppearance.xsl
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
	ChartAppearance, add-on of rdf2html.xsl

	Show linked data as a Chart.

	TODO: Chart appearance now uses rdfs:label (X axes) and rdf:value (Y axes). Should probably use datacube ontology.

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

<xsl:template match="rdf:RDF" mode="ChartAppearance">
	<div class="panel panel-primary">
		<div class="panel-heading"/>
		<div id="chart" class="panel-body">
		</div>
	</div>
	<script src="{$staticroot}/js/chart.min.js" type="text/javascript"/>
	<script>
		var data=[<xsl:for-each select="rdf:Description"><xsl:if test="position()!=1">,</xsl:if>{name:"<xsl:value-of select="rdfs:label"/>",value:<xsl:value-of select="rdf:value"/>}</xsl:for-each>];

		plotChart(data,"<xsl:value-of select="substring-after(@elmo:appearance,'#')"/>")

	</script>
</xsl:template>

</xsl:stylesheet>
