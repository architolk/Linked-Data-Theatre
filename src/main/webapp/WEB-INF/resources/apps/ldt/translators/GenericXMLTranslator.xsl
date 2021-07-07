<!--

    NAME     FBMTranslator.xsl
    VERSION  1.25.3-SNAPSHOT
    DATE     2020-11-25

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
	Translates XML to a simple RDF format. Most usable for debugging purposes

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:xmlvoc="http://bp4mc2.org/def/xml#"

	xmlns:fn="http://architolk.nl/fn"
>

	<xsl:function name="fn:upperCamelCase" as="xs:string">
		<xsl:param name="input" as="xs:string"/>
		<xsl:value-of select="concat(upper-case(substring($input,1,1)),substring($input,2))"/>
	</xsl:function>

	<xsl:function name="fn:lowerCamelCase" as="xs:string">
		<xsl:param name="input" as="xs:string"/>
		<xsl:value-of select="concat(lower-case(substring($input,1,1)),substring($input,2))"/>
	</xsl:function>

	<xsl:template match="*[(count(*)+count(@*))>0]" mode="property">
		<xsl:element name="xmlvoc:{fn:lowerCamelCase(local-name())}">
			<xsl:attribute name="rdf:resource">urn:uuid:<xsl:value-of select="generate-id()"/></xsl:attribute>
		</xsl:element>
	</xsl:template>

	<xsl:template match="*" mode="property">
		<!--Don't show empty properties -->
		<xsl:if test=".!=''">
			<xsl:element name="xmlvoc:{fn:lowerCamelCase(local-name())}">
				<xsl:value-of select="."/>
			</xsl:element>
		</xsl:if>
	</xsl:template>

	<xsl:template match="@*" mode="attribute">
		<!--Don't show empty properties -->
		<xsl:if test=".!=''">
			<xsl:element name="xmlvoc:{fn:lowerCamelCase(local-name())}">
				<xsl:value-of select="."/>
			</xsl:element>
		</xsl:if>
	</xsl:template>

	<xsl:template match="*" mode="node">
		<xsl:element name="xmlvoc:{fn:upperCamelCase(local-name())}">
			<xsl:attribute name="rdf:about">urn:uuid:<xsl:value-of select="generate-id()"/></xsl:attribute>
			<xsl:apply-templates select="@*" mode="attribute"/>
			<xsl:apply-templates select="*" mode="property"/>
		</xsl:element>
		<xsl:apply-templates select="*[(count(*)+count(@*))>0]" mode="node"/>
	</xsl:template>

	<xsl:template match="/">
		<rdf:RDF>
			<xsl:for-each select="/root/*[local-name()!='container' and local-name()!='file']">
				<xsl:element name="xmlvoc:{fn:upperCamelCase(local-name())}">
					<xsl:attribute name="rdf:about">urn:uuid:<xsl:value-of select="generate-id()"/></xsl:attribute>
					<xsl:apply-templates select="@*" mode="attribute"/>
					<xsl:apply-templates select="*" mode="property"/>
				</xsl:element>
				<xsl:apply-templates select="*[(count(*)+count(@*))>0]" mode="node"/>
			</xsl:for-each>
		</rdf:RDF>
	</xsl:template>
</xsl:stylesheet>
