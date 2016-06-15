<!--

    NAME     rdf2jsonldcontext.xsl
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
    Transformation of RDF document to json-ld format
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
>

<xsl:template match="/">
{"@context":
	{<xsl:for-each-group select="results/rdf:RDF[1]/rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#DatatypeProperty' or rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#ObjectProperty']" group-by="@rdf:about"><xsl:sort select="@rdf:about"/><xsl:if test="position()!=1">
	,</xsl:if>"<xsl:value-of select="replace(@rdf:about,'^.*(#|/)','')"/>":{"@id":"<xsl:value-of select="@rdf:about"/>"<xsl:if test="rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#ObjectProperty'">,"@type":"@id"</xsl:if>}</xsl:for-each-group>
	}
}
</xsl:template>

</xsl:stylesheet>