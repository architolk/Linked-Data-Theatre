/*
 * NAME     linkeddatamap.js
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
 * Javascript to show linked data on a map, using leaflet
 *
 */
var map;
var osm = null;
var listOfLocations = [];
var listOfMarkers = [];
var listOfGeoObjects = [];
var lastPolygon;
var containerURL;
var mapChanged = false;
var movedItem;
var subjectURL;
var subjectPolygon = null;

// Resolutions (pixels per meter) of the zoom levels:
var res = [3440.640, 1720.320, 860.160, 430.080, 215.040, 107.520, 53.760, 26.880, 13.440, 6.720, 3.360, 1.680, 0.840, 0.420, 0.210, 0.105];

// Relative sizing of circles
var circleQuotient = 0.7;

// Minimum length of edge (squared value, so 36 actually means a minium value of 6)
var minEdgeLength = 100;

var numberRegexp = /^[-+]?([0-9]*\.[0-9]+|[0-9]+)([eE][-+]?[0-9]+)?/;

 /*
 * Parse WKT and return GeoJSON.
 *
 * @param {string} _ A WKT geometry
 * @return {?Object} A GeoJSON geometry object
 */
function parse(_) {
    var parts = _.split(";"),
        _ = parts.pop(),
        srid = (parts.shift() || "").split("=").pop();

    var i = 0;

    function $(re) {
        var match = _.substring(i).match(re);
        if (!match) return null;
        else {
            i += match[0].length;
            return match[0];
        }
    }

    function crs(obj) {
        if (obj && srid.match(/\d+/)) {
            obj.crs = {
                type: 'name',
                properties: {
                    name: 'urn:ogc:def:crs:EPSG::' + srid
                }
            };
        }

        return obj;
    }

    function white() { $(/^\s*/); }

    function multicoords() {
        white();
        var depth = 0, rings = [], stack = [rings],
            pointer = rings, elem;

        while (elem =
            $(/^(\()/) ||
            $(/^(\))/) ||
            $(/^(\,)/) ||
            $(numberRegexp)) {
            if (elem == '(') {
                stack.push(pointer);
                pointer = [];
                stack[stack.length - 1].push(pointer);
                depth++;
            } else if (elem == ')') {
                pointer = stack.pop();
                // the stack was empty, input was malformed
                if (!pointer) return;
                depth--;
                if (depth === 0) break;
            } else if (elem === ',') {
                pointer = [];
                stack[stack.length - 1].push(pointer);
            } else if (!isNaN(parseFloat(elem))) {
                pointer.push(parseFloat(elem));
            } else {
                return null;
            }
            white();
        }

        if (depth !== 0) return null;
        return rings;
    }

    function coords() {
        var list = [], item, pt;
        while (pt =
            $(numberRegexp) ||
            $(/^(\,)/)) {
            if (pt == ',') {
                list.push(item);
                item = [];
            } else {
                if (!item) item = [];
                item.push(parseFloat(pt));
            }
            white();
        }
        if (item) list.push(item);
        return list.length ? list : null;
    }

    function point() {
        if (!$(/^(point)/i)) return null;
        white();
        if (!$(/^(\()/)) return null;
        var c = coords();
        if (!c) return null;
        white();
        if (!$(/^(\))/)) return null;
        return {
            type: 'Point',
            coordinates: c[0]
        };
    }

	// Added: unsupported in WKT, but pretty handy for leaflet!
	// TODO: Hier nog features bij stoppen, en dan nog call-back functie implementeren!
	function circle() {
        if (!$(/^(circle)/i)) return null;
        white();
        if (!$(/^(\()/)) return null;
        var c = coords();
        if (!c) return null;
        white();
        if (!$(/^(\))/)) return null;
        return {
            type: 'Point',
			radius: circleQuotient*parseFloat(c[1]),
			originalradius: c[1],
            coordinates: c[0]
        };
	}
	
    function multipoint() {
        if (!$(/^(multipoint)/i)) return null;
        white();
        var c = multicoords();
        if (!c) return null;
        white();
        return {
            type: 'MultiPoint',
            coordinates: c
        };
    }

    function multilinestring() {
        if (!$(/^(multilinestring)/i)) return null;
        white();
        var c = multicoords();
        if (!c) return null;
        white();
        return {
            type: 'MultiLineString',
            coordinates: c
        };
    }

    function linestring() {
        if (!$(/^(linestring)/i)) return null;
        white();
        if (!$(/^(\()/)) return null;
        var c = coords();
        if (!c) return null;
        if (!$(/^(\))/)) return null;
        return {
            type: 'LineString',
            coordinates: c
        };
    }

    function polygon() {
        if (!$(/^(polygon)/i)) return null;
        white();
        return {
            type: 'Polygon',
            coordinates: multicoords()
        };
    }

    function multipolygon() {
        if (!$(/^(multipolygon)/i)) return null;
        white();
        return {
            type: 'MultiPolygon',
            coordinates: multicoords()
        };
    }

    function geometrycollection() {
        var geometries = [], geometry;

        if (!$(/^(geometrycollection)/i)) return null;
        white();

        if (!$(/^(\()/)) return null;
        while (geometry = root()) {
            geometries.push(geometry);
            white();
            $(/^(\,)/);
            white();
        }
        if (!$(/^(\))/)) return null;

        return {
            type: 'GeometryCollection',
            geometries: geometries
        };
    }

    function root() {
        return point() ||
            circle() ||
            linestring() ||
            polygon() ||
            multipoint() ||
            multilinestring() ||
            multipolygon() ||
            geometrycollection();
    }

    return crs(root());
}

