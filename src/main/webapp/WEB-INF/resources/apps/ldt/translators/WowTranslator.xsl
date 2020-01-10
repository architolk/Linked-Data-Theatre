<!--

    NAME     WowTranslator.xsl
    VERSION  1.24.0
    DATE     2020-01-10

    Copyright 2012-2020

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
	Translates Wow JSON API to RDF
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
>

<xsl:template match="/">
	<rdf:RDF>
		<xsl:for-each select="response/sites">
			<rdf:Description rdf:about="http://wow.knmi.nl/site/{id}">
				<rdfs:label><xsl:value-of select="name"/></rdfs:label>
				<rdf:value><xsl:value-of select="property/temperature"/></rdf:value>
				<geo:lat><xsl:value-of select="geo/coordinates[1]"/></geo:lat>
				<geo:long><xsl:value-of select="geo/coordinates[2]"/></geo:long>
			</rdf:Description>
		</xsl:for-each>
	</rdf:RDF>
</xsl:template>

</xsl:stylesheet>