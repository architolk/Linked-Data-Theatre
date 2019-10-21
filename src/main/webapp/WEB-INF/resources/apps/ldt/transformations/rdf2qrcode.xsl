<!--

    NAME     rdf2qrcode.xsl
    VERSION  1.23.1-SNAPSHOT
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
    Transformation of RDF document to a qr code

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
>

<xsl:output method="xml" indent="yes"/>

<xsl:variable name="staticroot"><xsl:value-of select="/context/@staticroot"/></xsl:variable>
<xsl:variable name="ldtversion">?version=<xsl:value-of select="/context/@version"/></xsl:variable>

<xsl:template match="/">
	<html>
		<head>
			<meta charset="utf-8"/>
			<meta http-equiv="X-UA-Compatible" content="IE=edge" />
			<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
			<title><xsl:value-of select="context/subject"/></title>
			<script type="text/javascript" src="{$staticroot}/js/kjua.min.js{$ldtversion}"></script>
	  </head>
		<body>
			<xsl:if test="context/subject!=''">
				<img id="logo" src="{$staticroot}/images/rdflogo.png" style="display:none"/>
				<script type="text/javascript">
					var options = {
		        ecLevel: 'H',
		        rounded: 100,
		        quiet: 1,
		        size: 300,
		        back: '#FFFFFF',
		        fill: '#000000',
		        mode: 'image',
		        mSize: 30,
		        mPosX: 50,
		        mPosY: 50,
		        image: document.getElementById('logo'),
		        text: '<xsl:value-of select="context/subject"/>'
		      };
		      var el = kjua(options);
		      document.querySelector('body').appendChild(el);
				</script>
			</xsl:if>
		</body>
	</html>
</xsl:template>

</xsl:stylesheet>