function style(feature) {

	// Most style element are created by the styleclass. Defaults should not be set by framework
	return {
		weight: 1,
		className: feature.geometry.styleclass
	};
}

function highlightFeature(e) {
	var layer = e.target;
    map.doubleClickZoom.disable();
	map.dragging.disable();
	//Not for markers!
	if (!(layer instanceof L.Marker)) {
		layer.setStyle({
			weight: 5
		});

		if (!L.Browser.ie && !L.Browser.opera) {
			layer.bringToFront();
		}
	}
}

function resetHighlight(e) {
    var layer = e.target;
    map.doubleClickZoom.enable();
	map.dragging.enable();
	//Not for markers!
	if (!(layer instanceof L.Marker)) {
		layer.setStyle({
			weight: 1
		});
	}
}

function circleMoveStart(e) {
	movedItem = e.target;
	//Remove arrowhead (IE Bugfix)
	if (movedItem.edge!=undefined) {
		d3.select(movedItem.edge._path)
			.attr("marker-end","none");
	}
	if (movedItem.redge!=undefined) {
		d3.select(movedItem.redge._path)
			.attr("marker-end","none");
	}
	map.on('mousemove',circleMove);
	map.on('mouseup',circleMoveEnd);
}

function setChangeColors() {
	if (!mapChanged) {
		if (listOfMarkers.length == 0) {
			for(i = 0; i < listOfGeoObjects.length; ++i) {
				var layer = listOfGeoObjects[i].getLayers()[0];
				if (layer.feature.geometry.styleclass!="shidden-object") {
					listOfGeoObjects[i].setStyle({fillColor: '#000000', color: '#000000'});
					//Remove custom classname (hack - leaflet doesn't support this). Classname interfers with change of style
					path = listOfGeoObjects[i].getLayers()[0]._path;
					path.setAttribute("class","leaflet-interactive");
				}
			}
		}
		mapChanged = true;
	}
	if (listOfMarkers.indexOf(movedItem) === -1) { //Niet zo mooi: indexOf kan een dure functie zijn, en deze wordt wel bij elke beweging uitgevoerd!
		movedItem.setStyle({fillColor: '#FF0000', color: '#FF0000'})
		listOfMarkers.push(movedItem);
	}
}

function circleMove(e) {
	movedItem.setLatLng(e.latlng);
	if (movedItem.label) {	
		movedItem.label.setLatLng(movedItem._latlng);
	}
	setChangeColors();
	//Refactoring needed for stuff below
	//Change start position of edge (start is moving)
	if (movedItem.edge!=undefined) {
		var latlngs = Array();
		latlngs.push(e.latlng);
		latlngs.push(movedItem.edge.getLatLngs()[1]);
		movedItem.edge.setLatLngs(latlngs);
	}
	//Change end position of edge (end is moving)
	if (movedItem.redge!=undefined) {
		var latlngs = Array();
		latlngs.push(movedItem.redge.getLatLngs()[0]);
		latlngs.push(e.latlng);
		movedItem.redge.setLatLngs(latlngs);
	}
}
function circleMoveEnd(e) {
	map.removeEventListener('mousemove');
	//Redisplay the arrowheads after zoom
	//We might use this in the future to resize the arrowheads according to the zoomlevel!
	if (movedItem.edge!=undefined) {
		d3.select(movedItem.edge._path)
			.attr("marker-end","url(#ArrowHead)")
		;
	}
	if (movedItem.redge!=undefined) {
		d3.select(movedItem.redge._path)
			.attr("marker-end","url(#ArrowHead)")
		;
	}
}

