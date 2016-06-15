/*
 * NAME     d3graphs-inner.js
 * VERSION  1.8.0
 * DATE     2016-06-15
 *
 * Copyright 2012-2016
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
 * Javascript to generate graphical representation of a rdf graph, using d3.js
 *
 */
var width = $("#graph").width(),
    height = 500;//$("#graph").height(),
	aspect = height/width;

// zoom features
var zoom = d3.behavior.zoom()
	.scaleExtent([0.1,10])
	.on("zoom",zoomed);

// svg graph on the body
var svg = d3.select("#graph").append("svg")
    .attr("width", "100%")
    .attr("height", "500")
	.attr("overflow", "hidden")
	.append("g")
		.call(zoom)
		.on("dblclick.zoom",null);

// detailbox div
var detailBox = d3.select("#graphtitle");
	
//Rectangle area for panning		
var rect = svg.append("rect")
    .attr("width", "100%")
    .attr("height", "100%")
	.attr("class","canvas");
 
//Container that holds all the graphical elements
var container = svg.append("g");

//Arrowhead definition
//(All other endpoints should be defined in this section)
container.append('defs').selectAll('marker')
        .data(['end'])
      .enter().append('marker')
        .attr('id'          , 'ArrowHead')
        .attr('viewBox'     , '0 -5 10 10')
        .attr('refX'        , 10)
        .attr('refY'        , 0)
        .attr('markerWidth' , 6)
        .attr('markerHeight', 6)
        .attr('orient'      , 'auto')
      .append('path')
        .attr('d', 'M0,-5L10,0L0,5');

//Force definition
var force = d3.layout.force()
    .gravity(0)
    .distance(150)
    .charge(-200)
    .size([width, height])
	.on("tick",tick);

//Initialising selection of graphical elements
//allLinks = all the current links
//allNodes = all the current nodes
var allLinks = container.selectAll(".link"),
	allNodes = container.selectAll(".node")
	nodeMap = {},
	linkMap = {},
	currentNode = null;

d3.json(jsonApiCall+jsonApiSubject, function(error, json) {

	//Links aanpassen: @id bevat de werkelijke identificatie die in source en target wordt gebruikt
	//Issue: link with the same source and target, but a different label, those links are placed on top of each other
	json.nodes.forEach(function(x) { nodeMap[x['@id']] = x; });
	json.links = json.links.map(function(x) {
		linkMap[x.source+x.target]=x;
		return {source: nodeMap[x.source], target: nodeMap[x.target], label: x.label, uri: x.uri};
    });
	
	//Eerste node in het midden plaatsen en vastzetten
	json.nodes[0].x = width/2;
	json.nodes[0].y = height/2;
	json.nodes[0].fixed = true;
	json.nodes[0].expanded = true;
	updateTitle(json.nodes[0]);
	
	force
		.nodes(json.nodes)
		.links(json.links);

	update();

});

var node_drag = d3.behavior.drag()
	.on("dragstart", dragstart)
	.on("drag", dragmove)
	.on("dragend", dragend);

function updateTitle(d) {
	/*
	var html = '<div class="header">'+d.label+'</div><table><tr><td>URI</td><td class="data">'+d['@id']+"</td></tr>";
	for (var key in d.data) {
		html += '<tr><td>'+key+'</td><td class="data">'+d.data[key]+"</td></tr>";
	}
	html += '</table><div class="button"><p id="expand" onclick="expand();">Uitbreiden</p></div>';
	*/
	var html = '<h3 class="panel-title"><a style="font-size:16px" href="'+uriEndpoint+encodeURIComponent(d['@id'])+'"><span class="glyphicon glyphicon-new-window"/></a> '+d.label;
	if (!d.expanded) {
		html+=' <a onclick="expand();" class="badge" style="font-size:12px">';
		if (d.data['count']) {
			html+=d.data['count']
		};
		html+='<span class="glyphicon glyphicon-zoom-in"/></a>';
	}
	html+='</h3>';
	detailBox.html(html);
}
	
function dragstart(d) {
	d3.event.sourceEvent.stopPropagation();
	force.stop();
	currentNode = d;
	updateTitle(d);
}
function dragmove(d) {
	d.px += d3.event.dx;
	d.py += d3.event.dy;
	d.x += d3.event.dx;
	d.y += d3.event.dy;
	tick();
}
function dragend(d) {
	d.fixed = true;
	tick();
	force.resume();
}
	
function zoomed() {
	container.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
}
	
