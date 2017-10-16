/*
 * NAME     d3graphs-inner.js
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
 * Javascript to generate graphical representation of a rdf graph, using d3.js
 *
 */
var width = $("#graph").width(),
    height = 500;//$("#graph").height(),
	aspect = height/width;

//Maximum number of nodes allowed before links and nodes are aggregated
var maxNodes = 4;

//Full screen toggle
var fullScreenFlag = false;

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

// propertybox div
var pt = document.getElementsByTagName('svg')[0].createSVGPoint();
var propertyBox = d3.select("#propertybox");
var infoBox = propertyBox.append("div");
infoBox.attr("class","infobox");
var propertyNode = null;
var infoNode = null;
var propertyBoxVisible = false;

//Rectangle area for panning
var rect = svg.append("rect")
    .attr("width", "100%")
    .attr("height", "100%")
	.attr("class","canvas");

//Container that holds all the graphical elements
var container = svg.append("g");

//Flag for IE10 and IE11 bug: SVG edges are not showing when redrawn
var bugIE = ((navigator.appVersion.indexOf("rv:11")!=-1) || (navigator.appVersion.indexOf("MSIE 10")!=-1));

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
//allLinks = all the current visible links
//allNodes = all the current visible nodes
//AllNodes and AllLinks are used within the tick function
//root holds all data, even data that has been made invisible
var allLinks = container.selectAll(".link"),
	allNodes = container.selectAll(".node"),
	nodeMap = {},
	linkMap = {},
	root = {},
	currentNode = null;

//Fetch data via Ajax-call and process
d3.json(jsonApiCall+encodeURIComponent(jsonApiSubject), function(error, json) {

	root.nodes = json.nodes;
	//Update nodes: the original data contains nodes with an uri-reference to the node, not the node itself (@id holds the uri-reference)
	root.nodes.forEach(function(x) { nodeMap[x['@id']] = x; });

	//Update links
	root.links = [];
	json.links.forEach(function(x) {
		if (linkMap[x.source+x.target]) {
			//Link already exists, add label to existing link
			linkMap[x.source+x.target].label = linkMap[x.source+x.target].label+", "+x.label
		} else {
			//New link
			var l = {id:x.source+x.target, source: nodeMap[x.source], target: nodeMap[x.target], label: x.label, uri: x.uri}
			linkMap[x.source+x.target]=l;
			root.links.push(l);
		}
	});

	//Place first node in the center and set to fixed
	root.nodes[0].x = width/2;
	root.nodes[0].y = height/2;
	root.nodes[0].fixed = true;
	root.nodes[0].expanded = true;
	updateTitle(root.nodes[0]);

	//Create network
	root.nodes.forEach(function(n) {
		n.inLinks = {};
		n.outLinks = {};
		n.linkCount = 0;
		n.parentLink;
		n.elementType = "rect"; //Maybe not the best place...
	});
	root.links.forEach(function(l) {
		l.source.outLinks[l.uri] = l.source.outLinks[l.uri] || [];
		l.source.outLinks[l.uri].push(l);
		l.source.linkCount++;
		l.source.parentLink = l;
		l.target.inLinks[l.uri] = l.target.inLinks[l.uri] || [];
		l.target.inLinks[l.uri].push(l);
		l.target.linkCount++;
		l.target.parentLink = l;
	});

	createAggregateNodes();
	update();

});

function movePropertyBox() {
	if (propertyBoxVisible && propertyNode) {
		if (propertyNode.arect) {
			propertyBox.style("display","block");
			//Get absolute position
			var matrix  = propertyNode.arect.getScreenCTM();
			if (propertyNode.arect.nodeName==='rect') {
				pt.x = propertyNode.arect.x.animVal.value+propertyNode.arect.width.animVal.value;
				pt.y = propertyNode.arect.y.animVal.value;
			}
			if (propertyNode.arect.nodeName==='circle') {
				pt.x = propertyNode.arect.cx.animVal.value+propertyNode.arect.r.animVal.value;
				pt.y = propertyNode.arect.cy.animVal.value-propertyNode.arect.r.animVal.value;
			}
			var divrect = pt.matrixTransform(matrix);
			//Correct for offset and scroll
			var theX = divrect.x-$('#graphcanvas').offset().left+$(window).scrollLeft();
			var theY = divrect.y-$('#graphcanvas').offset().top+$(window).scrollTop();
			//Set position
			propertyBox.style("left",theX+"px");
			propertyBox.style("top",theY+"px");
		}
	}
}

