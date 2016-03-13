<!--

    NAME     rdf2xls.xsl
    VERSION  1.6.0
    DATE     2016-03-13

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
	Transformation of rDF document to xlsx, using ExcelSerializer
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
>

<xsl:template match="/">
	<xsl:choose>
		<xsl:when test="exists(results/rdf:RDF[1]/rdf:Description/@rdf:about)">
			<xsl:apply-templates select="results/rdf:RDF[1]" mode="construct"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="results/rdf:RDF[1]" mode="select"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Select query -->
<xsl:template match="rdf:RDF" mode="select">
	<xsl:for-each select="rdf:Description[1]">
		<workbook>
			<sheet name="result">
				<row>
					<xsl:for-each select="res:resultVariable[substring-after(.,'_')!='label']">
						<column><xsl:value-of select="."/></column>
					</xsl:for-each>
				</row>
				<xsl:for-each select="res:solution">
					<row>
						<xsl:variable name="binding" select="res:binding"/>
						<xsl:for-each select="../res:resultVariable[substring-after(.,'_')!='label']">
							<xsl:variable name="var" select="."/>
							<xsl:variable name="label"><xsl:value-of select="$binding[res:variable=concat($var,'_label')]/res:value"/></xsl:variable>
							<column>
								<xsl:variable name="value" select="$binding[res:variable=$var]"/>
								<xsl:choose>
									<xsl:when test="$value/res:value!=''"><xsl:value-of select="$value/res:value"/></xsl:when>
									<xsl:when test="$value/res:value/@rdf:resource!=''">
										<xsl:attribute name="hyperlink"><xsl:value-of select="$value/res:value/@rdf:resource"/></xsl:attribute>
										<xsl:value-of select="$label"/>
										<xsl:if test="$label=''"><xsl:value-of select="$value/res:value/@rdf:resource"/></xsl:if>
									</xsl:when>
									<xsl:otherwise></xsl:otherwise>
								</xsl:choose>
								<!-- <xsl:value-of select="$binding[res:variable=$var]/res:value/@rdf:resource"/><xsl:value-of select="$binding[res:variable=$var]/res:value"/> -->
							</column>
						</xsl:for-each>
					</row>
				</xsl:for-each>
			</sheet>
		</workbook>
	</xsl:for-each>
</xsl:template>

<!-- Construct query -->
<xsl:template match="rdf:RDF" mode="construct">
	<!-- Create the correct sheet names for every resource -->
	<xsl:variable name="resources">
		<xsl:for-each-group select="rdf:Description" group-by="@rdf:about">
			<xsl:variable name="rdfs-label"><xsl:value-of select="substring(tokenize(replace(rdfs:label[1],'[^a-zA-Z0-9/\._-]',''),'/')[position()=last()],1,30)"/></xsl:variable>
			<xsl:variable name="uri-label">
				<xsl:value-of select="$rdfs-label"/>
				<xsl:if test="$rdfs-label=''"><xsl:value-of select="substring(tokenize(replace(@rdf:about,'[^a-zA-Z0-9/\._-]',''),'/')[position()=last()],1,30)"/></xsl:if>
			</xsl:variable>
			<xsl:variable name="label"><xsl:value-of select="normalize-space($uri-label)"/></xsl:variable>
			<xsl:element name="resource">
				<xsl:attribute name="uri"><xsl:value-of select="@rdf:about"/></xsl:attribute>
				<xsl:attribute name="label">
					<xsl:value-of select="$label"/>
					<xsl:if test="$label=''">item</xsl:if>
				</xsl:attribute>
			</xsl:element>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- Duplicate names should be postfixed with a number to make them unique -->
	<xsl:variable name="labels">
		<xsl:for-each-group select="$resources/resource" group-by="@label">
			<xsl:variable name="count" select="count(current-group())"/>
			<xsl:for-each select="current-group()">
				<xsl:element name="label">
					<xsl:attribute name="uri"><xsl:value-of select="@uri"/></xsl:attribute>
					<xsl:attribute name="label">
						<xsl:choose>
							<xsl:when test="$count=1"><xsl:value-of select="@label"/></xsl:when>
							<xsl:otherwise><xsl:value-of select="substring(@label,1,25)"/><xsl:value-of select="position()"/></xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
				</xsl:element>
			</xsl:for-each>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- Make the XML excel file -->
	<workbook>
		<xsl:for-each-group select="rdf:Description" group-by="@rdf:about">
			<xsl:variable name="uri" select="@rdf:about"/>
			<sheet name="{$labels/label[@uri=$uri]/@label}">
				<row>
					<column>Property</column>
					<column>Language</column>
					<column>Value</column>
				</row>
				<row>
					<column>URI></column>
					<column/>
					<column><xsl:value-of select="@rdf:about"/></column>
				</row>
				<xsl:for-each select="current-group()/*">
					<row>
						<column><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></column>
						<column><xsl:value-of select="xsl:lang"/></column>
						<column><xsl:value-of select="."/><xsl:value-of select="@rdf:resource"/></column>
					</row>
				</xsl:for-each>
			</sheet>
		</xsl:for-each-group>
	</workbook>
</xsl:template>

</xsl:stylesheet>