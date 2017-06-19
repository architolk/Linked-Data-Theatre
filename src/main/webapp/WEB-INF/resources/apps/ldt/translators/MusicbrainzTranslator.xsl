<!--

    NAME     MusicbrainzTranslator.xsl
    VERSION  1.18.0
    DATE     2017-06-18

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
	xmlns:mmd="http://musicbrainz.org/ns/mmd-2.0#"
>

<xsl:template match="/">
	<rdf:RDF>
		<xsl:for-each select="response/mmd:metadata/mmd:artist">
			<rdf:Description rdf:about="http://musicbrainz.org/ws/2/artist/{@id}">
				<rdfs:label><xsl:value-of select="mmd:name"/></rdfs:label>
				<xsl:for-each select="mmd:relation-list[@target-type='artist']/mmd:relation[not(exists(mmd:direction))]">
					<xsl:element name="mmd:{replace(@type,' ','-')}">
						<xsl:attribute name="rdf:resource">http://musicbrainz.org/ws/2/artist/<xsl:value-of select="mmd:target"/></xsl:attribute>
					</xsl:element>
				</xsl:for-each>
			</rdf:Description>
		</xsl:for-each>
		<xsl:for-each select="response/mmd:metadata/mmd:artist/mmd:relation-list/mmd:relation/mmd:artist">
			<rdf:Description rdf:about="http://musicbrainz.org/ws/2/artist/{@id}">
				<rdfs:label><xsl:value-of select="mmd:name"/></rdfs:label>
				<xsl:if test="../mmd:direction='backward'">
					<xsl:element name="mmd:{replace(../@type,' ','-')}">
						<xsl:attribute name="rdf:resource">http://musicbrainz.org/ws/2/artist/<xsl:value-of select="../../../@id"/></xsl:attribute>
					</xsl:element>
				</xsl:if>
			</rdf:Description>
		</xsl:for-each>
	</rdf:RDF>
</xsl:template>

</xsl:stylesheet>