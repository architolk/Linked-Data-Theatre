/*
 * NAME     leaflet.label.js
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
 * Inspired by Leaflet.label
 * Changed to use svg.text element instead of div
 *
 * TODO: Test for all situations, this version is just a quick-fix
 */

(function (window, document, undefined) {
var L = window.L;

L.Label = (L.Layer ? L.Layer : L.Class).extend({

	includes: L.Mixin.Events,

	options: {
		className: '',
		clickable: false,
		direction: 'right',
		noHide: false,
		offset: [12, -15], // 6 (width of the label triangle) + 6 (padding)
		opacity: 1,
		zoomAnimation: true
	},
	
	initialize: function (options, source) {
		L.setOptions(this, options);

		this._source = source;
		this._animated = L.Browser.any3d && this.options.zoomAnimation;
		this._isOpen = false;
	},

	setLatLng: function (latlng) {
		this._latlng = L.latLng(latlng);
		if (this._map) {
			this._updatePosition();
		}
		return this;
	},

	setContent: function (content) {
		this._content = content;
		return this;
	},

	onAdd: function (map) {
		this._map = map;

		if (!this._container) {
			this._initLayout();
		}
		this._update();

		map
			.on('viewreset', this._onViewReset, this)
			.on('zoomanim', this._zoomAnimation, this);

	},
	
	_initLayout: function () {
		this._container = document.createElementNS("http://www.w3.org/2000/svg","text");
		var txt = this._content + " ";
		var txtArray = txt.replace(/(.{17,17})(.+)/,"$1...").replace(/(.{0,17}) /g,"$1~").split("~");
		for (var i=0; i<txtArray.length; i++) {
			var tsNode = document.createElementNS("http://www.w3.org/2000/svg","tspan");
			tsNode.textContent = txtArray[i];
			this._container.appendChild(tsNode);
		}
		this._source._path.parentNode.appendChild(this._container);
	},

	_updatePosition: function () {
		var pos = this._map.latLngToLayerPoint(this._latlng);
		this._setPosition(pos,this._map.getZoom());
	},

	_update: function () {
		if (!this._map) { return; }

		//this._container.style.visibility = 'hidden';
		//this._updateContent();
		this._updatePosition();
		//this._container.style.visibility = '';
	},

	_zoomAnimation: function (opt) {
		var pos = this._map._latLngToNewLayerPoint(this._latlng, opt.zoom, opt.center).round();
		this._setPosition(pos,opt.zoom);
	},

	_onViewReset: function (e) {
		/* if map resets hard, we must update the label */
		if (e && e.hard) {
			this._update();
		}
	},

	_setPosition: function (pos,zoom) {
		//sizing for labels is a power of two
		var zoomSize = Math.pow(2,zoom+1);
		this._container.setAttribute("x",pos.x+zoomSize);
		this._container.setAttribute("y",pos.y-zoomSize);
		this._container.style.fontSize = zoomSize+"px";
		for (var i=0; i<this._container.childNodes.length; i++) {
			this._container.childNodes.item(i).setAttribute("x",pos.x+zoomSize);
			this._container.childNodes.item(i).setAttribute("dy",zoomSize);
		}
	}
	
});

// This object is a mixin for L.Marker and L.CircleMarker. We declare it here as both need to include the contents.
L.BaseMarkerMethods = {

	showLabel: function () {
		if (this.label && this._map) {
			this.label.setLatLng(this._latlng);
			this._map.showLabel(this.label);
		}

		return this;
	},
	
	bindLabel: function (content, options) {
		this.label = new L.Label(options, this)
			.setContent(content);

		return this;
	},

	_moveLabel: function (e) {
		if (this.label._map) {
			this.label.setLatLng(e.latlng);
		}
	}

}
L.Marker.include(L.BaseMarkerMethods);
L.CircleMarker.include(L.BaseMarkerMethods);

L.FeatureGroup.include({
	bindLabel: function (content, options) {
		return this.invoke('bindLabel', content, options);
	},
	showLabel: function () {
		return this.invoke('showLabel');
	}
});

L.Map.include({
	showLabel: function (label) {
		return this.addLayer(label);
	}
});

}(window, document));