function mouseoverNode(d) {
	if (!propertyBoxVisible) {
		propertyNode = d;
		propertyBoxVisible = true;
		movePropertyBox();
		if (infoNode!=propertyNode) {
			var html='';
			infoBox.html(html);
		}
	}
}

function mouseoutNode(d) {
	if (propertyBoxVisible) {
		propertyBoxVisible = false;
		propertyBox.style("display","none");
		if (infoNode!=propertyNode) {
			var html='';
			infoBox.html(html);
		}
	}
}

function mouseoverPropertyBox() {
	if (!propertyBoxVisible) {
		propertyBox.style("display","block");
		propertyBoxVisible = true;
	}
}

function mouseoutPropertyBox() {
	propertyBox.style("display","none");
	propertyBoxVisible = false;
	if (infoNode!=propertyNode) {
		var html='';
		infoBox.html(html);
	}
}

function createAggregateNodes() {

	//Add an aggregateNode for any node that has more than maxNodes outgoing OR ingoing links
	root.nodes.forEach(function(n) {
		if (!n.aggregateNode) {
			Object.getOwnPropertyNames(n.outLinks).forEach(function(prop) {
				var d = n.outLinks[prop];
				if (d.length>=maxNodes) {
					if (!nodeMap[n["@id"]+d[0].uri]) {
						var aNode = {"@id":n["@id"]+d[0].uri,data:{},label:d[0].label,uri:d[0].uri,elementType:"circle",aggregateNode:true,inbound:false,count:d.length,links:d};
						root.nodes.push(aNode);
						root.links.push({id:n["@id"]+d[0].uri,source:n,target:aNode,label:d[0].label,uri:d[0].uri});
						nodeMap[aNode["@id"]]=aNode;
					}
				}
			});
			Object.getOwnPropertyNames(n.inLinks).forEach(function(prop) {
				var d = n.inLinks[prop];
				if (d.length>=maxNodes) {
					if (!nodeMap[n["@id"]+d[0].uri]) {
						var aNode = {"@id":n["@id"]+d[0].uri,data:{},label:d[0].label,uri:d[0].uri,elementType:"circle",aggregateNode:true,inbound:true,count:d.length,links:d};
						root.nodes.push(aNode);
						root.links.push({id:n["@id"]+d[0].uri,source:aNode,target:n,label:d[0].label,uri:d[0].uri});
						nodeMap[aNode["@id"]]=aNode;
					}
				}
			});
		}
	});
	//Do a recount of number of connections
	//(count is number of connections minus the connections that remain visible
	root.nodes.forEach(function(n) {
		if (n.aggregateNode) {
			n.count = n.links.filter(function(d) {return ((d.target.linkCount<=1) || (d.source.linkCount<=1))}).length;
		}
	});
}

var node_drag = d3.behavior.drag()
	.on("dragstart", dragstart)
	.on("drag", dragmove)
	.on("dragend", dragend);

function updateTitle(d) {
	var html = '<h3 class="panel-title"><a style="font-size:16px" href="'+uriEndpoint+encodeURIComponent(d['@id'])+'"><span class="glyphicon glyphicon-new-window"/></a> '+d.label;
	if (!d.expanded) {
		html+=' <a onclick="expand();" class="badge" style="font-size:12px">';
		if (d.data['count']) {
			html+=d.data['count']
		};
		html+='<span class="glyphicon glyphicon-zoom-in"/></a>';
	}
	html+='<span class="glyphicon glyphicon-fullscreen" style="position:absolute;right:10px;margin-top:10px;cursor:pointer" onclick="togglefullscreen()"/>';
	html+='</h3>';
	detailBox.html(html);
}

