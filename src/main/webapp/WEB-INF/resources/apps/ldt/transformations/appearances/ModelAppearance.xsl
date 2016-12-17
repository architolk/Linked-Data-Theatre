<!--

    NAME     ModelAppearance.xsl
    VERSION  1.13.1-SNAPSHOT
    DATE     2016-12-06

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
	ModelAppearance, add-on of rdf2html.xsl
	
	A Model appearance creates a model from some linked data. It looks a bit like the GraphAppearance, but used for static models.
	
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

<xsl:template match="rdf:RDF" mode="ModelAppearance">
	<link rel="stylesheet" href="{$staticroot}/css/joint.min.css" />
    <script src="{$staticroot}/js/lodash.min.js"></script>
    <script src="{$staticroot}/js/backbone.min.js"></script>
	<script src="{$staticroot}/js/graphlib.min.js"></script>
	<script src="{$staticroot}/js/dagre.min.js"></script>
    <script src="{$staticroot}/js/joint.min.js"></script>
	<!--<script src="{$staticroot}/js/joint.layout.DirectedGraph.min.js"></script>-->
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title">Model</h3>
		</div>
		<div class="panel-body">
			<div id="jointmodel"/>
			<xsl:variable name="nodes">
				<xsl:for-each select="rdf:Description[@rdf:about!='']">
					<node><xsl:value-of select="@rdf:about"/></node>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="cells">
				<!-- Nodes -->
				<xsl:for-each select="rdf:Description">
					<xsl:if test="position()!=1">,</xsl:if>
					<xsl:text>{id:"</xsl:text><xsl:value-of select="@rdf:about"/><xsl:text>"</xsl:text>
					<xsl:text>,type:"basic.Rect"</xsl:text>
					<xsl:text>,position:{x:300,y:300}</xsl:text>
					<xsl:text>,size:{width:100,height:30}</xsl:text>
					<xsl:text>,attrs:{text: {text: "</xsl:text><xsl:value-of select="rdfs:label"/><xsl:text>"}}</xsl:text>
					<xsl:text>}</xsl:text>
				</xsl:for-each>
				<!-- Links -->
				<xsl:for-each select="rdf:Description/*[@rdf:resource!='']">
					<xsl:variable name="target" select="@rdf:resource"/>
					<xsl:if test="exists($nodes/node[.=$target])">
						<xsl:text>,{id:"</xsl:text><xsl:value-of select="../@rdf:about"/><xsl:value-of select="@rdf:resource"/><xsl:text>"</xsl:text>
						<xsl:text>,type:"link"</xsl:text>
						<xsl:text>,source:{id:"</xsl:text><xsl:value-of select="../@rdf:about"/><xsl:text>"}</xsl:text>
						<xsl:text>,target:{id:"</xsl:text><xsl:value-of select="@rdf:resource"/><xsl:text>"}</xsl:text>
						<xsl:text>,labels: [{ position: 0.5, attrs: { text: { text: "label" } } }]</xsl:text>
						<xsl:text>}</xsl:text>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			<script type="text/javascript">

				var graph = new joint.dia.Graph;

				var paper = new joint.dia.Paper({
					el: $('#jointmodel'),
					width: "100%",
					height: 400,
					model: graph,
					gridSize: 1
				});
				
				graph.fromJSON({cells: [<xsl:value-of select="$cells"/>]});
				
				var graphBBox = joint.layout.DirectedGraph.layout(graph, {
					nodeSep: 50,
					edgeSep: 80,
					rankDir: "TB"
				});


			</script>
			<!--
			<script type="text/javascript">

				var graph = new joint.dia.Graph;

				var paper = new joint.dia.Paper({
					el: $('#jointmodel'),
					width: "100%",
					height: 400,
					model: graph,
					gridSize: 1
				});

				var uml = joint.shapes.uml;
				
				var s1 = new uml.State({
					position: { x:100  , y: 100 },
					size: { width: 200, height: 100 },
					name: "state 1",
					events: ["property1","property2"],
					attrs: {
						'.uml-state-body': {
							fill: 'rgba(0, 0, 255, 0.1)',
							stroke: 'rgba(0, 0, 255, 0.5)',
							'stroke-width': 1.5
						},
						'.uml-state-separator': {
							stroke: 'rgba(0, 0, 255, 0.4)'
						}
					}
				});
				
				var bloodgroup = new uml.Class({
					position: { x:20  , y: 190 },
					size: { width: 220, height: 100 },
					name: 'BloodGroup',
					attributes: ['bloodGroup: String'],
					methods: ['+ isCompatible(bG: String): Boolean'],
					attrs: {
						'.uml-class-name-rect': {
							fill: '#ff8450',
							stroke: '#fff',
							'stroke-width': 0.5,
						},
						'.uml-class-attrs-rect, .uml-class-methods-rect': {
							fill: '#fe976a',
							stroke: '#fff',
							'stroke-width': 0.5
						},
						'.uml-class-attrs-text': {
							ref: '.uml-class-attrs-rect',
							'ref-y': 0.5,
							'y-alignment': 'middle'
						},
						'.uml-class-methods-text': {
							ref: '.uml-class-methods-rect',
							'ref-y': 0.5,
							'y-alignment': 'middle'
						}
					}
				});

				var rect = new joint.shapes.basic.Rect({
					position: { x: 100, y: 30 },
					size: { width: 100, height: 30 },
					attrs: { rect: { fill: 'blue' }, text: { text: 'my box', fill: 'white' } }
				});

				var rect2 = rect.clone();
				rect2.translate(300);

				var link = new joint.dia.Link({
					source: { id: rect.id },
					target: { id: rect2.id }
				});

				graph.addCells([rect, rect2, link]);

				graph.addCell(s1);
				
				alert(JSON.stringify(graph.toJSON()));
			</script>
			-->
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>