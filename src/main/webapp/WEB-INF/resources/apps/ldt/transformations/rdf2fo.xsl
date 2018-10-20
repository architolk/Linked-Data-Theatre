<!--

    NAME     rdf2fo.xsl
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
    Transformation of SVG format to FO format, used to convert SVG to PDF or PNG using XML-FO processor
	
-->
<xsl:stylesheet version="2.0"
			xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
			xmlns:sparql="http://www.w3.org/2005/sparql-results#" 
			xmlns:error="http://apache.org/cocoon/sparql/1.0" 
			xmlns:svg="http://www.w3.org/2000/svg" 
			xmlns:fo="http://www.w3.org/1999/XSL/Format"
			xmlns:xs="http://www.w3.org/2001/XMLSchema"
		  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
			xmlns:xhtml="http://www.w3.org/1999/xhtml"
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

<xsl:template match="rdf:RDF" mode="select">
	<fo:root>
		<fo:layout-master-set>
			<fo:simple-page-master	master-name="simple"
									margin-top="2cm"
									margin-bottom="2cm"
									margin-left="2cm"
									margin-right="2cm"
									page-width="21cm"
									page-height="29.7cm">
				<fo:region-body margin-top="1cm"/>
				<fo:region-before extent="3cm"/>
				<fo:region-after extent="1.5cm"/>
			</fo:simple-page-master>
		</fo:layout-master-set>
		<fo:page-sequence master-reference="simple">
			<fo:flow flow-name="xsl-region-body">
				<fo:block font-size="10pt" font-family="Helvetica" space-after.optimum="10pt">
					<xsl:for-each select="rdf:Description[1]">
						<fo:table>
							<fo:table-body>
								<fo:table-row>
									<xsl:for-each select="res:resultVariable">
										<fo:table-cell><fo:block><xsl:value-of select="."/></fo:block></fo:table-cell>
									</xsl:for-each>
								</fo:table-row>
								<xsl:for-each select="res:solution">
									<fo:table-row>
										<xsl:variable name="binding" select="res:binding"/>
										<xsl:for-each select="../res:resultVariable">
											<xsl:variable name="var" select="."/>
											<fo:table-cell><fo:block>
												<xsl:variable name="value" select="$binding[res:variable=$var]"/>
												<xsl:choose>
													<xsl:when test="$value/res:value!=''"><xsl:value-of select="$value/res:value"/></xsl:when>
													<xsl:when test="$value/res:value/@rdf:resource!=''"><xsl:value-of select="$value/res:value/@rdf:resource"/></xsl:when>
													<xsl:otherwise></xsl:otherwise>
												</xsl:choose>
											</fo:block></fo:table-cell>
										</xsl:for-each>
									</fo:table-row>
								</xsl:for-each>
							</fo:table-body>
						</fo:table>
					</xsl:for-each>
				</fo:block>
			</fo:flow>
		</fo:page-sequence>
	</fo:root>
</xsl:template>

<xsl:template match="rdf:RDF" mode="construct">
	<fo:root>
		<fo:layout-master-set>
			<fo:simple-page-master	master-name="simple"
									margin-top="2cm"
									margin-bottom="2cm"
									margin-left="2cm"
									margin-right="2cm"
									page-width="21cm"
									page-height="29.7cm">
				<fo:region-body margin-top="1cm"/>
				<fo:region-before extent="3cm"/>
				<fo:region-after extent="1.5cm"/>
			</fo:simple-page-master>
		</fo:layout-master-set>
		<fo:page-sequence master-reference="simple">
			<fo:flow flow-name="xsl-region-body">
				<fo:block font-size="12pt" font-family="Helvetica" space-after.optimum="12pt">Construct query not supported</fo:block>
			</fo:flow>
		</fo:page-sequence>
	</fo:root>
</xsl:template>

</xsl:stylesheet>