<!--

    NAME     rdf2txt.xsl
    VERSION  1.6.0
    DATE     2016-03-13

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
    Transformation of RDF document to text format
	
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">

<xsl:key name="bnodes" match="/rdf:RDF/rdf:Description" use="@rdf:nodeID"/>

<xsl:template match="/">
<xsl:for-each select="results/rdf:RDF/rdf:Description/*">
	<xsl:value-of select="."/><xsl:text>
</xsl:text>
</xsl:for-each>
</xsl:template>

</xsl:stylesheet>