<!--

    NAME     BAGWFSTranslator.xsl
    VERSION  1.22.0
    DATE     2018-06-13

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
	Translates BAG WFS to RDF
	
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
	xmlns:wfs="http://www.opengis.net/wfs/2.0"
	xmlns:gml="http://www.opengis.net/gml/3.2"
	xmlns:bag="http://bag.geonovum.nl"
	xmlns:bago="http://bag.basisregistraties.overheid.nl/def/bag#"
>

<xsl:template match="/">
	<rdf:RDF>
		<xsl:for-each select="response/wfs:FeatureCollection/wfs:member/*">
			<rdf:Description rdf:about="http://bag.basisregistraties.overheid.nl/bag/id/verblijfsobject/{format-number(bag:identificatie,'0000000000000000')}">
				<bago:oppervlakte><xsl:value-of select="bag:oppervlakte"/></bago:oppervlakte>
				<bago:adres><xsl:value-of select="bag:openbare_ruimte"/><xsl:text> </xsl:text><xsl:value-of select="bag:huisnummer"/><xsl:text> </xsl:text><xsl:value-of select="bag:woonplaats"/></bago:adres>
				<bago:oorspronkelijkBouwjaar><xsl:value-of select="bag:bouwjaar"/></bago:oorspronkelijkBouwjaar>
				<bago:gebruiksdoel><xsl:value-of select="bag:gebruiksdoel"/></bago:gebruiksdoel>
				<bago:pandrelatering rdf:resource="http://bag.basisregistraties.overheid.nl/bag/id/verblijfsobject/{format-number(bag:pandidentificatie,'0000000000000000')}"/>
			</rdf:Description>
		</xsl:for-each>
	</rdf:RDF>
</xsl:template>

</xsl:stylesheet>