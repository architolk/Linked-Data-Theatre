/*
 * NAME     linkedmodel.js
 * VERSION  1.19.0
 * DATE     2017-10-16
 *
 * Copyright 2012-2017
 *
 * This file is part of the Linked Data Theatre.
 *
 * The Linked Data Theatre is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Linked Data Theatre is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.
 */
/*
 * DESCRIPTION
 * Javascript to show linked data as a model, using joint.js
 *
 */
//Full screen toggle
var fullScreenFlag = false;
 
function togglefullscreen() {
	if (fullScreenFlag) {
		$('#graphcanvas').css({position:'relative',left:'',top:'',width:'',height:'',zIndex:''});
		d3.select("#jointmodel").select("svg").attr("height",400);
	} else {
		$('#graphcanvas').css({position:'absolute',left:0,top:0,width: $(window).width(), height: $(window).height(), zIndex: 1000});
		d3.select("#jointmodel").select("svg").attr("height",$(window).height()-100);
	}
	fullScreenFlag = !fullScreenFlag;
}

var graph = new joint.dia.Graph;

var paper = new joint.dia.Paper({
	el: $('#jointmodel'),
	width: "100%",
	height: 400,
	model: graph,
	gridSize: 1
});

//Create dragable paper
paper.on('blank:pointerdown',
	function(event, x, y) {
		dragStartPosition = { x: x, y: y};
	}
);
paper.on('cell:pointerup blank:pointerup', function(cellView, x, y) {
	delete dragStartPosition;
});
$("#jointmodel")
	.mousemove(function(event) {
		if (typeof(dragStartPosition) != "undefined")
			paper.setOrigin(
				event.offsetX - dragStartPosition.x, 
				event.offsetY - dragStartPosition.y);
	});

//Set elements
graph.fromJSON(cells);

//Update links
_.each(graph.getLinks(),function(link) {
	if (link.attributes.ldttype==="isa") {
		link.attr({
			".connection": { stroke: '#000000', 'stroke-width': 1 },
			".marker-target": { fill: '#FFFFFF', stroke: '#000000', d: 'M 14 0 L 0 7 L 14 14 z' }
		});
	} else if (link.attributes.ldttype==="role") {
		link.attr({
			".connection": { stroke: '#000000', 'stroke-width': 1, 'stroke-dasharray': '5,5' },
			".marker-target": { fill: '#FFFFFF', stroke: '#000000', d: 'M 14 0 L 0 7 L 14 14 z' }
		});
	} else {
		link.attr({
			".connection": { stroke: '#000000', 'stroke-width': 1 },
			".marker-target": { fill: '#000000', stroke: '#000000', d: 'M 8 0 L 0 4 L 8 8 z' }
		});
		link.label(0,{attrs:{text:{'font-size':12, 'font-weight': 'normal'}}});
	}
});

//Update elements
_.each(graph.getElements(),function(element) {
	element.attr({
		".uml-state-name": {
			'ref': '.uml-state-body', 'ref-x': .5, 'ref-y': 5, 'text-anchor': 'middle',
			'fill': '#000000', 'font-family': 'Arial', 'font-size': 14
		},
		".uml-state-events": {
			'ref': '.uml-state-separator', 'ref-x': 5, 'ref-y': 5,
			'fill': '#000000', 'font-family': 'Arial', 'font-size': 12
		}
	});
	var realWith = paper.findViewByModel(element).getBBox().width+10;
	if (element.attributes.events) {
		element.resize(Math.max(realWith,100),30 + Math.max(element.attributes.events.length*12,10));
	}
});

// Auto-layout
var graphBBox = joint.layout.DirectedGraph.layout(graph, {
	nodeSep: 100,
	edgeSep: 40,
	rankDir: "TB"
});

//Update links so they will not cross a node
_.each(graph.getLinks(),function(link) {paper.findViewByModel(link).update();});

//Create an event if a cell might have been changed. In that case: update links so they will not cross the node in question
paper.on('cell:pointerup', function(cell) {
	_.each(graph.getLinks(),function(link) {paper.findViewByModel(link).update();});
});
