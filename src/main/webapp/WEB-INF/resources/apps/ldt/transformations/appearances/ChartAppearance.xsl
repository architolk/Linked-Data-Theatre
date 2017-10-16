<!--

    NAME     ChartAppearance.xsl
    VERSION  1.19.0
    DATE     2017-10-16

    Copyright 2012-2017

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
	<script>
		var data=[<xsl:for-each select="rdf:Description"><xsl:if test="position()!=1">,</xsl:if>{name:"<xsl:value-of select="rdfs:label"/>",value:<xsl:value-of select="rdf:value"/>}</xsl:for-each>];

		var margin = {top: 20, right: 30, bottom: 30, left: 40},
			width = 800 - margin.left - margin.right,
			height = 200 - margin.top - margin.bottom;

		var x = d3.scale.ordinal()
			.rangeRoundBands([0, width], .1);

		var y = d3.scale.linear()
			.range([height, 0])

		var xAxis = d3.svg.axis()
			.scale(x)
			.orient("bottom");

		var yAxis = d3.svg.axis()
			.scale(y)
			.orient("left");

		var chart = d3.select("#chart").append("svg")
			.attr("width", width + margin.left + margin.right)
			.attr("height", height + margin.top + margin.bottom)
		  .append("g")
			.attr("transform", "translate(" + margin.left + "," + margin.top + ")");

		x.domain(data.map(function (d) {return d.name;}));
		y.domain([0,d3.max(data, function (d) {return d.value;})]);
			
		  chart.append("g")
			  .attr("class", "x axis")
			  .attr("transform", "translate(0," + height + ")")
			  .call(xAxis);

		  chart.append("g")
			  .attr("class", "y axis")
			  .call(yAxis);

		  chart.selectAll(".bar")
			  .data(data)
			.enter().append("rect")
			  .attr("class", "bar")
			  .attr("x", function(d) { return x(d.name); })
			  .attr("y", function(d) { return y(d.value); })
			  .attr("height", function(d) { return height - y(d.value); })
			  .attr("width", x.rangeBand());
	</script>
</xsl:template>

</xsl:stylesheet>