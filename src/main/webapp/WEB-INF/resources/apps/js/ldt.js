/*
 * NAME     ldt.js
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
 * Javascript routines used within the LDT
 *
 */

 /*
  *  Routines for FrameAppearance
  */
function getDocHeight(doc) {
    doc = doc || document;
    var body = doc.body, html = doc.documentElement;
    var height = Math.max( body.scrollHeight, body.offsetHeight, 
        html.clientHeight, html.scrollHeight, html.offsetHeight );
    return height;
}
function setFrameHeight(ifrm) {
    var doc = ifrm.contentDocument? ifrm.contentDocument: 
        ifrm.contentWindow.document;
    ifrm.style.visibility = 'hidden';
    ifrm.style.height = "50px"; // reset to minimal height ...
    // IE opt. for bing/msn needs a bit added or scrollbar appears
    ifrm.style.height = getDocHeight( doc ) + 4 + "px";
    ifrm.style.visibility = 'visible';
}

 /*
  *  Routines for TextAppearance
  */
function gotoFrame(link) {
	if (window.name.substring(0,5)==='frame') {
		siblingname = "frame" + String(Number(window.name.substring(5))+1);
		sibling = parent.document.getElementsByName(siblingname)[0];
		if (sibling) {
			sibling.src = link
		} else {
			parent.window.location = link
		}
	} else {
		window.location = link
	}
}
