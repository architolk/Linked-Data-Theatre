<!--

    NAME     rdf2svgi.xsl
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
	Transformation of RDF document to interactive SVG+HTML representation
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
>

<xsl:variable name="docroot"><xsl:value-of select="context/@docroot"/></xsl:variable>
<xsl:variable name="staticroot"><xsl:value-of select="context/@staticroot"/></xsl:variable>
<xsl:variable name="subdomain"><xsl:value-of select="context/subdomain"/></xsl:variable>
<xsl:variable name="subject"><xsl:value-of select="context/subject"/></xsl:variable>

<xsl:template match="/">
<html>
<head>
	<meta charset="utf-8"/>
	<meta http-equiv="X-UA-Compatible" content="IE=edge" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
	<title><xsl:value-of select="context/title"/></title>

	<link rel="stylesheet" type="text/css" href="{$staticroot}/css/bootstrap.min.css"/>
	<link rel="stylesheet" type="text/css" href="{$staticroot}/css/ldt-theme.min.css"/>
	<link rel="stylesheet" type="text/css" href="{$staticroot}/css/font-awesome.min.css"/>

	<!-- Alternative styling -->
	<xsl:for-each select="context/stylesheet">
		<link rel="stylesheet" type="text/css" href="{@href}"/>
	</xsl:for-each>
	
	<script type="text/javascript" src="{$staticroot}/js/jquery-1.11.3.min.js"></script>
	<script type="text/javascript" src="{$staticroot}/js/bootstrap.min.js"></script>
	<script type="text/javascript" src="{$staticroot}/js/d3.v3.min.js"></script>

</head>
<body>
	<div id="graphcanvas" style="position: relative">
		<div id="propertybox" style="position:absolute; display:none" onmouseover="mouseoverPropertyBox();" onmouseout="mouseoutPropertyBox();">
			<i id="mbtninfo" class="btn btn-primary" style="padding: 1px 4px;" onclick="clickInfoBox();">
				<span class="glyphicon glyphicon-info-sign" style="cursor:pointer"/>
			</i>
			<i id="mbtnexpand" class="btn btn-primary" style="padding: 1px 4px;" onclick="clickPropertyBox();">
				<span class="glyphicon glyphicon-zoom-in" style="cursor:pointer"/>
			</i>
		</div>
		<div class="panel panel-primary panel-secondary">
			<div id="graphtitle" class="panel-heading"/>
			<div id="graph" class="panel-body"/>
		</div>
	</div>
	<xsl:variable name="jsonParams"><xsl:for-each select="context/parameters/parameter"><xsl:value-of select="name"/>=<xsl:value-of select="encode-for-uri(value)"/>&amp;</xsl:for-each></xsl:variable>
	<script type="text/javascript">
		var jsonApiSubject = "<xsl:value-of select="context/subject"/>";
		var jsonApiCall = "<xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource.d3json?q=&amp;<xsl:value-of select="$jsonParams"/>subject=";
		var uriEndpoint = "<xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource?<xsl:value-of select="$jsonParams"/>subject=";
	</script>
	<script src="{$staticroot}/js/d3graphs-inner.min.js" type="text/javascript"/>
	<script type="text/javascript">
		togglefullscreen();
	</script>
</body>
</html>
</xsl:template>

</xsl:stylesheet>
