<!--

    NAME     AnchorTranslator.xsl
    VERSION  1.23.1-SNAPSHOT
    DATE     2019-11-07

    Copyright 2012-2019

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
	xmlns:anchor="http://bp4mc2.org/def/anchor#"
>

<xsl:variable name="prefix">urn:mnemonic:</xsl:variable>

<xsl:template match="/">
	<rdf:RDF>
		<xsl:for-each select="root/schema/knot">
			<anchor:Knot rdf:about="{$prefix}knot:{@mnemonic}">
				<anchor:mnemonic><xsl:value-of select="@mnemonic"/></anchor:mnemonic>
				<anchor:descriptor><xsl:value-of select="@descriptor"/></anchor:descriptor>
				<xsl:for-each select="description"><anchor:description><xsl:value-of select="."/></anchor:description></xsl:for-each>
			</anchor:Knot>
		</xsl:for-each>
		<xsl:for-each select="root/schema/anchor">
			<anchor:Anchor rdf:about="{$prefix}anchor:{@mnemonic}">
				<anchor:mnemonic><xsl:value-of select="@mnemonic"/></anchor:mnemonic>
				<anchor:descriptor><xsl:value-of select="@descriptor"/></anchor:descriptor>
				<xsl:for-each select="description"><anchor:description><xsl:value-of select="."/></anchor:description></xsl:for-each>
				<xsl:for-each select="attribute">
					<anchor:attribute>
						<anchor:Attribute>
							<anchor:mnemonic><xsl:value-of select="@mnemonic"/></anchor:mnemonic>
							<anchor:descriptor><xsl:value-of select="@descriptor"/></anchor:descriptor>
							<xsl:if test="exists(@dataRange)"><anchor:dataRange><xsl:value-of select="@dataRange"/></anchor:dataRange></xsl:if>
							<xsl:if test="exists(@knotRange)"><anchor:knotRange rdf:resource="{$prefix}knot:{@knotRange}"/></xsl:if>
							<xsl:for-each select="description"><anchor:description><xsl:value-of select="."/></anchor:description></xsl:for-each>
						</anchor:Attribute>
					</anchor:attribute>
				</xsl:for-each>
			</anchor:Anchor>
		</xsl:for-each>
		<xsl:for-each select="root/schema/tie">
			<anchor:Tie rdf:about="{$prefix}tie:{position()}"> <!-- Not good, but what is the identifier of a tie?? -->
				<xsl:for-each select="anchorRole">
					<anchor:anchorRole>
						<anchor:AnchorRole>
							<anchor:role><xsl:value-of select="@role"/></anchor:role>
							<anchor:identifier><xsl:value-of select="@identifier"/></anchor:identifier>
							<xsl:for-each select="description"><anchor:description><xsl:value-of select="."/></anchor:description></xsl:for-each>
							<anchor:type rdf:resource="{$prefix}anchor:{@type}"/>
						</anchor:AnchorRole>
					</anchor:anchorRole>
				</xsl:for-each>
				<xsl:for-each select="description"><anchor:description><xsl:value-of select="."/></anchor:description></xsl:for-each>
			</anchor:Tie>
		</xsl:for-each>
	</rdf:RDF>
</xsl:template>

</xsl:stylesheet>