function togglefullscreen() {
	if (fullScreenFlag) {
		$('#graphcanvas').css({position:'relative',left:'',top:'',width:'',height:'',zIndex:''});
		//d3.select('#graphcanvas').setAttribute("style","relative");
	} else {
		$('#graphcanvas').css({position:'absolute',left:0,top:0,width: $(window).width(), height: $(window).height(), zIndex: 1000});
		//d3.select('#graphcanvas').setAttribute("style","position:absolute;left:0;top:0;width:100%;height:100%");
		d3.select("#graph").select("svg").attr("height",$(window).height()-100);
	}
	fullScreenFlag = !fullScreenFlag;
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

	//Keep only the visible nodes
	var nodes = root.nodes.filter(function(d) {
		return d.aggregateNode ? (!d.expanded) && (d.count>0) : ((d.linkCount>1) || ((d.parentLink.source.outLinks[d.parentLink.uri].length < maxNodes) && (d.parentLink.target.inLinks[d.parentLink.uri].length < maxNodes)))
	});
	var links = root.links;
	//Keep only the visible links
	links = root.links.filter(function(d) {
		return d.source.aggregateNode ? (!d.source.expanded) && (d.source.count>0) : d.target.aggregateNode ? (!d.target.expanded) && (d.target.count>0) : (((d.source.linkCount>1) && (d.target.linkCount>1)) || ((d.source.outLinks[d.uri].length < maxNodes) && (d.target.inLinks[d.uri].length < maxNodes)))
	});

	// Update the links
	allLinks = allLinks.data(links,function(d) {return d.id});

	// Exit any old links.
	allLinks.exit().remove();

	// Enter any new links.
	var newLinks = allLinks
		.enter().append("g")
		.attr("class", function(d) { return "link"+(d.source["class"] ? " t"+d.source["class"] : "")+(d.target["class"] ? " t"+d.target["class"] : "") });

	newLinks.append("line")
		.attr("class","border")
	newLinks.append("line")
		.style("marker-end", "url(#ArrowHead)")
		.attr("class","stroke");
	newLinks.append("text")
		.attr("dx", 0)
		.attr("dy", 0)
		.attr("text-anchor", "middle")
		.attr("class","stroke-text")
		.text(function(d) { return d.label });

	// Update the nodes
	allNodes = allNodes.data(nodes,function(d) {return d["@id"]});

	// Update text (count of an aggregateNode might change)
	allNodes.select("text").text(function(d) { return d.aggregateNode ? d.count : d.label });

	// Exit any old nodes.
	allNodes.exit().remove();

	// Enter any new nodes.
	var newNodes = allNodes
		.enter().append("g")
		.attr("class", function(d) { return (d["class"] ? "node t"+d["class"] : "node")})
		.on("mouseover",mouseoverNode)
		.on("mouseout",mouseoutNode)
		.call(node_drag);


	newNodes.append("text")
		.attr("dx", 0)
		.attr("dy", 0)
		.attr("text-anchor", "middle")
		.attr("class","node-text")
		.text(function(d) { return d.aggregateNode ? d.count : d.label })
		.each(function(d) {d.rect = this.getBBox();	});

	newNodes.filter(function(d) {return d.elementType==="rect"}).append("rect")
		.attr("x", function(d) { return d.rect.x-5})
		.attr("y", function(d) { return d.rect.y-5})
		.attr("width", function(d) { return d.rect.width+10 })
		.attr("height", function(d) { return d.rect.height+10 })
		.attr("class", function(d) { return (d["class"] ? "s"+d["class"] : "default") })
		.each(function(d) {d.arect = this;});

	newNodes.filter(function(d) {return d.elementType==="circle"}).append("circle")
		.attr("cx", function(d) { return d.rect.x+5})
		.attr("cy", function(d) { return d.rect.y+5})
		.attr("r", function(d) { return 5+d.rect.height/2 })
		.attr("class", function(d) { return (d["class"] ? "s"+d["class"] : "default") })
		.each(function(d) {d.arect = this;});

	force
		.nodes(nodes)
		.links(links)
		.start();

}

function togglenode(show,nodeclass) {
	var selectednodes = container.selectAll(".t"+nodeclass)
	selectednodes.style("visibility",show ? "visible" : "hidden");
}

function clickPropertyBox() {
	if (propertyNode) {
		dblclick(propertyNode);
	}
}

function expandOneItem(id) {
	var selected = nodeMap[id];
	if (selected) {
		selected.linkCount++;
	}
	if (propertyNode) {
		if (propertyNode.aggregateNode) {
			propertyNode.count-=1;
			clickInfoBox();
		}
	}
	update();
}