function update() {

	allLinks = container.selectAll(".link").data(force.links());
	//Create a new selection of all the newLinks, only those links should be created as new graphical elements
	var newLinks = allLinks
		.enter().append("g")
		.attr("class", function(d) { return "link"+(d.source.class ? " t"+d.source.class : "")+(d.target.class ? " t"+d.target.class : "") });

	newLinks.append("line")
		.attr("class","border")
	newLinks.append("line")
		.style("stroke", "#696969")
		.style("stroke-width", "1px")
		.style("marker-end", "url(#ArrowHead)")
		.attr("class","stroke");
	newLinks.append("text")
		.attr("dx", 0)
		.attr("dy", 0)
		.attr("text-anchor", "middle")
		.style("font", "10px sans-serif")
		.text(function(d) { return d.label });
		
	allNodes = container.selectAll(".node").data(force.nodes());
	//Create a new selection of all the newNodes, only those nodes should be created as new graphical elements
	var newNodes = allNodes
		.enter().append("g")
		.attr("class", function(d) { return (d.class ? "node t"+d.class : "node")})
		.call(node_drag);

	newNodes.append("text")
		.attr("dx", 0)
		.attr("dy", 0)
		.attr("text-anchor", "middle")
		.style("font", "10px sans-serif")
		.text(function(d) { return d.label })
		.each(function(d) {
			d.rect = this.getBBox();
		});

	newNodes.append("rect")
		.attr("x", function(d) { return d.rect.x-5})
		.attr("y", function(d) { return d.rect.y-5})
		.attr("width", function(d) { return d.rect.width+10 })
		.attr("height", function(d) { return d.rect.height+10 })
		.attr("class", function(d) { return (d.class ? "s"+d.class : "default") })
	
	force.start();

}

function togglenode(show,nodeclass) {
	var selectednodes = container.selectAll(".t"+nodeclass)
	selectednodes.style("visibility",show ? "visible" : "hidden");
}
	  
function tick(e) {
	//Extra: Calculate change
	if (typeof e != "undefined") {
		var k = 6 * e.alpha;
	}
	allLinks.each(function(d) {
		//Extra: to form a kind of tree
		if (typeof e != "undefined") {
			d.source.y += k;
			d.target.y -= k;
		}
	
		//Calculating the edge of the rectangle
		//+1 to avoid divide by zero
		var dx = Math.abs(d.target.x - d.source.x)+1,
			dy = Math.abs(d.target.y - d.source.y)+1,
			ddx = d.target.x < d.source.x ? dx : -dx,
			ddy = d.target.y < d.source.y ? dy : -dy,
			xt = d.target.x+(d.source.x < d.target.x ? Math.max(d.target.rect.x-5,(d.target.rect.y-5)*dx/dy) : Math.min(d.target.rect.x-5+d.target.rect.width+10,-(d.target.rect.y-5)*dx/dy)),
			yt = d.target.y+(d.source.y < d.target.y ? Math.max(d.target.rect.y-5,(d.target.rect.x-5)*dy/dx) : Math.min(d.target.rect.y-5+d.target.rect.height+10,-(d.target.rect.x-5)*dy/dx)),
			xs = d.source.x+(d.target.x < d.source.x ? Math.max(d.source.rect.x-5,(d.source.rect.y-5)*dx/dy) : Math.min(d.source.rect.x-5+d.source.rect.width+10,-(d.source.rect.y-5)*dx/dy)),
			ys = d.source.y+(d.target.y < d.source.y ? Math.max(d.source.rect.y-5,(d.source.rect.x-5)*dy/dx) : Math.min(d.source.rect.y-5+d.source.rect.height+10,-(d.source.rect.x-5)*dy/dx));
			
		//Change the position of the lines, to match the border of the rectangle instead of the centre of the rectangle
		d3.select(this).selectAll("line")
			.attr("x1",xs)
			.attr("y1",ys)
			.attr("x2",xt)
			.attr("y2",yt);
			
		//Rotate the text to match the angle of the lines
		var tx = xs+(xt-xs)/2,
			ty = ys+(yt-ys)/2;
		d3.select(this).selectAll("text")
			.attr("x",tx)
			.attr("y",ty-3)
			.attr("transform","rotate("+Math.atan(ddy/ddx)*57+" "+tx+" "+ty+")")
	})

    allNodes.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

	// Onderstaande werkt wel om de rectangle groter te maken, maar je zou em ook weer kleiner moeten maken!
	// Bovendien werkt het niet meer als je panning hebt toegepast: oplossing gaan we dus anders doen (vandaar commented)
	// var maxwidth = 0;
	// allNodes.each(function(d) {
	// 	if (d.x > maxwidth) {
	// 		maxwidth = d.x;
	// 	}
	// })
	// rect.attr("width",maxwidth+100);
}

function expand() {
	if (currentNode) {
		dblclick(currentNode)
	}
}

function dblclick(d) {
	// d3.select(this).select("rect").style("fill","red");
	// Fixed position of a node can be relaxed after a user doubleclicks AND the node has been expanded
	d.fixed = d.expanded ? !d.fixed : d.fixed;

	//Only query if the nodes hasn't been expanded yet
	if (!d.expanded) {
		d3.json(jsonApiCall+encodeURIComponent(d['@id']), function(error, json) {
			//Only add new nodes
			json.nodes.forEach(function(x) {
				if (!nodeMap[x['@id']]) {
					force.nodes().push(x);
					nodeMap[x['@id']] = x;
					// startingpoint of new nodes = position starting node
					x.x = d.x;
					x.y = d.y;
				}
			})
			//Only add new lines
			//Issue: link with the same source and target, but a different label, those links are not added
			json.links.forEach(function(x) {
				if (!linkMap[x.source+x.target]) {
					force.links().push({source:nodeMap[x.source],target:nodeMap[x.target],label:x.label,uri:x.uri});
					linkMap[x.source+x.target] = x;
				}
			})
			
			d.expanded = true;
			updateTitle(d);
			update();
		})
	}
}
