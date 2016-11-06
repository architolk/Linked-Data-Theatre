<!--

    NAME     FrameAppearance.xsl
    VERSION  1.12.1-SNAPSHOT
    DATE     2016-11-06

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

<xsl:template match="rdf:RDF" mode="FrameAppearance">
	<script>
function getDocHeight(doc) {
    doc = doc || document;
    // stackoverflow.com/questions/1145850/
    var body = doc.body, html = doc.documentElement;
    var height = Math.max( body.scrollHeight, body.offsetHeight, 
        html.clientHeight, html.scrollHeight, html.offsetHeight );
    return height;
}
function setHeight(id) {
    var ifrm = document.getElementById(id);
    var doc = ifrm.contentDocument? ifrm.contentDocument: 
        ifrm.contentWindow.document;
    ifrm.style.visibility = 'hidden';
    ifrm.style.height = "10px"; // reset to minimal height ...
    // IE opt. for bing/msn needs a bit added or scrollbar appears
    ifrm.style.height = getDocHeight( doc ) + 4 + "px";
    ifrm.style.visibility = 'visible';
}
	</script>
	<style>
		.innerFrame {
			width: 100%;
			height: 400px;
			border: 0;
			overflow: hidden;
		}
		.frameScroll {
			width: 50%;
			float: left;
		}
		.frameFixed {
			width: 50%;
			float: right;
			right: 15px;
			position:fixed;
		}
	</style>
	<div style="row">
		<xsl:for-each select="rdf:Description[html:link!='']"><xsl:sort select="elmo:index"/>
			<xsl:variable name="frameclass">
				<xsl:choose>
					<xsl:when test="position()=1">frameScroll</xsl:when>
					<xsl:otherwise>frameFixed</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<div class="{$frameclass}">
				<iframe class="innerFrame" src="{html:link}" scrolling="no" id="frame{position()}" name="frame{position()}" onload="setHeight(this.id);"/>
			</div>
		</xsl:for-each>
	</div>
</xsl:template>

</xsl:stylesheet>