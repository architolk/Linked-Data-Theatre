<!--

    NAME     XSDTranslator.xsl
    VERSION  1.25.0
    DATE     2020-07-19

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
	Translates XSD to corresponding linked data (SHACL shapes)

-->
<xsl:stylesheet version="2.0"
	xmlns:xmi="http://schema.omg.org/spec/XMI/2.1"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
>

<xsl:variable name="prefix">http://elmo.localhost/ldt/id/</xsl:variable>
<xsl:variable name="archi-namespace">http://bp4mc2.org/def/archi#</xsl:variable>

<xsl:template match="xs:schema" mode="properties">
	<xsd:element rdf:resource="{$prefix}{@name}"/>
</xsl:template>

<xsl:template match="xs:element" mode="parse">
</xsl:template>

<xsl:template match="xs:schema" mode="parse">
	<xsd:Schema rdf:about="{$prefix}{@name}">
	  <rdfs:label><xsl:value-of select="@name"/></rdfs:label>
		<xsl:apply-templates select="xs:element" mode="properties"/>
	</xs:Schema>
	<xsl:apply-templates select="xs:element" mode="parse"/>
</xsl:template>

<xsl:template match="/root">
	<rdf:RDF>
		<xsl:apply-templates select="xs:schema" mode="parse"/>
	</rdf:RDF>
</xsl:template>

</xsl:stylesheet>
