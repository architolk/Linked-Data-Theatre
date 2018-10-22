/*
 * NAME     chart.js
 * VERSION  1.23.1-SNAPSHOT
 * DATE     2018-10-22
 *
 * Copyright 2012-2018
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
 * Javascript routines used with the chart appearance
 *
 */

// Calculate a linear regression from the data

// Takes 5 parameters:
// (1) Your data
// (2) A function that calculates the x position of an element in your data
// (3) A function that calculates the y position of an element in your data
// (4) The maximum value of your x-axis
// (5) The maximum value of your y-axis

// Returns an object with two points, where each point is an object with an x and y coordinate

function calcLinear(data, x, y, maxX, maxY){
 var minX = 0;
 var minY = 0;
 /////////
 //SLOPE//
 /////////

 // Let n = the number of data points
 var n = data.length;

 // Get just the points
 var pts = [];
 data.forEach(function(d,i){
   var obj = {};
   obj.x = x(d);
   obj.y = y(d);
   obj.mult = obj.x*obj.y;
   pts.push(obj);
 });

 // Let a equal n times the summation of all x-values multiplied by their corresponding y-values
 // Let b equal the sum of all x-values times the sum of all y-values
 // Let c equal n times the sum of all squared x-values
 // Let d equal the squared sum of all x-values
 var sum = 0;
 var xSum = 0;
 var ySum = 0;
 var sumSq = 0;
 pts.forEach(function(pt){
   sum = sum + pt.mult;
   xSum = xSum + pt.x;
   ySum = ySum + pt.y;
   sumSq = sumSq + (pt.x * pt.x);
 });
 var a = sum * n;
 var b = xSum * ySum;
 var c = sumSq * n;
 var d = xSum * xSum;

 // Plug the values that you calculated for a, b, c, and d into the following equation to calculate the slope
 // slope = m = (a - b) / (c - d)
 var m = (a - b) / (c - d);

 /////////////
 //INTERCEPT//
 /////////////

 // Let e equal the sum of all y-values
 var e = ySum;

 // Let f equal the slope times the sum of all x-values
 var f = m * xSum;

 // Plug the values you have calculated for e and f into the following equation for the y-intercept
 // y-intercept = b = (e - f) / n
 var b = (e - f) / n;

 // return an object of two points
 // each point is an object with an x and y coordinate
 return {
   ptA : {
     x: minX,
     y: m * minX + b
   },
   ptB : {
     x: maxX,
     y: m * maxX + b
   }
 }

}

function plotChart(data, appearance, xtype, ytype) {

 function getX(d) {return (typeof x.rangeBand)!= "undefined" ? x(d.d)+x.rangeBand()/2 : x(d.d)};
 function getY(d) {return (typeof y.rangeBand)!= "undefined" ? y(d.m)+y.rangeBand()/2 : y(d.m)};

 var margin = {top: 20, right: 30, bottom: 30, left: 40},
   width = 800 - margin.left - margin.right,
   height = 400 - margin.top - margin.bottom;

 var x;
 if (xtype==="decimal" || xtype==="integer") {
   x = d3.scale.linear()
     .domain([d3.min(data, function (d) {return d.d;}),d3.max(data, function (d) {return d.d;})])
     .range([0, width]);
 } else if (xtype==="dateTime") {
   x = d3.time.scale()
     .domain([d3.min(data, function (d) {return d.d;}),d3.max(data, function (d) {return d.d;})])
     .range([0, width]);
 } else {
   x = d3.scale.ordinal()
     .domain(data.map(function (d) {return d.d;}))
     .rangeRoundBands([0, width], 0.1);
 }

 var y = d3.scale.linear()
   .domain([d3.min(data, function (d) {return d.m;}),d3.max(data, function (d) {return d.m;})])
   .range([height, 0]);

 var xAxis = d3.svg.axis()
   .scale(x)
   .orient("bottom");

 var yAxis = d3.svg.axis()
   .scale(y)
   .orient("left");

 var chart = d3.select("#chart").append("svg")
   .attr("width", width + margin.left + margin.right)
   .attr("height", height + margin.top + margin.bottom)
   .append("g")
   .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

 chart.append("g")
   .attr("class", "x axis")
   .attr("transform", "translate(0," + height + ")")
   .call(xAxis);

 chart.append("g")
   .attr("class", "y axis")
   .call(yAxis);

 if (appearance==="ScatterPlotChartAppearance") {
   var lg = calcLinear(data, getX, getY, width, height);

   chart.append("line")
       .attr("class","line")
       .attr("x1", lg.ptA.x)
       .attr("y1", lg.ptA.y)
       .attr("x2", lg.ptB.x)
       .attr("y2", lg.ptB.y);

   chart.selectAll(".bar")
     .data(data)
     .enter().append("circle")
       .attr("class", "bar")
       .attr("cx", getX)
       .attr("cy", function(d) { return y(d.m)})
       .attr("r", 5);
 } else if (appearance==="LineChartAppearance") {
   var line = d3.svg.line()
                 .x(getX)
                 .y(getY)
                 .interpolate("cardinal");
   chart.append("path")
     .attr("d", line(data))
     .attr("class","line")

   chart.selectAll(".bar")
     .data(data)
     .enter().append("circle")
       .attr("class", "bar")
       .attr("cx", getX)
       .attr("cy", getY)
       .attr("r", 5);
 } else {
   chart.selectAll(".bar")
     .data(data)
   .enter().append("rect")
     .attr("class", "bar")
     .attr("x", function(d) { return x(d.d)})
     .attr("y", function(d) { return y(d.m)})
     .attr("height", function(d) { return height - y(d.m); })
     .attr("width", x.rangeBand());
 }
}
