<!--

    NAME     ArchimateTranslator.xsl
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
	Translates Archimate to corresponding linked data
	Input format should conform to the Open Group Archimate Exchange format (http://www.opengroup.org/xsd/archimate)
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xmi="http://schema.omg.org/spec/XMI/2.1"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:archixsd="http://www.opengroup.org/xsd/archimate"
	xmlns:archi="http://bp4mc2.org/def/archi#"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>

<xsl:variable name="prefix">http://elmo.localhost/ldt/id/</xsl:variable>
<xsl:variable name="archi-namespace">http://bp4mc2.org/def/archi#</xsl:variable>

<xsl:key name="elements" match="/root/archixsd:model/archixsd:elements/archixsd:element" use="@identifier"/>

<xsl:variable name="propertymap">
	<p type="AccessRelationship" qname="accesses"/>
	<p type="AggregationRelationship" qname="aggregates"/>
	<p type="AssignmentRelationship" qname="assignedTo"/>
	<p type="AssociationRelationship" qname="isAssociatedWith"/>
	<p type="CompositionRelationship" qname="isComposedOf"/>
	<p type="FlowRelationship" qname="flowsTo"/>
	<p type="InfluenceRelationship" qname="influences"/>
	<p type="RealisationRelationship" qname="realizes"/>
	<p type="SpecialisationRelationship" qname="isSpecialisationOf"/>
	<p type="TriggeringRelationship" qname="triggers"/>
	<p type="UsedByRelationship" qname="isUsedBy"/>
</xsl:variable>

<xsl:template match="archixsd:label|archixsd:name">
	<rdfs:label>
		<xsl:if test="@xml:lang!=''"><xsl:attribute name="xml:lang"><xsl:value-of select="@xml:lang"/></xsl:attribute></xsl:if>
		<xsl:choose>
			<xsl:when test=".!=''"><xsl:value-of select="."/></xsl:when>
			<xsl:otherwise><xsl:value-of select="../local-name()"/><xsl:text> </xsl:text><xsl:value-of select="../@identifier"/></xsl:otherwise>
		</xsl:choose>
	</rdfs:label>
</xsl:template>

<xsl:template match="archixsd:documentation">
	<rdfs:comment>
		<xsl:if test="@xml:lang!=''"><xsl:attribute name="xml:lang"><xsl:value-of select="@xml:lang"/></xsl:attribute></xsl:if>
		<xsl:value-of select="."/>
	</rdfs:comment>
</xsl:template>

<xsl:template match="archixsd:model">
	<archi:Model rdf:about="{$prefix}model/{@identifier}">
		<xsl:apply-templates select="archixsd:name|archixsd:documentation"/>
		<xsl:for-each select="archixsd:metadata/*">
			<xsl:element name="{name()}" namespace="http://purl.org/dc/elements/1.1/">
				<xsl:value-of select="."/>
			</xsl:element>
		</xsl:for-each>
	</archi:Model>
	<xsl:apply-templates select="archixsd:properties|archixsd:elements|archixsd:relationships|archixsd:propertydefs|archixsd:organization|archixsd:views"/>
</xsl:template>

<xsl:template match="archixsd:properties">
	<!-- TODO -->
</xsl:template>

<xsl:template match="archixsd:elements">
	<xsl:apply-templates select="archixsd:element"/>
</xsl:template>
<xsl:template match="archixsd:element">
	<xsl:element name="archi:{@xsi:type}" namespace="{$archi-namespace}">
		<xsl:attribute name="rdf:about"><xsl:value-of select="$prefix"/><xsl:value-of select="lower-case(@xsi:type)"/>/<xsl:value-of select="@identifier"/></xsl:attribute>
		<xsl:apply-templates select="archixsd:label|archixsd:documentation"/>
	</xsl:element>
</xsl:template>

<xsl:template match="archixsd:relationships">
	<xsl:apply-templates select="archixsd:relationship"/>
</xsl:template>
<xsl:template match="archixsd:relationship">
	<xsl:variable name="xsitype" select="@xsi:type"/>
	<xsl:variable name="property" select="$propertymap/p[@type=$xsitype]/@qname"/>
	<xsl:if test="$property!=''">
		<rdf:Description rdf:about="{$prefix}{lower-case(key('elements',@source)/@xsi:type)}/{@source}">
			<xsl:element name="archi:{$property}" namespace="{$archi-namespace}">
				<xsl:attribute name="rdf:resource"><xsl:value-of select="$prefix"/><xsl:value-of select="lower-case(key('elements',@target)/@xsi:type)"/>/<xsl:value-of select="@target"/></xsl:attribute>
			</xsl:element>
		</rdf:Description>
	</xsl:if>
</xsl:template>

<xsl:template match="archixsd:propertydefs">
	<!-- TODO -->
</xsl:template>

<xsl:template match="archixsd:views">
	<xsl:apply-templates select="archixsd:view"/>
</xsl:template>
<xsl:template match="archixsd:view">
	<archi:View rdf:about="{$prefix}view/{@identifier}">
		<xsl:apply-templates select="archixsd:name|archixsd:documentation"/>
		<xsl:apply-templates select="archixsd:node" mode="ref"/>
	</archi:View>
	<xsl:apply-templates select="archixsd:node"/>
</xsl:template>
<xsl:template match="archixsd:node" mode="ref">
	<archi:hasNode rdf:resource="{$prefix}node/{@identifier}"/>
	<xsl:apply-templates select="archixsd:node" mode="ref"/>
</xsl:template>

<xsl:template match="archixsd:node">
	<archi:Node rdf:about="{$prefix}node/{@identifier}">
		<archi:element rdf:resource="{$prefix}{lower-case(key('elements',@elementref)/@xsi:type)}/{@elementref}"/>
		<xsl:variable name="x" as="xs:decimal" select="xs:decimal(@x) div 4"/>
		<xsl:variable name="y" as="xs:decimal" select="xs:decimal(@y) div 4"/>
		<xsl:variable name="w" as="xs:decimal" select="xs:decimal(@w) div 4"/>
		<xsl:variable name="h" as="xs:decimal" select="xs:decimal(@h) div 4"/>
		<archi:geometry>
			<xsl:text>POLYGON((</xsl:text>
			<xsl:value-of select="$x"/><xsl:text> </xsl:text><xsl:value-of select="-$y"/><xsl:text>,</xsl:text>
			<xsl:value-of select="$x + $w"/><xsl:text> </xsl:text><xsl:value-of select="-$y"/><xsl:text>,</xsl:text>
			<xsl:value-of select="$x + $w"/><xsl:text> </xsl:text><xsl:value-of select="-$y - $h"/><xsl:text>,</xsl:text>
			<xsl:value-of select="$x"/><xsl:text> </xsl:text><xsl:value-of select="-$y - $h"/><xsl:text>,</xsl:text>
			<xsl:value-of select="$x"/><xsl:text> </xsl:text><xsl:value-of select="-$y"/>
			<xsl:text>))</xsl:text>
		</archi:geometry>
	</archi:Node>
	<xsl:apply-templates select="archixsd:node"/>
</xsl:template>

<xsl:template match="/root">
	<rdf:RDF>
		<xsl:apply-templates select="archixsd:model"/>
	</rdf:RDF>
</xsl:template>

</xsl:stylesheet>