<!--

    NAME     DMNTranslator2.xsl
    VERSION  1.17.1-SNAPSHOT
    DATE     2017-05-12

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
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:dmn="http://www.omg.org/spec/DMN/20151101/dmn.xsd"
	xmlns:dmno="http://www.omg.org/spec/DMN/20151101/dmn#"
	xmlns:uitv="http://data.digitaalstelselomgevingswet.nl/v0.6/Uitvoeringsregels"
	xmlns:content="http://data.digitaalstelselomgevingswet.nl/v0.6/Content"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"	
> 

	<xsl:include href="DMNTranslator.xsl"/>
	
	<xsl:template match="/dmn:definitions">
		<dmno:Definitions rdf:about="{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates/>
		</dmno:Definitions>
	</xsl:template>
		
	<xsl:template match="uitv:vraag|uitv:bijlage|uitv:uitvoeringsregels|uitv:uitvoeringsregel|uitv:uitvoeringsregelRef">
		<xsl:call-template name="process">
			<xsl:with-param name="namespace" select="'dmno'" />
			<xsl:with-param name="namespaceUri" select="'http://data.digitaalstelselomgevingswet.nl/v0.6/Uitvoeringsregels#'" />
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="content:content|content:html|content:htmlblok">
		<xsl:call-template name="process">
			<xsl:with-param name="namespace" select="'dmno'" />
			<xsl:with-param name="namespaceUri" select="'http://data.digitaalstelselomgevingswet.nl/v0.6/Content#'" />
		</xsl:call-template>
	</xsl:template>	
	
	<xsl:template match="uitv:conversieregelRef">
		<uitv:conversieregelRef href="#{.}" xmlns:uitv="http://data.digitaalstelselomgevingswet.nl/v0.6/Uitvoeringsregels" />
	</xsl:template> 
	
	<xsl:template match="uitv:vraagType|uitv:vraagTekst|uitv:bijlageType|uitv:eis">
		<xsl:element name="uitv:{local-name(.)}" namespace="http://data.digitaalstelselomgevingswet.nl/v0.6/Uitvoeringsregels"><xsl:value-of select="."/></xsl:element>
	</xsl:template>
	
	<xsl:template match="xhtml:p|xhtml:div">
		
	</xsl:template>

</xsl:stylesheet>
