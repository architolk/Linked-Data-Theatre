<!--

    NAME     sparql2rdfaform.xsl
    VERSION  1.20.0
    DATE     2018-01-12

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
    Transforms container content (turtle format) to rdfa for presentation in the UI (and further processing by container.xpl pipeline and rdfa2html.xsl)
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:geosparql="http://www.opengis.net/ont/geosparql#"
>

<xsl:template match="rdf:RDF">
	<xsl:variable name="appearance">
		<xsl:choose>
			<xsl:when test="count(rdf:Description)&gt;1">Table</xsl:when>
			<xsl:otherwise>Content</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#{$appearance}Appearance">
		<xsl:for-each select="rdf:Description">
			<rdf:Description>
				<xsl:copy-of select="@*"/>
				<xsl:copy-of select="* except (geosparql:asWKT|geo:geometry|*[@rdf:datatype='http://www.opengis.net/ont/geosparql#wktLiteral'])"/>
			</rdf:Description>
		</xsl:for-each>
	</rdf:RDF>
	<xsl:if test="exists(*/geosparql:asWKT|*/geo:geometry|*/*[@rdf:datatype='http://www.opengis.net/ont/geosparql#wktLiteral'])">
		<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#GeoAppearance">
			<xsl:for-each select="rdf:Description[exists(geosparql:asWKT|geo:geometry|*[@rdf:datatype='http://www.opengis.net/ont/geosparql#wktLiteral']) and @rdf:about!='']">
				<rdf:Description rdf:about="{@rdf:about}">
					<rdfs:label><xsl:value-of select="rdfs:label"/></rdfs:label>
					<geo:geometry><xsl:value-of select="geosparql:asWKT|geo:geometry|*[@rdf:datatype='http://www.opengis.net/ont/geosparql#wktLiteral']"/></geo:geometry>
				</rdf:Description>
			</xsl:for-each>
		</rdf:RDF>
	</xsl:if>
</xsl:template>

<xsl:template match="res:sparql">
	<xsl:variable name="geo-datatype-item"><xsl:value-of select="res:results/res:result[1]/res:binding[res:literal/@datatype='http://www.opengis.net/ont/geosparql#wktLiteral'][1]/@name"/>
	</xsl:variable>
	<xsl:variable name="geo-item">
		<xsl:for-each select="res:head/res:variable">
			<xsl:variable name="geoname"><xsl:value-of select="@name"/>_geo</xsl:variable>
			<xsl:if test="exists(../res:variable[@name=$geoname])">
				<item obj="{@name}" geo="{$geoname}"/>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="$geo-datatype-item!=''">
			<item obj="" geo="{$geo-datatype-item}"/>
		</xsl:if>
	</xsl:variable>
	<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#TableAppearance">
		<rdf:Description rdf:nodeID="rset">
			<rdf:type rdf:resource="http://www.w3.org/2005/sparql-results#ResultSet"/>
			<xsl:for-each select="res:head/res:variable">
				<res:resultVariable><xsl:value-of select="@name"/></res:resultVariable>
			</xsl:for-each>
			<xsl:for-each select="res:results/res:result">
				<xsl:variable name="row" select="position()-1"/>
				<res:solution rdf:nodeID="r{$row}">
					<xsl:for-each select="res:binding">
						<xsl:variable name="column" select="position()-1"/>
						<xsl:variable name="varname" select="@name"/>
						<res:binding rdf:nodeID="r{$row}c{$column}">
							<res:variable><xsl:value-of select="$varname"/></res:variable>
							<res:value>
								<xsl:choose>
									<xsl:when test="exists($geo-item/item[@geo=$varname])">GEO</xsl:when>
									<xsl:when test="exists(res:uri)"><xsl:attribute name="rdf:resource"><xsl:value-of select="res:uri"/></xsl:attribute></xsl:when>
									<xsl:when test="exists(res:literal)"><xsl:attribute name="datatype"><xsl:value-of select="res:literal/@datatype"/></xsl:attribute><xsl:value-of select="res:literal"/></xsl:when>
									<xsl:otherwise />
								</xsl:choose>
							</res:value>
						</res:binding>
					</xsl:for-each>
				</res:solution>
			</xsl:for-each>
		</rdf:Description>
	</rdf:RDF>
	<!-- Voorlopig maar 1 geo-item toestaan, in principe zou meer ook prima kunnen op dezelfde manier -->
	<xsl:if test="exists($geo-item/item[1])">
		<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#GeoAppearance">
			<xsl:for-each select="res:results/res:result">
				<xsl:if test="exists(res:binding[@name=$geo-item/item[1]/@geo])">
					<xsl:variable name="uri"><xsl:value-of select="res:binding[@name=$geo-item/item[1]/@obj]/res:uri"/></xsl:variable>
					<xsl:variable name="uri-safe">
						<xsl:value-of select="$uri"/>
						<xsl:if test="$uri=''">urn:pos<xsl:value-of select="position()"/></xsl:if>
					</xsl:variable>
					<rdf:Description rdf:about="{$uri-safe}">
						<xsl:variable name="varlabel"><xsl:value-of select="$geo-item/item[1]/@obj"/>_label</xsl:variable>
						<xsl:variable name="label"><xsl:value-of select="res:binding[@name=$varlabel]/res:literal"/></xsl:variable>
						<rdfs:label>
							<xsl:choose>
								<xsl:when test="$label!=''"><xsl:value-of select="$label"/></xsl:when>
								<xsl:otherwise>GEO</xsl:otherwise>
							</xsl:choose>
						</rdfs:label>
						<geo:geometry><xsl:value-of select="res:binding[@name=$geo-item/item[1]/@geo]/res:literal"/></geo:geometry>
					</rdf:Description>
				</xsl:if>
			</xsl:for-each>
		</rdf:RDF>
	</xsl:if>
