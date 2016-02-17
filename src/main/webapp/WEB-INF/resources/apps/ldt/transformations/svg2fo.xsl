<!--

    NAME     svg2fo.xsl
    VERSION  1.5.2-SNAPSHOT
    DATE     2016-02-17

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
			xmlns:xhtml="http://www.w3.org/1999/xhtml"
>

<xsl:key name="nodes" match="data/nodes/node" use="@id"/>

<xsl:template match="/root">
<xsl:variable name="imgwidth" select="/root/request/parameters/parameter[name='imgwidth']/value"/>
<xsl:variable name="imgheight" select="/root/request/parameters/parameter[name='imgheight']/value"/>
<xsl:variable name="imgsrc" select="/root/request/parameters/parameter[name='imgsrc']/value"/>
<xsl:for-each select="xhtml:div/svg:svg">
	<fo:root>
		<fo:layout-master-set>
			<fo:simple-page-master	master-name="simple"
									page-height="{$imgheight}px"
									page-width="{$imgwidth}px"
									margin-top="0px"
									margin-bottom="0px"
									margin-left="0px"
									margin-right="0px">
				<fo:region-body margin-top="0px"/>
				<fo:region-before extent="3cm"/>
				<fo:region-after extent="1.5cm"/>
			</fo:simple-page-master>
		</fo:layout-master-set>
		<fo:page-sequence master-reference="simple">
			<fo:flow flow-name="xsl-region-body">
				<xsl:variable name="imgleft"><xsl:value-of select="substring-before(substring-after(../xhtml:img/@style,'left: '),'px;')"/></xsl:variable>
				<xsl:variable name="imgtop"><xsl:value-of select="substring-before(substring-after(../xhtml:img/@style,'top: '),'px;')"/></xsl:variable>
				<xsl:variable name="svgleft"><xsl:value-of select="substring-before(substring-after(@style,'left: '),'px;')"/></xsl:variable>
				<xsl:variable name="svgtop"><xsl:value-of select="substring-before(substring-after(@style,'top: '),'px;')"/></xsl:variable>
				<fo:block-container space-before.optimum="3pt" space-after.optimum="20pt" absolute-position="fixed" top="0" left="0">
					<fo:block>
						<fo:external-graphic src="{$imgsrc}" content-width="{$imgwidth}px" content-height="{$imgheight}px"/>
					</fo:block>
				</fo:block-container>
				<!-- Hier wordt het niet slechter van, maar ook niet beter -->
				<!-- Was: top="0", left="0" -->
				<fo:block-container space-before.optimum="3pt" space-after.optimum="20pt" absolute-position="fixed" top="{$svgtop - $imgtop}" left="{$svgleft - $imgleft}">
					<fo:block>
						<fo:instream-foreign-object content-width="{$imgwidth}" content-height="{$imgheight}">
							<svg:svg width="{$imgwidth}" height="{$imgheight}">
								<svg:g>
									<xsl:copy-of select="svg:g/*"/>
									<!--
									<xsl:for-each select="/root/xhtml:div/xhtml:div">
										<xsl:variable name="left"><xsl:value-of select="substring-before(substring-after(@style,'left: '),'px; ')"/></xsl:variable>
										<xsl:variable name="top"><xsl:value-of select="substring-before(substring-after(@style,'top: '),'px; ')"/></xsl:variable>
										<svg:text x="{18+$left}px" y="{-18+$top}px" fill="black" font-size="14">
											<xsl:for-each select="tokenize(replace(concat(normalize-space(.),' '),'(.{0,10}) ','$1&#xA;'),'&#xA;')">
												<svg:tspan x="{18+$left}px" dy="16px"><xsl:value-of select="."/></svg:tspan>
											</xsl:for-each>
										</svg:text>
									</xsl:for-each>
									-->
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

</xsl:stylesheet>