function onEachFeature(feature, layer) {
    layer.on({
        mouseover: highlightFeature,
        mouseout: resetHighlight,
		mousedown: circleMoveStart
    });
}

function pointToLayer(feature, latlng) {
	if (feature.radius) {
		return L.circleMarker(latlng,{radius: res[0]*feature.radius/res[map.getZoom()]})
	} else {
		return L.marker(latlng);
	}
}

function removeArrowheads(e){
	// Remove arrowheads before zoom (IE has a SVG bug that will separate the arrowhead from the edge!)
	for(i = 0; i < listOfGeoObjects.length; ++i) {
		var layer = listOfGeoObjects[i].getLayers()[0];
		if (layer instanceof L.CircleMarker) {
			if (layer.edge!=undefined) {
				d3.select(layer.edge._path)
					.attr("marker-end","none")
				;
			}
			if (layer.redge!=undefined) {
				d3.select(layer.redge._path)
					.attr("marker-end","none")
				;
			}
		}
	}
}

function resizeCircle(e) {
	for(i = 0; i < listOfGeoObjects.length; ++i) {
		var layer = listOfGeoObjects[i].getLayers()[0];
		if (layer instanceof L.CircleMarker) {
			layer.setStyle({radius: res[0]*layer.feature.geometry.radius/res[map.getZoom()]});
			//Redisplay the arrowheads after zoom
			//We might use this in the future to resize the arrowheads according to the zoomlevel!
			if (layer.edge!=undefined) {
				d3.select(layer.edge._path)
					.attr("marker-end","url(#ArrowHead)")
				;
			}
			if (layer.redge!=undefined) {
				d3.select(layer.redge._path)
					.attr("marker-end","url(#ArrowHead)")
				;
			}
		}
	}
}

function addWKT(uri, wkt, text, url, styleclass) {
	var wktObject = parse(wkt);
	wktObject.url = url;
	wktObject.uri = uri;
	wktObject.styleclass = styleclass
	var html = "";
	if (url!="") {
		html+='<a href="'+url+'">'+text+'</a>';
	} else {
		html+=text;
	}
	lastPolygon = L.geoJson(wktObject,{style: style,onEachFeature: onEachFeature,pointToLayer: pointToLayer}).addTo(map)
						.bindPopup(html);
						
	if (uri === subjectURL) {
		subjectPolygon = lastPolygon;
	}
						
	//TESTTESTTEST
	lastPolygon.uri = uri;
	//TESTTESTTEST
	//Only if bindLabel is available

	//Stukje hieronder plaatst een text svg in de tekst!
	if (lastPolygon.bindLabel2!=undefined) {
		var layer = lastPolygon.getLayers()[0];
		var pos = map.latLngToLayerPoint(layer._latlng);
		var labelPoint = map.layerPointToContainerPoint(pos);
		
		var tsvg = document.createElementNS("http://www.w3.org/2000/svg","text");
		tsvg.setAttribute("x",labelPoint.x);
		tsvg.setAttribute("y",labelPoint.y);
		var thtm = document.createTextNode("test");
		tsvg.appendChild(thtm);
		layer._path.parentNode.appendChild(tsvg);
	}
	
	if (lastPolygon.bindLabel!=undefined) {
		lastPolygon.bindLabel(text,{noHide:true, offset: [0,0]});
		lastPolygon.showLabel();
	}

	//Add to list
	listOfGeoObjects.push(lastPolygon);
}

