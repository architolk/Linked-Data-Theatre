<?xml version="1.0" encoding="utf-8"?>
<!--

    NAME     merge-parameters.xsl
    VERSION  1.13.0
    DATE     2016-12-06

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
    Merges original parameters with result from API Call
  
-->

<xsl:stylesheet version="2.0" 
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:elmo="http://bp4mc2.org/elmo/def#"
				exclude-result-prefixes="elmo"
>

	<xsl:template match="/">
		<xsl:variable name="output" select="/root/representation/fragment[@applies-to='']"/>
		<xsl:choose>
			<xsl:when test="not(exists(/root/context/parameters)) and not(exists(/root/representation/fragment/elmo:path))">
				<xsl:copy-of select="/root/response/*"/>
			</xsl:when>
			<xsl:otherwise>
				<parameters>
					<xsl:copy-of select="/root/context/parameters/parameter"/>
					<xsl:for-each select="$output">
						<xsl:variable name="path" select="elmo:path"/>
						<xsl:variable name="value"><xsl:for-each select="/root/response"><xsl:value-of select="saxon:evaluate($path)" xmlns:saxon="http://saxon.sf.net/"/></xsl:for-each></xsl:variable>
						<parameter>
							<name><xsl:value-of select="elmo:name"/></name>
							<value>
								<xsl:value-of select="$value"/>
								<!-- Setting the empty value to an empty URI is a quick fix, should be better solution in query.xsl: not performing query after an empty result -->
								<xsl:if test="$value=''">http://bp4mc2.org/elmo/def#Nothing</xsl:if>
							</value>
						</parameter>
					</xsl:for-each>
				</parameters>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>