</xsl:template>

<xsl:template match="/">
	<results>
		<xsl:copy-of select="root/context"/>
		<xsl:copy-of select="root/representation/(rdf:RDF except rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#FormAppearance'])"/>
		<rdf:RDF elmo:appearance="http://bp4mc2.org/elmo/def#FormAppearance">
			<xsl:copy-of select="root/representation/rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#FormAppearance']/rdf:Description[@rdf:nodeID='form']"/>
			<xsl:if test="exists(root/parameters/error)">
				<rdf:Description rdf:nodeID="error">
					<xsl:copy-of select="root/representation/rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#FormAppearance']/rdf:Description[@rdf:nodeID='error']/*"/>
					<elmo:applies-to>error</elmo:applies-to>
					<rdf:value><xsl:value-of select="root/parameters/error"/></rdf:value>
					<elmo:appearance rdf:resource="http://bp4mc2.org/elmo/def#Message"/>
				</rdf:Description>
			</xsl:if>
			<xsl:if test="exists(root/queries/rdf:RDF/rdf:Description)">
				<rdf:Description rdf:nodeID="queries">
					<xsl:copy-of select="root/representation/rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#FormAppearance']/rdf:Description[@rdf:nodeID='queries']/*"/>
					<elmo:applies-to>select</elmo:applies-to>
					<elmo:valuesFrom rdf:resource="http://bp4mc2.org/elmo/def#Queries"/>
					<elmo:value-to>query</elmo:value-to>
				</rdf:Description>
			</xsl:if>
			<rdf:Description rdf:nodeID="query">
				<xsl:copy-of select="root/representation/rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#FormAppearance']/rdf:Description[@rdf:nodeID='query']/*"/>
				<elmo:applies-to>query</elmo:applies-to>
				<elmo:valueDatatype rdf:resource="http://www.w3.org/2001/XMLSchema#String"/>
				<elmo:appearance rdf:resource="http://bp4mc2.org/elmo/def#SparqlEditor"/>
				<rdf:value><xsl:value-of select="root/context/parameters/parameter[name='query']/value"/></rdf:value>
			</rdf:Description>
			<xsl:if test="root/representation/rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#FormAppearance']/rdf:Description[@rdf:nodeID='format']/elmo:valuesFrom/@rdf:resource!=''">
				<rdf:Description rdf:nodeID="format">
					<xsl:copy-of select="root/representation/rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#FormAppearance']/rdf:Description[@rdf:nodeID='format']/*"/>
					<elmo:applies-to>format</elmo:applies-to>
				</rdf:Description>
			</xsl:if>
			<rdf:Description rdf:nodeID="button">
				<xsl:copy-of select="root/representation/rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#FormAppearance']/rdf:Description[@rdf:nodeID='button']/*"/>
				<elmo:appearance rdf:resource="http://bp4mc2.org/elmo/def#SubmitAppearance"/>
				<html:link><xsl:value-of select="root/context/@docroot"/><xsl:value-of select="root/context/subdomain"/>/sparql</html:link>
			</rdf:Description>
		</rdf:RDF>
		<rdf:RDF elmo:query="http://bp4mc2.org/elmo/def#Queries" elmo:appearance="http://bp4mc2.org/elmo/def#HiddenAppearance">
			<xsl:copy-of select="root/queries/rdf:RDF/*"/>
		</rdf:RDF>
		<xsl:apply-templates select="root/rdf:RDF|root/res:sparql"/>
	</results>
</xsl:template>

</xsl:stylesheet>