function addEdge(subject,predicate,object) {
	var latlngs = Array();

	var sSub = listOfGeoObjects.filter(function(obj) {return obj.uri == subject;})[0];
	var sObj = listOfGeoObjects.filter(function(obj) {return obj.uri == object;})[0];
	
	if (sSub!=undefined && sObj!=undefined) {
		latlngs.push(sSub.getLayers()[0].getLatLng());
		latlngs.push(sObj.getLayers()[0].getLatLng());

		//Get edge length
		dx = latlngs[0].lat-latlngs[1].lat;
		dy = latlngs[0].lng-latlngs[1].lng;
		
		//Add edge only if the edge is actually visible (long enough)
		if (dx*dx+dy*dy>minEdgeLength) {
			var polyline = L.polyline(latlngs, {className: 'edgestyle'}).addTo(map);
			d3.select(polyline._path)
				.attr("marker-end","url(#ArrowHead)")
				.attr("stroke","#606060")
			;
			sSub.getLayers()[0].edge = polyline;  //Edge outward
			sObj.getLayers()[0].redge = polyline; //Edge inward
		}
	}

}

function updateMap() {
	updateTTL = "@prefix geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>. ";
	for(i = 0; i < listOfMarkers.length; ++i) {
//		updateTTL += "<" + listOfMarkers[i].feature.geometry.url + '> geo:geometry "CIRCLE(' + listOfMarkers[i].getLatLng().lng + ' ' + listOfMarkers[i].getLatLng().lat + ',' + listOfMarkers[i].feature.geometry.originalradius + ')". ';
		updateTTL += "<" + listOfMarkers[i].feature.geometry.uri + '> geo:geometry "CIRCLE(' + listOfMarkers[i].getLatLng().lng + ' ' + listOfMarkers[i].getLatLng().lat + ',' + listOfMarkers[i].feature.geometry.originalradius + ')". ';
	}
	for(i = 0; i < listOfGeoObjects.length; ++i) {
		layer = listOfGeoObjects[i].getLayers()[0];
		if (layer.feature.geometry.styleclass!="shidden-object") {
			layer._path.setAttribute("class","leaflet-interactive "+layer.feature.geometry.styleclass);
		}
	}
	if (listOfMarkers.length>0) {
		$.post(containerURL, {container: containerURL,content: updateTTL}, function(data) {alert(data.response)},'json');
		
		listOfMarkers = [];
	}
	mapChanged = false;
}

function addPoint(latCor, longCor, text, url, value, iconvalue) {
	//Every location is a marker-object.
	var location = L.marker([latCor, longCor]).addTo(map);
	
	if (iconvalue!="") {
		location.setIcon(L.icon({iconUrl: iconvalue}));
	}

	//TODO: use bindLabel instead of adding the value to the pop
	
	//Eerst stellen we de locatie in waarop de marker moet worden weergegeven, waarbij we hier kiezen voor simpele Latitude/Longitude coördinaten die ook gebruikt worden door GPS.
	//location.setLatLng([latCor, longCor]);
	//Daarna geven we aan welke informatie moet worden weergegeven wanneer de gebruiker op de locatie klikt.
	var html = "";
	if (url!="") {
		html+='<a href="'+url+'">'+text;
		if (value!='') {
			html+=' ('+value+')';
		}
		html+='</a>';
	} else {
		html+=text;
		if (value!='') {
			html+=' ('+value+')';
		}
	}
	location.bindPopup(html);
	
	//Tot slot voegen we de locatie toe aan de te tonen locaties.
	listOfLocations.push(location);
}

function printMap() {
	//Set zoom to level 1: everything should be visible
	map.setZoom(1);
	var img = document.getElementsByClassName("leaflet-image-layer")[0]; //Dit mag beter: er zijn mogelijk meerdere img met deze classname

	//Size of the container should be the size of the image (don't know how to do this :-(
	
	//Zoom should be 1:1
	//Styleclass declarations can not be exported: copy styleclass values to style attributes
	for(i = 0; i < listOfGeoObjects.length; ++i) {
		var pathStyle = getComputedStyle(listOfGeoObjects[i].getLayers()[0]._path);
		listOfGeoObjects[i].setStyle({color: pathStyle.getPropertyValue("stroke"), fillColor: pathStyle.getPropertyValue("fill"), fillOpacity: pathStyle.getPropertyValue("fill-opacity")});
	}
	
	var svg = document.getElementsByTagName("svg")[0]; //Dit mag beter: er zijn mogelijk meerdere svg's!

	var svg_xml = (new XMLSerializer).serializeToString(svg.parentNode);

	var form = document.getElementById("svgform");
	form['data'].value = svg_xml;
	form['type'].value = 'pdf'; //pdf and png are allowed values
	form['dimensions'].value = img._leaflet_pos.x+"|"+img._leaflet_pos.y+"|"+svg._leaflet_pos.x+"|"+svg._leaflet_pos.y+"|"+img.width+"|"+img.height+"|"+svg.width.baseVal.value+"|"+svg.height.baseVal.value;
	form['imgsrc'].value = img.src;
	form.submit();
}

