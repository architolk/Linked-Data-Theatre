<!--

    NAME     GraphAppearance.xsl
    VERSION  1.11.1-SNAPSHOT
    DATE     2016-09-29

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
	GraphAppearance, add-on of rdf2html.xsl
	
	A GraphAppearance shows Linked Data as a graph, plus the opportunity to navigate through the linked data (expand the graph)
	
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

<xsl:template match="rdf:RDF" mode="GraphAppearance">
	<div style="position: relative">
		<xsl:if test="exists(rdf:Description[html:stylesheet!='' and elmo:applies-to!=''])">
			<div class="panel panel-primary" style="position:absolute;right:20px;top:50px">
				<div class="panel-heading"><span class="glyphicon glyphicon-off" style="position:absolute;right:5px;margin-top:2px;cursor:pointer" onclick="this.parentNode.parentNode.style.display='none'"/></div>	
				<table style="margin-left:10px">
					<xsl:for-each select="rdf:Description[html:stylesheet!='' and elmo:applies-to!='']">
						<tr>
							<td><input name="{elmo:applies-to}" type="checkbox" checked="checked" onclick="togglenode(this.checked,this.name);"/></td>
							<td><svg style="display: inline;" width="140" height="30"><g><rect x="5" y="5" width="120" height="20" class="s{elmo:applies-to}"/><text x="15" y="18" style="line-height: normal; font-family: sans-serif; font-size: 10px; font-style: normal; font-variant: normal; font-weight: normal; font-size-adjust: none; font-stretch: normal;"><xsl:value-of select="elmo:applies-to"/></text></g></svg></td>
						</tr>
					</xsl:for-each>
				</table>
			</div>
		</xsl:if>
		<div class="panel panel-primary panel-secondary">
			<div id="graphtitle" class="panel-heading"/>
			<div id="graph" class="panel-body"/>
		</div>
	</div>
	<style>
	<!-- Styling for the edge between nodes -->
	.link line.border {
	  stroke: #fff;
	  stroke-opacity: 0;
	  stroke-width: 8px;
	}
	.link line.stroke {
	  pointer-events: none;
	}
	.link text {
	  pointer-events: none;
	}
	<!-- Styling of nodes -->
	.node text {
	  pointer-events: none;
	}
	<!-- Styling of canvas -->
	.canvas {
	  fill: none;
	  pointer-events: all;
	}
	<!-- Default styling (should be part of node or edge??) -->
	.default {
		fill: white;
		fill-opacity: .3;
		stroke: #666;
	}
	<!-- DIV Detailbox -->
	div.detailbox {
		background-color: black;
		border-radius: 5px;
		-moz-border-radius: 5px;
		font-size: 0.8em;
		top: 5px;
		right: 5px;
		width: 300px;
		padding: 5px;
		position: absolute;
	}
	div.detailbox div.header {
		color: white;
		font-weight: bold;
		margin: 0px 0px 5px;
	}
	div.detailbox div.button {
		height: 30px;
		padding: 0px;
	}

	div.detailbox table {
		width:100%;
		background-color:white;
		table-layout: fixed;
		word-wrap:break-word;
	}
	div.detailbox table tr td.data {
		width:80%;
	}

	div.detailbox div.button #expand {
		padding: 5px;
		float: right;
		text-align: right;
		z-index: 5000;
		background-color: #808080;
		border-color: #808080;
		color: white;
		cursor: pointer;
		border-radius: 5px;
		-moz-border-radius: 5px;
		padding-left: 15px;
		text-indent: -10px;
		font-weight: bold;
	}
	<xsl:for-each select="rdf:Description[html:stylesheet!='' and elmo:applies-to!='']">
		.s<xsl:value-of select="elmo:applies-to"/> {
		<xsl:value-of select="html:stylesheet"/>
		}
	</xsl:for-each>
	<xsl:for-each select="rdf:Description[html:stylesheet!='' and elmo:applies-to!='']">
		.t<xsl:value-of select="elmo:applies-to"/> {
			visibility: visible
		}
	</xsl:for-each>
	</style>
	<script type="text/javascript">
		var jsonApiSubject = "<xsl:value-of select="/results/context/subject"/>";
		var jsonApiCall = "<xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource.d3json?representation=<xsl:value-of select="encode-for-uri(@elmo:query)"/>&amp;subject=";
		var uriEndpoint = "<xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource?subject=";
	</script>
	<script src="{$staticroot}/js/d3graphs-inner.min.js" type="text/javascript"/>
</xsl:template>

</xsl:stylesheet>