<!--

    NAME     GraphAppearance.xsl
    VERSION  1.22.0
    DATE     2018-06-13

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
	GraphAppearance, add-on of rdf2html.xsl

	A GraphAppearance shows Linked Data as a graph, plus the opportunity to navigate through the linked data (expand the graph)

	TODO: Including a <style> element within a <div> is not compliant to html5: this has to change
		  Solution might be to migrate the code to the javascript part
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
	<div id="graphcanvas" style="position: relative">
		<xsl:if test="exists(rdf:Description[html:stylesheet!='' and elmo:applies-to!=''])">
			<div class="panel panel-primary" style="position:absolute;right:20px;top:50px">
				<div class="panel-heading"><span class="glyphicon glyphicon-off" style="position:absolute;right:5px;margin-top:2px;cursor:pointer" onclick="this.parentNode.parentNode.style.display='none'"/></div>
				<table style="margin-left:10px">
					<xsl:for-each select="rdf:Description[html:stylesheet!='' and elmo:applies-to!='']"><xsl:sort select="elmo:index"/>
						<tr>
							<td><input name="{elmo:applies-to}" type="checkbox" checked="checked" onclick="togglenode(this.checked,this.name);"/></td>
							<td><svg style="display: inline;" class="legend" width="140" height="30"><g><rect x="5" y="5" width="120" height="22" class="s{elmo:applies-to}"/><text x="15" y="20" class="graph-legend"><xsl:value-of select="elmo:applies-to"/></text></g></svg></td>
						</tr>
					</xsl:for-each>
				</table>
			</div>
		</xsl:if>
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
	<style>
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
	<xsl:variable name="link"><xsl:value-of select="rdf:Description[elmo:applies-to='http://bp4mc2.org/elmo/def#Appearance']/html:link[1]"/></xsl:variable>
	<xsl:variable name="jsonApiCall">
		<xsl:choose>
			<xsl:when test="$link!='' and substring($link,1,1)='/'"><xsl:value-of select="$link"/>?</xsl:when>
			<xsl:when test="$link!='' and not(substring($link,1,1)='/')"><xsl:value-of select="$subdomain"/><xsl:value-of select="$link"/>?</xsl:when>
			<xsl:otherwise><xsl:value-of select="$subdomain"/>/resource?representation=<xsl:value-of select="encode-for-uri(@elmo:query)"/>&amp;</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="jsonParams"><xsl:for-each select="/results/context/parameters/parameter"><xsl:value-of select="name"/>=<xsl:value-of select="encode-for-uri(value)"/>&amp;</xsl:for-each></xsl:variable>
	<!-- TODO: jsonApiCall is changed to resource? instead of resource.d3json? -> This means that de javascript should use regular JSON-LD! -->
	<script type="text/javascript">
		var jsonApiSubject = "<xsl:value-of select="/results/context/subject"/>";
		var jsonApiCall = "<xsl:value-of select="$docroot"/><xsl:value-of select="$jsonApiCall"/>date=<xsl:value-of select="/results/context/date"/>&amp;<xsl:value-of select="$jsonParams"/>subject=";
		var uriEndpoint = "<xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource?<xsl:value-of select="$jsonParams"/>subject=";
	</script>
	<script src="{$staticroot}/js/jsonld.min.js" type="text/javascript"/>
	<script src="{$staticroot}/js/d3graphs-inner.min.js" type="text/javascript"/>
</xsl:template>

</xsl:stylesheet>