function mapClicked(e) {
	map.clicked = map.clicked + 1;
	// Default leaflet gedrag omzeilen (dblclick vuurt ook een click event af). 
	setTimeout(function(){
		if (map.clicked == 1) {
			var form = document.getElementById("clickform");
			form['lat'].value = e.latlng.lat;
			form['long'].value = e.latlng.lng;
			form['zoom'].value = map.getZoom();
			form.submit();
		} 
	}, 300);
}

function mapDblClicked(e) {
	map.clicked = 0;
}

function initMap(staticroot, startZoom, latCor, longCor, baseLayer, imageMapURL, contURL, left, top, width, height, psubjectURL) {
	//Setter
	subjectURL = psubjectURL;
	
	// Pad naar de icons goedmaken
	L.Icon.Default.imagePath = staticroot + '/images/';

	if (baseLayer === 'image') {
		// create the slippy map
		map = L.map('map', {
		  minZoom: 1,
		  maxZoom: 4,
		  center: [width/2,0],
		  zoom: 2,
		  crs: L.CRS.Simple
		});
		
		// calculate the edges of the image, in coordinate space
		var southWest = map.unproject([left, height+top], map.getMaxZoom()-1);
		var northEast = map.unproject([width+left, top], map.getMaxZoom()-1);
		var bounds = new L.LatLngBounds(southWest, northEast);

		// add the image overlay, 
		// so that it covers the entire map
		osm = new L.imageOverlay(imageMapURL, bounds);
		map.addLayer(osm);

		// tell leaflet that the map is exactly as big as the image
		map.setMaxBounds(bounds);
		
		// Add print-button
		L.easyButton( '<span class="print"><b>P</b></span>', printMap).addTo(map);
		
		// Add save-button
		if (contURL !== '') {
			containerURL = contURL;
			L.easyButton( '<span class="save"><b>S</b></span>', updateMap).addTo(map);
		}
	}
	else {
		overlay = null;
		if (baseLayer === 'brt') {
			//Use BRT tiles
			//RD Projectie
			var RD = new L.Proj.CRS( 'EPSG:28992','+proj=sterea +lat_0=52.15616055555555 +lon_0=5.38763888888889 +k=0.9999079 +x_0=155000 +y_0=463000 +ellps=bessel +units=m +towgs84=565.2369,50.0087,465.658,-0.406857330322398,0.350732676542563,-1.8703473836068,4.0812 +no_defs',
				{
					resolutions: res,
					bounds: L.bounds([-285401.92, 22598.08], [595401.9199999999, 903401.9199999999]),
					origin: [-285401.92, 22598.08]
				}
			);
			map = L.map('map',{crs: RD, maxZoom: 14});
			osm = new L.TileLayer('http://geodata.nationaalgeoregister.nl/tms/1.0.0/brtachtergrondkaart/{z}/{x}/{y}.png', {minZoom: 1, maxZoom: 16, tms: true, continuousWorld: true});
		} else if (baseLayer=='brk') {
			//Use BRK tiles
			//RD Projectie
			var RD = new L.Proj.CRS( 'EPSG:28992','+proj=sterea +lat_0=52.15616055555555 +lon_0=5.38763888888889 +k=0.9999079 +x_0=155000 +y_0=463000 +ellps=bessel +units=m +towgs84=565.2369,50.0087,465.658,-0.406857330322398,0.350732676542563,-1.8703473836068,4.0812 +no_defs',
				{
					resolutions: res,
					bounds: L.bounds([-285401.92, 22598.08], [595401.9199999999, 903401.9199999999]),
					origin: [-285401.92, 22598.08]
				}
			);
			map = L.map('map',{crs: RD, maxZoom: 13});
			osm = new L.TileLayer('http://geodata.nationaalgeoregister.nl/tms/1.0.0/brtachtergrondkaart/{z}/{x}/{y}.png', {minZoom: 1, maxZoom: 13, tms: true, continuousWorld: true});
			overlay = new L.tileLayer.wms('https://geodata.nationaalgeoregister.nl/kadastralekaartv2/wms', {layers: 'perceel,perceelnummer',format: 'image/png',transparent: true});
		} else if (baseLayer=='bgt') {
			//Use BRK tiles
			//RD Projectie
			var RD = new L.Proj.CRS( 'EPSG:28992','+proj=sterea +lat_0=52.15616055555555 +lon_0=5.38763888888889 +k=0.9999079 +x_0=155000 +y_0=463000 +ellps=bessel +units=m +towgs84=565.2369,50.0087,465.658,-0.406857330322398,0.350732676542563,-1.8703473836068,4.0812 +no_defs',
				{
					resolutions: res,
					bounds: L.bounds([-285401.92, 22598.08], [595401.9199999999, 903401.9199999999]),
					origin: [-285401.92, 22598.08]
				}
			);
			map = L.map('map',{crs: RD, minZoom: 12, maxZoom: 15});
			osm = new L.TileLayer.WMTS( "http://geodata.nationaalgeoregister.nl/tiles/service/wmts" ,
                               {
                                   layer: "bgtpastel",
                                   style: "_null",
                                   tilematrixSet: "EPSG:28992:16",
                                   format: "image/png"
                               }
                              );
		} else if (baseLayer=='none') {
			map = L.map('map');
		} else {
			//Use OpenStreetMap tiles
			map = L.map('map');
			osm = new L.TileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {minZoom: 1, maxZoom: 18});
		}
		

		//We initialiseren de kaart met een set van coördinaten waarbij we hier kiezen voor simpele Latitude/Longitude coördinaten die ook gebruikt worden door GPS. De derde parameter is het standaard zoom-niveau van de kaart. Bij zoomen geldt: hoe hoger, hoe dichter bij.
		map.setView(new L.LatLng(latCor, longCor), startZoom);

		//Add tile layer to map
		if (osm) {
			map.addLayer(osm);
			if (overlay) map.addLayer(overlay);
		}
	}
	
	//Events
	map.on('dblclick', mapDblClicked);
	//Zoom and pan option for circlemarkers
	//A bug in IE forces us to redraw any arrowheads
	map.on('zoomstart',removeArrowheads);
	map.on('zoomend',resizeCircle);
	map.on('movestart',removeArrowheads);
	map.on('moveend',resizeCircle);
	map.invalidateSize();
}

