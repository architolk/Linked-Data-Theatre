<!--

    NAME     header2json.xsl
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
    Transforms the regular header XML to json
  
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">

<xsl:variable name="dblquote"><xsl:text>"&#10;&#13;</xsl:text></xsl:variable>
<xsl:variable name="quote">'  </xsl:variable>

<xsl:template match="*" mode="parse">"<xsl:value-of select="local-name()"/>": <xsl:choose><xsl:when test="count(*)=0">"<xsl:value-of select="translate(.,$dblquote,$quote)"/>"</xsl:when><xsl:otherwise>{<xsl:for-each select="*"><xsl:if test="position()!=1">,
</xsl:if><xsl:apply-templates select="." mode="parse"/></xsl:for-each>}</xsl:otherwise></xsl:choose>
</xsl:template>

<xsl:template match="/">
{<xsl:apply-templates select="." mode="parse"/>}
</xsl:template>

</xsl:stylesheet>