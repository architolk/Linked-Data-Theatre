<!--

    NAME     rdf2svgi.xsl
    VERSION  1.6.0
    DATE     2016-03-13

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
﻿<!--
    DESCRIPTION
	Transformation of RDF document to interactive SVG+HTML representation
	
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">

<xsl:template match="/">
<html>
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
<!-- Styling of tooltip --> <!-- Deprecated? Tooltip is still part of d3graphs.js, but not in use?? -->
div.tooltip {   
  position: absolute;           
  text-align: left;           
  padding: 2px;             
  display: inline;
  display: inline-block;
  font: 12px sans-serif;        
  background: #FFFFE0;   
  border: 1px solid black;
  pointer-events: none;
}
div.tooltip table tr td {
  vertical-align: top;
}
div.tooltip table tr td.data {
  width: 300px;
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
	font-family: Lucida Grande, sans-serif;
	background-color: black;
	border-radius: 5px;
	-moz-border-radius: 5px;
	font-size: 0.8em;
	position:absolute;
	top: 5px;
	right: 5px;
	width: 300px;
	display: hidden;
	padding: 5px;
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
</style>
<body>
</body>
<script src="/config/js/d3.min.js" type="text/javascript"/>
<script type="text/javascript">
	var jsonApiSubject = "<xsl:value-of select="context/subject"/>";
	var jsonApiCall = "resource.d3json?subject=";
</script>
<script src="/config/js/d3graphs.js" type="text/javascript"/>
</html>
</xsl:template>

</xsl:stylesheet>