function addOverlay(serviceSpec, layersSpec, transparantSpec) {
	if (transparantSpec) {
		map.addLayer(L.tileLayer.wms(serviceSpec, {layers: layersSpec,format: 'image/png',transparent: true}));
	} else {
		map.addLayer(L.tileLayer.wms(serviceSpec, {layers: layersSpec,format: 'image/jpeg',transparent: false}));
	}
}

function showLocations(doZoom, appearance) {
	d3.select(map.getPanes().overlayPane).selectAll("g").append('marker')
	.attr('id'          , 'ArrowHead')
	.attr('viewBox'     , '0 -5 10 10')
	.attr('refX'        , 10)
	.attr('refY'        , 0)
	.attr('markerWidth' , 6)
	.attr('markerHeight', 6)
	.attr('orient'      , 'auto')
	.attr('stroke'		, '#909090')
	.attr('fill'		, 'none')
	.attr('stroke-width', '2px')
  .append('path')
	.attr('d', 'M0,-5L10,0L0,5');
	
	if (listOfGeoObjects.length!=0) {
		var firstPolygon = subjectPolygon;
		if (!firstPolygon) {
			firstPolygon = listOfGeoObjects[0];
		}
		if (doZoom==1 && (firstPolygon) && !(firstPolygon.getLayers()[0] instanceof L.CircleMarker)) {
			map.fitBounds(firstPolygon.getBounds());
		}
	}

	//No locations, show crosshair and register event
	if (!(lastPolygon) || appearance=='GeoSelectAppearance') {
		map.clicked = 0;
		map.on('click',mapClicked);
		document.getElementById('map').style.cursor = 'crosshair';
	}
}