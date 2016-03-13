<!--

    NAME     csv2xml.xsl
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
    Transformation of CSV document to a generic xml format
	(at this moment: it's not a comma, but a semicolon...)
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"

	xmlns:fn="fn" exclude-result-prefixes="xs fn"
>

<xsl:function name="fn:getTokens" as="xs:string+">
	<xsl:param name="str" as="xs:string"/>
	<xsl:analyze-string select="concat(replace($str,'&#xD;',''), ';')" regex='(("[^"]*")+|[^;]*);'>
		<xsl:matching-substring>
			<xsl:sequence select='replace(regex-group(1), "^""|""$|("")""", "$1")'/>
		</xsl:matching-substring>
	</xsl:analyze-string>
</xsl:function>

<xsl:template match="/">
	<xsl:variable name="lines" select="tokenize(document,'&#xa;')" as="xs:string+"/>
	<xsl:variable name="itemNames" select="fn:getTokens($lines[1])" as="xs:string+"/>
	<csv>
		<xsl:for-each select="$lines[position() &gt; 1]">
			<xsl:variable name="lineItems" select="fn:getTokens(.)" as="xs:string+"/>
			<row>
				<xsl:for-each select="$itemNames">
					<xsl:variable name="pos" select="position()"/>
					<column name="{.}"><xsl:value-of select="$lineItems[$pos]"/></column>
				</xsl:for-each>
			</row>
		</xsl:for-each>
	</csv>
</xsl:template>

</xsl:stylesheet>