function clickInfoBox() {
	if (propertyNode) {
		infoNode = propertyNode;
		if (propertyNode.aggregateNode) {
			var html= '<table style="background-color:#F0F0F0;">';
			propertyNode.links.forEach(function(x) {
				if (propertyNode.inbound) {
					if (x.source.linkCount<=1) { //Hack: linkCount is misused to show nodes from aggregation!
						html += '<tr><td><a onclick="expandOneItem(this.href);return false;" href="' + x.source['@id'] + '">' + x.source.label + '</a></td></tr>';
					}
				} else {
					if (x.target.linkCount<=1) { //Hack: linkCount is misused to show nodes from aggregation!
						html += '<tr><td><a onclick="expandOneItem(this.href);return false;" href="' + x.target['@id'] + '">' + x.target.label + '</a></td></tr>';
					}
				}
			});
			html += "</table>";
			infoBox.html(html);
		} else {
			var html = '<table>';
			for (var key in propertyNode.data) {
				html += '<tr><td>'+key+'</td><td class="data">'+propertyNode.data[key]+"</td></tr>";
			}
			html += "</table>";
			infoBox.html(html);
		}
	}
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

			if (d.target.elementType==="circle") {
				var pl = Math.sqrt((ddx*ddx)+(ddy*ddy)),
					rad = 5+d.target.rect.height/2;
				xt = d.target.x+((ddx*rad)/pl)+2;
				yt = d.target.y+((ddy*rad)/pl)-5;
			}
			if (d.source.elementType==="circle") {
				var pl = Math.sqrt((ddx*ddx)+(ddy*ddy)),
					rad = 5+d.source.rect.height/2;
				xs = d.source.x-((ddx*rad)/pl);
				ys = d.source.y-((ddy*rad)/pl)-5;
			}

		//Change the position of the lines, to match the border of the rectangle instead of the centre of the rectangle
		d3.select(this).selectAll("line")
			.attr("x1",xs)
			.attr("y1",ys)
			.attr("x2",xt)
			.attr("y2",yt);

		//Rotate the text to match the angle of the lines
		var tx = xs+(xt-xs)*2/3, //set label at 2/3 of edge (to solve situation with overlapping edges)
			ty = ys+(yt-ys)*2/3;
		d3.select(this).selectAll("text")
			.attr("x",tx)
			.attr("y",ty-3)
			.attr("transform","rotate("+Math.atan(ddy/ddx)*57+" "+tx+" "+ty+")");

		//IE10 and IE11 bugfix
		if (bugIE) {
			this.parentNode.insertBefore(this,this);
		}
	})

    allNodes.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });
	movePropertyBox();

}

function expand() {
	if (currentNode) {
		dblclick(currentNode)
	}
}

function dblclick(d) {
	// Fixed position of a node can be relaxed after a user doubleclicks AND the node has been expanded
	d.fixed = d.expanded ? !d.fixed : d.fixed;

	//Check for aggregate node
	if (!d.aggregateNode) {
		//Only query if the nodes hasn't been expanded yet
		if (!d.expanded) {
			//Fetch new data via Ajax call
			d3.json(jsonApiCall+encodeURIComponent(d['@id']), function(error, json) {
				//Only add new nodes
				var newNodes = json.nodes.filter(function(x) {return !nodeMap[x['@id']]});
				newNodes.forEach(function(x) {
					//force.nodes().push(x); OLD
					root.nodes.push(x); //NEW
					nodeMap[x['@id']] = x;
					// startingpoint of new nodes = position starting node
					x.x = d.x;
					x.y = d.y;
					//Create network: initialize new node
					x.inLinks = {};
					x.outLinks = {};
					x.linkCount = 0;
					x.parentLink;
					x.elementType = "rect";
				})
				//Only add new lines
				json.links.forEach(function(x) {
					if (linkMap[x.source+x.target]) {
						//Existing link, check if uri is different and label is different, add label to existing link
						var el = linkMap[x.source+x.target];
						if ((el.uri!=x.uri) && (el.label!=x.label)) {
							el.label = el.label + ", " + x.label;
						}
					} else {
						var l = {id:x.source+x.target,source:nodeMap[x.source],target:nodeMap[x.target],label:x.label,uri:x.uri};
						root.links.push(l);
						linkMap[x.source+x.target] = l;
						//Create network: set in & out-links
						l.source.outLinks[l.uri] = l.source.outLinks[l.uri] || [];
						l.source.outLinks[l.uri].push(l);
						l.source.linkCount++;
						l.source.parentLink = l;
						l.target.inLinks[l.uri] = l.target.inLinks[l.uri] || [];
						l.target.inLinks[l.uri].push(l);
						l.target.linkCount++;
						l.target.parentLink = l;
					}
				})

				d.expanded = true;
				updateTitle(d);
				createAggregateNodes();
				update();
			})
		}
	} else {
		//TODO: Uncollapse aggregate
		d.expanded = true;
		//A bit dirty: make sure that the new nodes are visible
		d.links.forEach(function(x) {
			x.target.linkCount++;
			x.source.linkCount++;
		});
		update();
	}
}
