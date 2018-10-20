<!--

    NAME     rdf2ttl.xsl
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
	Transformation of RDF document to turtle format
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
>

<xsl:include href="rdf2turtle.xsl"/>

<xsl:key name="bnode" match="results/rdf:RDF[1]/rdf:Description|xmlresult/rdf:RDF[1]/rdf:Description" use="@rdf:nodeID"/>

<xsl:template match="/">
	<xsl:apply-templates select="results/rdf:RDF[1]" mode="rdf2turtle"/>
	<xsl:for-each select="xmlresult">
		<turtle>
			<xsl:apply-templates select="rdf:RDF[1]" mode="rdf2turtle"/>
		</turtle>
	</xsl:for-each>
</xsl:template>

</xsl:stylesheet>