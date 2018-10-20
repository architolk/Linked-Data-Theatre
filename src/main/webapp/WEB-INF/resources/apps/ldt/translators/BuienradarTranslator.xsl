<!--

    NAME     BuienradarTranslator.xsl
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
	Translates Buienrader XML API to RDF
	
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
		<xsl:if test="response!=''">
			<xsl:for-each select="tokenize(response,'\n')">
				<xsl:variable name="tijdstip" select="substring(substring-after(.,'|'),1,5)"/>
				<xsl:if test="$tijdstip!=''">
					<rdf:Description rdf:about="http://buienradar.nl/id/tijdstip/{$tijdstip}">
						<rdfs:label><xsl:value-of select="$tijdstip"/></rdfs:label>
						<rdf:value><xsl:value-of select="substring-before(.,'|')"/></rdf:value>
					</rdf:Description>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		<xsl:for-each select="response/buienradarnl/weergegevens/actueel_weer/weerstations/weerstation">
			<rdf:Description rdf:about="http://buienradar.nl/id/weerstation/{@id}">
				<rdfs:label><xsl:value-of select="stationnaam"/></rdfs:label>
				<geo:lat><xsl:value-of select="(lat - floor(lat)) div 0.6 + floor(lat)"/></geo:lat>
				<geo:long><xsl:value-of select="(lon - floor(lon)) div 0.6 + floor(lon)"/></geo:long>
				<html:icon><xsl:value-of select="icoonactueel"/></html:icon>
				<rdf:value><xsl:if test="temperatuur10cm!='-'"><xsl:value-of select="temperatuur10cm"/></xsl:if></rdf:value>
			</rdf:Description>
		</xsl:for-each>
	</rdf:RDF>
</xsl:template>

</xsl:stylesheet>