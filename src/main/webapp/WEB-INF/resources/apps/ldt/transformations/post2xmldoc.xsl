<!--

    NAME     post2xmldoc.xsl
    VERSION  1.8.0
    DATE     2016-06-15

    Copyright 2012-2016

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
	Transforms the posted svg xml to a xml document for further processing in the svg2document.xpl pipeline
	
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sparql="http://www.w3.org/2005/sparql-results#" xmlns:error="http://apache.org/cocoon/sparql/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">

<xsl:template match="/">
<xsl:for-each select="request/parameters/parameter[name='data']">
<document xsi:type="xs:string" content-type="application/xml">
<xsl:value-of select="value"/>
</document>
</xsl:for-each>
</xsl:template>

</xsl:stylesheet>