<!--

    NAME     GeoAppearance.xsl
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
	GeoAppearance, add-on of rdf2html.xsl
	
	GeoAppearance is used for presenting a geographical representation of the data (as WKT string)
	This file is also used for the ImageAppearance

	TODO: Including a <style> element within a <div> is not compliant to html5: this has to change
		  The best way is to migrate this to the javascript part of the code
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
>

<xsl:output method="xml" indent="yes"/>

<xsl:template match="*" mode="safejsonstring">
	<xsl:variable name="filter">(")</xsl:variable>
	<xsl:value-of select="replace(replace(replace(.,'\\','\\\\'),'[&#13;]{0,1}&#10;','\\n'),$filter,'\\$1')"/>
</xsl:template>

<xsl:template match="rdf:RDF" mode="GeoAppearance">
	<xsl:param name="backmap"/>
	<xsl:param name="appearance"/>

	<xsl:if test="exists(rdf:Description/@rdf:about)">

		<xsl:choose>
			<xsl:when test="$backmap='image'">
				<link href="{$staticroot}/css/leaflet.css{$ldtversion}" rel="stylesheet"/>
				<script src="{$staticroot}/js/leaflet.js{$ldtversion}"></script>
				<script src="{$staticroot}/js/leaflet.label.js{$ldtversion}"></script>
				<script src="{$staticroot}/js/easy-button.js{$ldtversion}"></script>
				<!-- Print form -->
				<form id="svgform" method="post" action="{$subdomain}/print-graph" enctype="multipart/form-data">
					<input type="hidden" id="type" name="type" value=""/>
					<input type="hidden" id="data" name="data" value=""/>
					<input type="hidden" id="dimensions" name="dimensions" value=""/>
					<input type="hidden" id="imgsrc" name="imgsrc" value=""/>
				</form>
				<!-- TOT HIER -->
			</xsl:when>
			<xsl:otherwise>
				<link href="{$staticroot}/css/leaflet.css{$ldtversion}" rel="stylesheet"/>
				<script src="{$staticroot}/js/leaflet.js{$ldtversion}"></script>
				<script src="{$staticroot}/js/proj4-compressed.js{$ldtversion}"></script>
				<script src="{$staticroot}/js/proj4leaflet.js{$ldtversion}"></script>
				<script src="{$staticroot}/js/leaflet-tilelayer-wmts.min.js{$ldtversion}"></script>
				<!-- Clickable map form -->
				<xsl:variable name="link" select="rdf:Description[elmo:applies-to='http://bp4mc2.org/elmo/def#Appearance']/html:link[1]"/>
				<xsl:variable name="action">
					<xsl:choose>
						<xsl:when test="$link!=''"><xsl:value-of select="$link"/></xsl:when>
						<xsl:otherwise>#</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<form id="clickform" method="get" action="{$action}">
					<input type="hidden" id="lat" name="lat" value=""/>
					<input type="hidden" id="long" name="long" value=""/>
					<input type="hidden" id="zoom" name="zoom" value=""/>
				</form>
			</xsl:otherwise>
		</xsl:choose>
		<script src="{$staticroot}/js/linkeddatamap.min.js{$ldtversion}"></script>
		
		<xsl:variable name="latlocator" select="rdf:Description[rdf:type/@rdf:resource='http://bp4mc2.org/elmo/def#GeoLocator'][1]/geo:lat"/>
		<xsl:variable name="latdata">
			<xsl:value-of select="$latlocator"/>
			<xsl:if test="not($latlocator!='')"><xsl:value-of select="rdf:Description[1]/geo:lat"/></xsl:if>
		</xsl:variable>
		<xsl:variable name="lat">
			<xsl:choose>
				<xsl:when test="not($latdata!='') or contains($latdata,'@')">52.155</xsl:when>
				<xsl:otherwise><xsl:value-of select="$latdata"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="longlocator" select="rdf:Description[rdf:type/@rdf:resource='http://bp4mc2.org/elmo/def#GeoLocator'][1]/geo:long"/>
		<xsl:variable name="longdata">
			<xsl:value-of select="$longlocator"/>
			<xsl:if test="not($longlocator!='')"><xsl:value-of select="rdf:Description[1]/geo:long"/></xsl:if>
		</xsl:variable>
		<xsl:variable name="long">
			<xsl:choose>
				<xsl:when test="not($longdata!='') or contains($longdata,'@')">5.38</xsl:when>
				<xsl:otherwise><xsl:value-of select="$longdata"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="doZoom">
			<xsl:choose>
				<xsl:when test="$longdata!=''">0</xsl:when>
				<xsl:otherwise>1</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="zoomdata"><xsl:value-of select="/results/context/parameters/parameter[name='zoom']/value"/></xsl:variable>
		<xsl:variable name="zoom">
			<xsl:value-of select="$zoomdata"/>
			<xsl:if test="not($zoomdata!='')">5</xsl:if>
		</xsl:variable>
		<xsl:variable name="htmlimg" select="rdf:Description/html:img"/>
		<xsl:variable name="htmlleft" select="rdf:Description/html:left"/>
		<xsl:variable name="htmltop" select="rdf:Description/html:top"/>
		<xsl:variable name="htmlwidth" select="rdf:Description/html:width"/>
		<xsl:variable name="htmlheight" select="rdf:Description/html:height"/>
		<xsl:variable name="container" select="@elmo:container"/>
		<xsl:variable name="img"><xsl:value-of select="$htmlimg"/><xsl:if test="not($htmlimg!='')">Background.png</xsl:if></xsl:variable>
		<xsl:variable name="left"><xsl:value-of select="$htmlleft"/><xsl:if test="not($htmlleft!='')">0</xsl:if></xsl:variable>
		<xsl:variable name="top"><xsl:value-of select="$htmltop"/><xsl:if test="not($htmltop!='')">0</xsl:if></xsl:variable>
		<xsl:variable name="width"><xsl:value-of select="$htmlwidth"/><xsl:if test="not($htmlwidth!='')">1000</xsl:if></xsl:variable>
		<xsl:variable name="height"><xsl:value-of select="$htmlheight"/><xsl:if test="not($htmlheight!='')">600</xsl:if></xsl:variable>
		
		<xsl:variable name="icons">
			<xsl:for-each select="rdf:Description[html:icon!='' and elmo:applies-to!='' and not(matches(elmo:applies-to,'^http://bp4mc2.org/elmo/def'))]">
				<icon class="{elmo:applies-to}"><xsl:value-of select="html:icon"/></icon>
			</xsl:for-each>
		</xsl:variable>
		
		<style>
				.shidden-object {
					display:none;
					pointer-events: none;
				}
				.sdefault {
					stroke: #3388ff;
					fill: #3388ff;
				}
			<xsl:for-each select="rdf:Description[html:stylesheet!='' and elmo:applies-to!='' and not(matches(elmo:applies-to,'^http://bp4mc2.org/elmo/def'))]">
				.s<xsl:value-of select="elmo:applies-to"/> {
				<xsl:value-of select="html:stylesheet"/>
				}
				.edgestyle {
					stroke: #606060;
					stroke-width: 2px;
					pointer-events: none;
				}
			</xsl:for-each>
			<xsl:choose>
				<xsl:when test="exists(rdf:Description[html:stylesheet!='' and elmo:applies-to='http://bp4mc2.org/elmo/def#Appearance'])">
					.leaflet-container {
						<xsl:value-of select="rdf:Description[elmo:applies-to='http://bp4mc2.org/elmo/def#Appearance']/html:stylesheet[1]"/>
					}
				</xsl:when>
				<xsl:otherwise>
					.leaflet-container {
						height: 500px;
						width: 100%;
					}
				</xsl:otherwise>
			</xsl:choose>
		</style>
		<div class="panel panel-primary">
			<div class="panel-heading">
				<xsl:variable name="count" select="count(rdf:Description[(geo:lat!='' and geo:long!='' and rdfs:label!='') or geo:geometry!=''])"/>
				<xsl:choose>
					<xsl:when test="$count=0 and not($zoomdata!='')"/>
					<xsl:when test="$count=0">Niets gevonden</xsl:when>
					<xsl:otherwise>Aantal gevonden: <xsl:value-of select="$count"/></xsl:otherwise>
				</xsl:choose>
			</div>
			<div class="panel-body">
				<div id="map"></div>
				<!-- TODO: width en height moet ergens vandaan komen. Liefst uit plaatje, maar mag ook uit eigenschappen -->
				<script type="text/javascript">
					initMap("<xsl:value-of select="$staticroot"/>",<xsl:value-of select="replace($zoom,'[^0-9\.]','')"/>,<xsl:value-of select="replace($lat,'[^0-9\.]','')"/>, <xsl:value-of select="replace($long,'[^0-9\.]','')"/>, "<xsl:value-of select="$backmap"/>", "<xsl:value-of select="$img"/>", "<xsl:value-of select="$container"/>", <xsl:value-of select="$left"/>, <xsl:value-of select="replace($top,'[^0-9\.]','')"/>, <xsl:value-of select="replace($width,'[^0-9\.]','')"/>, <xsl:value-of select="replace($height,'[^0-9\.]','')"/>, "<xsl:value-of select="/results/context/subject"/>");

					<xsl:for-each select="rdf:Description[elmo:applies-to='http://bp4mc2.org/elmo/def#Appearance' and elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#TransparantOverlay']">
						<xsl:variable name="layers">
							<xsl:for-each select="elmo:layer[.!='']"><xsl:if test="position()!=1">,</xsl:if><xsl:value-of select="."/></xsl:for-each>
						</xsl:variable>
						addOverlay('<xsl:value-of select="elmo:service"/>','<xsl:value-of select="$layers"/>',true);
					</xsl:for-each>
					
					<xsl:for-each select="rdf:Description[geo:lat!='' and geo:long!='' and rdfs:label!='']">
						<xsl:variable name="resource-uri"><xsl:call-template name="resource-uri"><xsl:with-param name="uri" select="@rdf:about"/></xsl:call-template></xsl:variable>
						addPoint(<xsl:value-of select="geo:lat[1]"/>,<xsl:value-of select="geo:long[1]"/>,"<xsl:apply-templates select="rdfs:label" mode="safejsonstring"/>","<xsl:value-of select="$resource-uri"/>","<xsl:value-of select="rdf:value"/>","<xsl:value-of select="html:icon"/>");
					</xsl:for-each>
					<xsl:for-each select="rdf:Description[geo:geometry!='']"><xsl:sort select="string-length(geo:geometry[1])" data-type="number" order="descending"/>
						<xsl:variable name="link-uri">
							<xsl:choose>
								<xsl:when test="exists(html:link)"><xsl:copy-of select="html:link"/></xsl:when>
								<xsl:otherwise><html:link rdf:resource="{@rdf:about}"/></xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="resource-uri">
							<xsl:call-template name="resource-uri">
								<xsl:with-param name="uri" select="$link-uri/html:link/@rdf:resource"/>
								<xsl:with-param name="var" select="$link-uri/html:link"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:variable name="styleuri" select="elmo:style/@rdf:resource"/>
						<xsl:variable name="styleclass">
							<xsl:choose>
								<xsl:when test="$styleuri='http://bp4mc2.org/elmo/def#HiddenStyle'">hidden-object</xsl:when>
								<xsl:when test="html:stylesheet!=''"><xsl:value-of select="html:stylesheet"/></xsl:when>
								<xsl:otherwise><xsl:value-of select="../rdf:Description[@rdf:about=$styleuri]/elmo:name[1]"/></xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						addWKT("<xsl:value-of select="@rdf:about"/>","<xsl:value-of select="geo:geometry[1]"/>","<xsl:value-of select="rdfs:label[1]"/>","<xsl:value-of select="$resource-uri"/>","s<xsl:value-of select="$styleclass"/><xsl:if test="$styleclass=''">default</xsl:if>","<xsl:value-of select="$icons/icon[@class=$styleclass]"/>");
					</xsl:for-each>

					<xsl:for-each select="rdf:Description[geo:geometry!='']/(* except (html:link|elmo:style))[exists(@rdf:resource)]">
						addEdge("<xsl:value-of select="../@rdf:about"/>","<xsl:value-of select="name()"/>","<xsl:value-of select="@rdf:resource"/>");
					</xsl:for-each>
					
					showLocations(<xsl:value-of select="$doZoom"/>,"<xsl:value-of select="$appearance"/>");
				</script>
			</div>
		</div>
	</xsl:if>
	
</xsl:template>

</xsl:stylesheet>