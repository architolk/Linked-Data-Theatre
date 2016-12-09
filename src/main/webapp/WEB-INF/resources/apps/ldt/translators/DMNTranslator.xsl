<!--

    NAME     DMNTranslator.xsl
    VERSION  1.13.1-SNAPSHOT
    DATE     2016-12-09

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
	Translates XML/DMN to a conforming RDF representation
	
-->
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:dmn="http://www.omg.org/spec/DMN/20151101/dmn.xsd"
	xmlns:dmno="http://www.omg.org/spec/DMN/20151101/dmn#"
>

	<xsl:variable name="dmno-prefix">http://www.omg.org/spec/DMN/20151101/dmn#</xsl:variable>

	<!-- Properties -->
	<xsl:template match="dmn:informationRequirement|dmn:knowledgeRequirement|dmn:authorityRequirement">
		<xsl:variable name="name"><xsl:value-of select="local-name()"/></xsl:variable>
		<xsl:for-each select="*">
			<xsl:element name="dmno:{$name}">
				<xsl:attribute name="rdf:resource">urn:uuid:<xsl:value-of select="substring-after(@href,'_')"/></xsl:attribute>
			</xsl:element>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="dmn:description">
		<dmno:description><xsl:value-of select="."/></dmno:description>
	</xsl:template>
	
	<!-- Classes -->
	<xsl:template match="dmn:variable">
		<xsl:variable name="type">
			<xsl:choose>
				<xsl:when test="@typeRef='feel:boolean'">Boolean</xsl:when>
				<xsl:otherwise>Unknown</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:variable>
			<dmno:Variable rdf:about="urn:uuid:{substring-after(@id,'_')}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<dmno:type rdf:resource="{$dmno-prefix}{$type}"/>
				<xsl:apply-templates select="dmn:description"/>
			</dmno:Variable>
		</dmno:variable>
	</xsl:template>

	<xsl:template match="dmn:decision">
		<dmno:Decision rdf:about="urn:uuid:{substring-after(@id,'_')}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="dmn:informationRequirement|dmn:knowledgeRequirement|dmn:authorityRequirement"/>
			<xsl:apply-templates select="dmn:description"/>
			<xsl:apply-templates select="dmn:variable"/>
		</dmno:Decision>
	</xsl:template>

	<xsl:template match="dmn:inputData">
		<dmno:InputData rdf:about="urn:uuid:{substring-after(@id,'_')}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="dmn:informationRequirement|dmn:knowledgeRequirement|dmn:authorityRequirement"/>
			<xsl:apply-templates select="dmn:description"/>
			<xsl:apply-templates select="dmn:variable"/>
		</dmno:InputData>
	</xsl:template>

	<xsl:template match="dmn:knowledgeSource">
		<dmno:KnowledgeSource rdf:about="urn:uuid:{substring-after(@id,'_')}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:if test="exists(@locationURI)"><dmno:locationURI rdf:resource="{@locationURI}"/></xsl:if>
			<xsl:apply-templates select="dmn:description"/>
		</dmno:KnowledgeSource>
	</xsl:template>
	
	<xsl:template match="dmn:businessKnowledgeModel">
		<dmno:BusinessKnowledgeModel rdf:about="urn:uuid:{substring-after(@id,'_')}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="dmn:informationRequirement|dmn:knowledgeRequirement|dmn:authorityRequirement"/>
			<xsl:apply-templates select="dmn:description"/>
			<xsl:apply-templates select="dmn:variable"/>
		</dmno:BusinessKnowledgeModel>
	</xsl:template>
	
	<xsl:template match="dmn:organizationUnit">
		<dmno:OrganizationUnit rdf:about="urn:uuid:{substring-after(@id,'_')}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="dmn:description"/>
		</dmno:OrganizationUnit>
	</xsl:template>
	
	<!-- Main entry -->
	<xsl:template match="dmn:definitions">
		<xsl:apply-templates select="dmn:decision|dmn:inputData|dmn:knowledgeSource|dmn:businessKnowledgeModel|dmn:organizationUnit"/>
	</xsl:template>

	<xsl:template match="/root">
		<rdf:RDF>
			<xsl:apply-templates select="dmn:definitions"/>
		</rdf:RDF>
	</xsl:template>
</xsl:stylesheet>
