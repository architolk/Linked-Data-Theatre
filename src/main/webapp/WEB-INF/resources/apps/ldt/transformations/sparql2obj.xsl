<!--

    NAME     sparql2obj.xsl
    VERSION  1.8.0
    DATE     2016-06-15

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
	Transformation of a sparql result into intermediate obj format (deprecated?)
	
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sparql="http://www.w3.org/2005/sparql-results#">

<xsl:template name="shortname">
	<xsl:param name="name"/>

	<xsl:choose>
		<xsl:when test="substring-after($name,'#')=''">

			<xsl:variable name="shortname" select="substring-after($name,'/')"/>
			
			<xsl:choose>
				<xsl:when test="$shortname=''">
					<xsl:value-of select="$name"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="shortname"><xsl:with-param name="name" select="$shortname"/></xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="substring-after($name,'#')"/>
		</xsl:otherwise>
	</xsl:choose>
	
</xsl:template>

<xsl:template match="/">
<xsl:for-each select="sparql:sparql/sparql:results">

	<Objects>

		<xsl:for-each-group select="sparql:result" group-by="sparql:binding[@name='s']/sparql:uri">
			<xsl:variable name="shortname"><xsl:call-template name="shortname"><xsl:with-param name="name"><xsl:value-of select="sparql:binding[@name='s']/sparql:uri"/></xsl:with-param></xsl:call-template></xsl:variable>
			<Object about="{sparql:binding[@name='s']/sparql:uri}" label="{sparql:binding[@name='s_label']/sparql:literal}" name="{$shortname}">
				<xsl:for-each select="current-group()">
					<Property predicate="{sparql:binding[@name='p']/sparql:uri}">
						<xsl:value-of select="sparql:binding[@name='o']/sparql:uri"/>
						<xsl:value-of select="sparql:binding[@name='o']/sparql:literal"/>
					</Property>
				</xsl:for-each>
			</Object>
		</xsl:for-each-group>
	
	</Objects>
	
</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
	
