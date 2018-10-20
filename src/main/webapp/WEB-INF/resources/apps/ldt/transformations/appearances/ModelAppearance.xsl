<!--

    NAME     ModelAppearance.xsl
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
	ModelAppearance, add-on of rdf2html.xsl
	
	A Model appearance creates a model from some linked data. It looks a bit like the GraphAppearance, but used for static models.

	NB: Model appearance uses the class structure, not the shape structure. A better approach could be to use both
	
	Depended on: ModelTemplates.xsl (in case of a elmo:VocabularyAppearance)
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:shacl="http://www.w3.org/ns/shacl#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
>

<xsl:output method="xml" indent="yes"/>

<xsl:template match="rdf:RDF" mode="ModelAppearance">
	<xsl:variable name="vocabulary"><xsl:apply-templates select="." mode="VocabularyVariable"/></xsl:variable>
	<link rel="stylesheet" href="{$staticroot}/css/joint.min.css{$ldtversion}" />
    <script src="{$staticroot}/js/lodash.min.js{$ldtversion}"></script>
    <script src="{$staticroot}/js/backbone-min.js{$ldtversion}"></script>
	<script src="{$staticroot}/js/graphlib.min.js{$ldtversion}"></script>
	<script src="{$staticroot}/js/dagre.min.js{$ldtversion}"></script>
    <script src="{$staticroot}/js/joint.min.js{$ldtversion}"></script>
	<div id="graphcanvas" style="position:relative;">
		<div class="panel panel-primary">
			<div class="panel-heading">
				<h3 class="panel-title">Model<span class="glyphicon glyphicon-fullscreen" style="position:absolute;right:10px;margin-top:10px;cursor:pointer" onclick="togglefullscreen()"/></h3>
			</div>
			<div class="panel-body">
				<div id="jointmodel"/>
				<xsl:variable name="cells">
					<!-- Nodes -->
					<xsl:for-each select="$vocabulary/nodeShapes/shape[@empty!='true']">
						<!-- Label generation copied from rdf2yed. Should be refactored to ModelTemplates -->
						<xsl:variable name="slabel">
							<xsl:choose>
								<xsl:when test="@class-uri!=''"><xsl:value-of select="replace(@class-uri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:when>
								<xsl:otherwise><xsl:value-of select="replace(@uri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="label">
							<xsl:value-of select="@name"/>
							<xsl:if test="not(@name!='')">
								<xsl:value-of select="$slabel"/>
								<xsl:if test="$slabel=''">
									<xsl:choose>
										<xsl:when test="@class-uri!=''"><xsl:value-of select="@class-uri"/></xsl:when>
										<xsl:otherwise><xsl:value-of select="@uri"/></xsl:otherwise>
									</xsl:choose>
								</xsl:if>
							</xsl:if>
						</xsl:variable>
						<xsl:if test="position()!=1">,</xsl:if>
						<xsl:text>{id:"</xsl:text><xsl:value-of select="@uri"/><xsl:text>"</xsl:text>
						<xsl:text>,type:"uml.State"</xsl:text>
						<xsl:text>,name:"</xsl:text><xsl:value-of select="$label"/><xsl:text>"</xsl:text>
						<xsl:text>,events:[</xsl:text>
						<!-- Properties -->
						<xsl:for-each select="property[not(exists(ref-nodes/item) or exists(refshape[@empty='false']))]">
							<xsl:if test="position()!=1">,</xsl:if>
							<xsl:text>"</xsl:text>
							<xsl:apply-templates select="." mode="property-placement"/>
							<xsl:text>"</xsl:text>
						</xsl:for-each>
						<!-- Enumerations -->
						<xsl:for-each select="enumvalue">
							<xsl:if test="position()=1">"Possible values:"</xsl:if>
							<xsl:text>,"&#x221a; </xsl:text><xsl:value-of select="@name"/>"
						</xsl:for-each>
						<!-- Deprecated
						<xsl:for-each select="shape">
							<xsl:variable name="shape" select="@uri"/>
							<xsl:for-each select="$vocabulary/nodeShapes/shape[@uri=$shape]/property[not(exists(@refclass))]">
								<xsl:variable name="propertyuri" select="@uri"/>
								<xsl:variable name="property" select="$vocabulary/properties/property[@uri=$propertyuri]"/>
								<xsl:variable name="label"><xsl:value-of select="$property/@label"/></xsl:variable>
								<xsl:variable name="datatype"><xsl:value-of select="$property/datatype/@uri"/></xsl:variable>
								<xsl:if test="position()!=1">,</xsl:if>
								<xsl:text>"</xsl:text>
									<xsl:value-of select="$label"/><xsl:if test="$label=''"><xsl:value-of select="replace($propertyuri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:if>
									<xsl:if test="$datatype!=''"> (<xsl:value-of select="replace($datatype,'^.*(#|/)([^(#|/)]+)$','$2')"/>)</xsl:if>
									<xsl:text> [</xsl:text><xsl:value-of select="@mincount"/>,<xsl:value-of select="@maxcount"/>
								<xsl:text>]"</xsl:text>
							</xsl:for-each>
						</xsl:for-each>
						-->
						<xsl:text>]</xsl:text>
						<xsl:text>,position:{x:300,y:300}</xsl:text>
						<xsl:text>,size:{width:100,height:100}</xsl:text>
						<xsl:text>}</xsl:text>
					</xsl:for-each>
					<!-- Logic nodes, with edges -->
					<xsl:for-each select="$vocabulary/nodeShapes/shape/property/ref-nodes">
						<xsl:variable name="nodeuri" select="@uri"/>
						<xsl:text>,{id:"</xsl:text><xsl:value-of select="$nodeuri"/><xsl:text>"</xsl:text>
						<xsl:text>,type:"uml.StartState"</xsl:text>
						<xsl:text>,attrs: {circle: {fill: "#ffffff"}, text: {text: "</xsl:text><xsl:value-of select="@logic"/><xsl:text>"}}</xsl:text>
						<xsl:text>,position:{x:300,y:300}</xsl:text>
						<xsl:text>,size:{width:35,height:35}</xsl:text>
						<xsl:text>}</xsl:text>
						<xsl:for-each select="item">
							<xsl:variable name="refuri" select="@uri"/>
							<xsl:variable name="refshape" select="$vocabulary/nodeShapes/shape[@uri=$refuri]"/>
							<xsl:if test="$refshape/@empty!='true'">
								<edge source="{$nodeuri}" target="{@uri}"/>
								<xsl:text>,{id:"</xsl:text><xsl:value-of select="$nodeuri"/>#<xsl:value-of select="@uri"/><xsl:text>"</xsl:text>
								<xsl:text>,type:"link"</xsl:text>
								<xsl:text>,source:{id:"</xsl:text><xsl:value-of select="$nodeuri"/><xsl:text>"}</xsl:text>
								<xsl:text>,target:{id:"</xsl:text><xsl:value-of select="@uri"/><xsl:text>"}</xsl:text>
								<xsl:text>,router:{name:"manhattan"}</xsl:text>
								<xsl:text>,connector:{name:"normal"}</xsl:text>
								<xsl:text>}</xsl:text>
							</xsl:if>
						</xsl:for-each>
					</xsl:for-each>
					<!-- Links: superclasses -->
					<xsl:for-each select="$vocabulary/nodeShapes/shape[@class-uri!='' and @empty!='true']">
						<xsl:variable name="source" select="@uri"/>
						<xsl:variable name="class" select="@class-uri"/>
						<xsl:for-each select="$vocabulary/classes/class[@uri=$class]/super">
							<xsl:variable name="super" select="@uri"/>
							<xsl:for-each select="$vocabulary/nodeShapes/shape[@class-uri=$super and @empty!='true']">
								<xsl:text>,{id:"</xsl:text><xsl:value-of select="$source"/>#<xsl:value-of select="@uri"/><xsl:text>"</xsl:text>
								<xsl:text>,type:"link"</xsl:text>
								<xsl:text>,source:{id:"</xsl:text><xsl:value-of select="$source"/><xsl:text>"}</xsl:text>
								<xsl:text>,target:{id:"</xsl:text><xsl:value-of select="@uri"/><xsl:text>"}</xsl:text>
								<xsl:text>,router:{name:"manhattan"}</xsl:text>
								<xsl:text>,connector:{name:"normal"}</xsl:text>
								<xsl:text>,ldttype: "isa"</xsl:text>
								<xsl:text>}</xsl:text>
							</xsl:for-each>
						</xsl:for-each>
					</xsl:for-each>
					<!-- Links: objectproperties -->
					<xsl:for-each select="$vocabulary/nodeShapes/shape[@empty!='true']/property/(refshape|ref-nodes)">
						<xsl:variable name="refuri" select="@uri"/>
						<xsl:variable name="refshape" select="$vocabulary/nodeShapes/shape[@uri=$refuri]"/>
						<xsl:if test="local-name()='ref-nodes' or $refshape/@empty!='true'">
							<xsl:text>,{id:"</xsl:text><xsl:value-of select="../../@uri"/><xsl:value-of select="../@uri"/><xsl:value-of select="@uri"/><xsl:text>"</xsl:text>
							<xsl:text>,type:"link"</xsl:text>
							<xsl:text>,source:{id:"</xsl:text><xsl:value-of select="../../@uri"/><xsl:text>"}</xsl:text>
							<xsl:text>,target:{id:"</xsl:text><xsl:value-of select="@uri"/><xsl:text>"}</xsl:text>
							<xsl:text>,router:{name:"manhattan"}</xsl:text>
							<xsl:text>,connector:{name:"normal"}</xsl:text>
							<xsl:choose>
								<xsl:when test="@type='role'">,ldttype:"role"</xsl:when>
								<xsl:otherwise>
									<xsl:text>,labels: [{ position: 0.5, attrs: { text: { text: "</xsl:text>
									<xsl:apply-templates select=".." mode="property-placement"/>
									<xsl:text>" } } }]</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:text>}</xsl:text>
						</xsl:if>
					</xsl:for-each>
					<!--
					<xsl:for-each select="$vocabulary/classes/class/shape">
						<xsl:variable name="shape" select="@uri"/>
						<xsl:for-each select="$vocabulary/nodeShapes/shape[@uri=$shape]/property[@refclass!='']">
							<xsl:variable name="target" select="@refclass"/>
							<xsl:if test="exists($vocabulary/classes/class[@uri=$target])">
								<xsl:variable name="propertyuri" select="@uri"/>
								<xsl:variable name="property" select="$vocabulary/properties/property[@uri=$propertyuri]"/>
								<xsl:variable name="label"><xsl:value-of select="$property/@label"/></xsl:variable>
								<xsl:text>,{id:"</xsl:text><xsl:value-of select="../@class-uri"/><xsl:value-of select="$propertyuri"/><xsl:value-of select="$target"/><xsl:text>"</xsl:text>
								<xsl:text>,type:"link"</xsl:text>
								<xsl:text>,source:{id:"</xsl:text><xsl:value-of select="../@class-uri"/><xsl:text>"}</xsl:text>
								<xsl:text>,target:{id:"</xsl:text><xsl:value-of select="$target"/><xsl:text>"}</xsl:text>
								<xsl:text>,router:{name:"manhattan"}</xsl:text>
								<xsl:text>,connector:{name:"normal"}</xsl:text>
								<xsl:text>,labels: [{ position: 0.5, attrs: { text: { text: "</xsl:text>
									<xsl:value-of select="$label"/><xsl:if test="$label=''"><xsl:value-of select="replace($propertyuri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:if>
									<xsl:text> [</xsl:text><xsl:value-of select="@mincount"/>,<xsl:value-of select="@maxcount"/>
								<xsl:text>]" } } }]</xsl:text>
								<xsl:text>}</xsl:text>
							</xsl:if>
						</xsl:for-each>
					</xsl:for-each>
					-->
				</xsl:variable>
				<script type="text/javascript">
					var cells = {cells: [<xsl:value-of select="$cells"/>]};
				</script>
				<script src="{$staticroot}/js/linkedmodel.min.js{$ldtversion}"></script>
			</div>
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>