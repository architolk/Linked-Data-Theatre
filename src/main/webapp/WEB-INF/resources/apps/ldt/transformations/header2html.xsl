<!--

    NAME     header2html.xsl
    VERSION  1.14.0
    DATE     2017-01-04

    Copyright 2012-2017

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
    Transforms the regular header XML to html

-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">

<xsl:template match="*" mode="rec">

	<ul>
		<li><span><xsl:value-of select="name()"/></span>
			<xsl:choose>
				<xsl:when test="exists(*)"><xsl:apply-templates select="*" mode="rec"/></xsl:when>
				<xsl:otherwise><span style="padding-left: 10px; float:right;"><xsl:value-of select="."/></span></xsl:otherwise>
			</xsl:choose>
		</li>
	</ul>
</xsl:template>

<xsl:template match="/">
	<html>
		<body>
			<table><tr><td>
				<xsl:apply-templates select="*" mode="rec"/>
			</td></tr></table>
		</body>
	</html>
</xsl:template>

</xsl:stylesheet>
