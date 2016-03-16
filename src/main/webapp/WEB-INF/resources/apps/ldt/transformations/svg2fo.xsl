<!--

    NAME     svg2fo.xsl
    VERSION  1.6.2
    DATE     2016-03-16

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
    Transformation of SVG format to FO format, used to convert SVG to PDF or PNG using XML-FO processor
	
-->
<xsl:stylesheet version="2.0"
			xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
			xmlns:sparql="http://www.w3.org/2005/sparql-results#" 
			xmlns:error="http://apache.org/cocoon/sparql/1.0" 
			xmlns:svg="http://www.w3.org/2000/svg" 
			xmlns:fo="http://www.w3.org/1999/XSL/Format"
			xmlns:xs="http://www.w3.org/2001/XMLSchema"
			xmlns:xhtml="http://www.w3.org/1999/xhtml"
>

<xsl:key name="nodes" match="data/nodes/node" use="@id"/>

<xsl:template match="/root">
<xsl:variable name="dimensions" select="tokenize(/root/request/parameters/parameter[name='dimensions']/value,'\|')"/>
<!--
	1: img-left
	2: img-top
	3: svg-left
	4: svg-top
	5: img-width
	6: img-height
	7: svg-width
	8: svg-height
-->
<xsl:variable name="imgleft" select="xs:decimal($dimensions[1])" as="xs:decimal"/>
<xsl:variable name="imgtop" select="xs:decimal($dimensions[2])" as="xs:decimal"/>
<xsl:variable name="svgleft" select="xs:decimal($dimensions[3])" as="xs:decimal"/>
<xsl:variable name="svgtop" select="xs:decimal($dimensions[4])" as="xs:decimal"/>
<xsl:variable name="imgwidth" select="xs:decimal($dimensions[5])" as="xs:decimal"/>
<xsl:variable name="imgheight" select="xs:decimal($dimensions[6])" as="xs:decimal"/>
<xsl:variable name="svgwidth" select="xs:decimal($dimensions[7])" as="xs:decimal"/>
<xsl:variable name="svgheight" select="xs:decimal($dimensions[8])" as="xs:decimal"/>
<xsl:variable name="imgsrc" select="/root/request/parameters/parameter[name='imgsrc']/value"/>
<xsl:for-each select="xhtml:div/svg:svg">
	<fo:root>
		<fo:layout-master-set>
			<fo:simple-page-master	master-name="simple"
									page-height="{$imgheight}px"
									page-width="{$imgwidth}px"
									margin-top="0"
									margin-bottom="0"
									margin-left="0"
									margin-right="0">
				<fo:region-body margin-top="0"/>
				<fo:region-before extent="3cm"/>
				<fo:region-after extent="1.5cm"/>
			</fo:simple-page-master>
		</fo:layout-master-set>
		<fo:page-sequence master-reference="simple">
			<fo:flow flow-name="xsl-region-body">
				<fo:block-container space-before.optimum="3pt" space-after.optimum="20pt" absolute-position="fixed" top="0px" left="0px">
					<fo:block>
						<fo:external-graphic src="{$imgsrc}" content-width="{$imgwidth}px" content-height="{$imgheight}px"/>
					</fo:block>
				</fo:block-container>
				<fo:block-container space-before.optimum="3pt" space-after.optimum="20pt" absolute-position="fixed" top="{-$imgtop}px" left="{-$imgleft}px">
					<fo:block>
						<fo:instream-foreign-object content-width="{$svgwidth}px" content-height="{$svgheight}px">
							<svg:svg width="{$svgwidth}px" height="{$svgheight}px">
								<svg:g>
									<xsl:for-each select="svg:g">
										<xsl:apply-templates select="*" mode="svg"/>
									</xsl:for-each>
								</svg:g>
							</svg:svg>
						</fo:instream-foreign-object>
					</fo:block>
				</fo:block-container>
			</fo:flow>
		</fo:page-sequence>
	</fo:root>
</xsl:for-each>
</xsl:template>

<xsl:template match="svg:path" mode="svg">
	<xsl:if test="@class!='shidden-object leaflet-clickable'">
		<svg:path fill="{@fill}" marker-end="{@marker-end}" stroke="{@stroke}" stroke-linecap="round" stroke-linejoin="round" stroke-opacity="0.5" stroke-width="1" d="{@d}"/>
	</xsl:if>
</xsl:template>

<xsl:template match="svg:text" mode="svg">
	<xsl:copy-of select="."/>
</xsl:template>

<xsl:template match="svg:marker" mode="svg">
	<xsl:copy-of select="."/>
</xsl:template>


</xsl:stylesheet>