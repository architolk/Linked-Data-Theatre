<!--

    NAME     ArchiTranslator.xsl
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
	Translates Archi source file to corresponding linked data
	The resulting RDF is the same as the ArchimateTranslator, but in this case the input is a Archi source file.
	See for the Open Source Archi tool: http://archimatetool.com
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xmi="http://schema.omg.org/spec/XMI/2.1"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:archixsd="http://www.archimatetool.com/archimate"
	xmlns:archi="http://bp4mc2.org/def/archi#"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>

<xsl:variable name="prefix">http://elmo.localhost/ldt/id/</xsl:variable>
<xsl:variable name="archi-namespace">http://bp4mc2.org/def/archi#</xsl:variable>

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

<xsl:template match="archixsd:model">
	<xsl:apply-templates select="folder"/>
</xsl:template>

<xsl:template match="folder">
	<xsl:apply-templates select="folder|element"/>
</xsl:template>

<xsl:template match="element">
	<xsl:choose>
		<xsl:when test="exists(@name)">
			<xsl:element name="archi:{substring-after(@xsi:type,'archimate:')}">
				<xsl:attribute name="rdf:about"><xsl:value-of select="$prefix"/><xsl:value-of select="@id"/></xsl:attribute>
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			</xsl:element>
		</xsl:when>
		<xsl:when test="exists(@source) and exists(@target)">
			<xsl:variable name="type" select="substring-after(@xsi:type,'archimate:')"/>
			<xsl:variable name="property" select="$propertymap/p[@type=$type]/@qname"/>
			<xsl:if test="$property!=''">
				<rdf:Description rdf:about="{$prefix}{@source}">
					<xsl:element name="archi:{$property}">
						<xsl:attribute name="rdf:resource"><xsl:value-of select="$prefix"/><xsl:value-of select="@target"/></xsl:attribute>
					</xsl:element>
				</rdf:Description>
			</xsl:if>
		</xsl:when>
		<xsl:otherwise />
	</xsl:choose>
</xsl:template>

<xsl:template match="/root">
	<rdf:RDF>
		<xsl:apply-templates select="archixsd:model"/>
	</rdf:RDF>
</xsl:template>

</xsl:stylesheet>