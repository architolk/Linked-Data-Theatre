<!--

    NAME     CesiumAppearance.xsl
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
	CesiumAppearance, add-on of rdf2html.xsl
	
	Cesium is an appearance that shows a 3D representation of a KML object
	
	TODO: CesiumAppearance is still a prototype: needs more development
	TODO: Including a <style> element within a <div> is not compliant to html5: this has to change
	
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

<xsl:template match="rdf:RDF" mode="CesiumAppearance">
  <script type="text/javascript" src="{$staticroot}/js/Cesium.js"></script>
  <link rel="stylesheet" type="text/css" href="{$staticroot}/css/cesium-widgets.css"/>
  <style>
        html, body, #cesiumContainer {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
            overflow: hidden;
        }
  </style>
	<div class="panel panel-primary">
		<div class="panel-heading"/>
		<div class="panel-body">
			<div id="cesiumContainer"></div>
		</div>
	</div>
  <script>
<![CDATA[
// create a viewer and assign it to a div container "cesiumContainer"
//then, add the datasource  an make the viever zoom to the data source entities

      var viewer = new Cesium.Viewer('cesiumContainer', {
              
				  timeline: false,
				 animation: false,
       selectionIndicator : true,
				  geocoder: false,
				homeButton: false,
			   scene3DOnly: true,
	  navigationHelpButton: false,
	             vrButton : true,
                  infoBox : true
				  
					});
	viewer.dataSources.add(Cesium.KmlDataSource.load('/images/89338686-C050-480E-A5EE-993A872B0F07_geometry.kml')
		).then( function (dataSource) {
		viewer.zoomTo(dataSource.entities);
				}
		);

		var scene = viewer.scene;

// add a label to the building 'Beurs-World Trade Center' using coorinates 
	viewer.entities.add({
	   	position : Cesium.Cartesian3.fromDegrees(4.4813676, 51.9213224, 130.0),
		   label : {
				text : 'Beurs-World Trade Center',
				font : '18px Helvetica',
		   fillColor : Cesium.Color.GOLD,
		outlineColor : Cesium.Color.BLACK,
		outlineWidth : 2,
			   style : Cesium.LabelStyle.FILL_AND_OUTLINE
			}
		});
	
	
	
	
// create an event handler that fires SPARQL against the endpoint by a left click


	var handler = new Cesium.ScreenSpaceEventHandler(scene.canvas);
		
	handler.setInputAction(function(click) {
	
// Pick an object and figure out its coordinates
	
			var pickedObject = scene.pick(click.position);
			var cartesian = viewer.camera.pickEllipsoid(click.position, scene.globe.ellipsoid);
			var cartographic = Cesium.Cartographic.fromCartesian(cartesian);
			var longitudeString = Cesium.Math.toDegrees(cartographic.longitude).toFixed(6);
			var latitudeString = Cesium.Math.toDegrees(cartographic.latitude).toFixed(6);
			
// if an object is picked a query is sent to the endpoint 
 
		if (Cesium.defined(pickedObject) || (cartesian)) {
	  
			var subject = pickedObject.id.name.substring(1, 37);
			var pickedCoord = longitudeString + " " + latitudeString;
	
					console.log(subject);
					console.log(pickedCoord);
					
// define a query and convert it into uri		
	
			var uriBase = "http://ec2-54-229-171-74.eu-west-1.compute.amazonaws.com:7200/repositories/stan_data";
			var query = 'Prefix geof: <http://www.opengis.net/def/function/geosparql/> Select distinct ?bagId ?numVelue WHERE {?sensor a <http://purl.oclc.org/NET/ssnx/ssn#Sensor>; <http://purl.oclc.org/NET/ssnx/ssn#hasLocation> ?location. ?location a <http://www.opengis.net/citygml/building/2.0/RoofSurface>. <http://example.com/my/' + subject +'> <http://www.opengis.net/citygml/building/2.0/boundedBy> ?location. ?observation <http://purl.oclc.org/NET/ssnx/ssn#observedBy> ?sensor; <http://purl.oclc.org/NET/ssnx/ssn#observationSamplingTime> ?time; <http://purl.oclc.org/NET/ssnx/ssn#observationResult> ?sensorOutput. ?sensorOutput <http://purl.oclc.org/NET/ssnx/ssn#hasValue> ?observationValue. ?observationValue <http://qudt.org/schema/qudt#numericValue> ?numVelue. ?time <http://www.w3.org/2006/time#inXSDDateTime> "7-9-2014 15:12"^^<http://www.w3.org/2001/XMLSchema#dateTime>. ?bagId <http://www.opengis.net/ont/geosparql#hasGeometry> ?geom. ?geom <http://www.opengis.net/ont/geosparql#asWKT> ?geomWkt. BIND ("POINT(' + pickedCoord + ')"^^<http://www.opengis.net/ont/geosparql#wktLiteral> as ?point) Filter (geof:sfWithin(?point, ?geomWkt))}';
			var queryURI = encodeURIComponent(query);
			var URI = uriBase + "?" + "query=" + queryURI;
			var dataQuery = "query=" + queryURI;

					console.log(URI);
					
// Ajax call with the query				
// If the call is successfull, use the data for the massage in the info box

					$.ajax({
									async: true,
								   method: "POST",
									  url: uriBase,
								  headers: {
											"connection": "keep-alive",
												"accept": "application/xml,*/*;q=0.9",
										  "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
											},
									 data: dataQuery,			
								  success: function(data) {
								  
// create a message in the info box using the response
															console.log(data);
													var bag_id = $(data).find('uri').first().text();
													var temp = $(data).find('literal').first().text();
															console.log(bag_id);  
															console.log(temp);
											var descrText = "There are " + temp + "°C at the roof of " + bag_id;

													viewer.selectedEntity = new Cesium.Entity({
																description : descrText
																								});
															}
							});

    }
										}, Cesium.ScreenSpaceEventType.LEFT_CLICK);


]]>
  </script>
</xsl:template>

</xsl:stylesheet>