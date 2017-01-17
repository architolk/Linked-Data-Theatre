<!--

    NAME     context2info.xsl
    VERSION  1.14.1-SNAPSHOT
    DATE     2017-01-17

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
    Transformation of context to text format

-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">

<xsl:template match="/">
<xsl:variable name="domain"><xsl:value-of select="root/context/domain"/></xsl:variable>
<xsl:variable name="configcheck">
	<xsl:if test="not(exists(root/theatre/site[@domain=$domain]))">
		<error>[001] Non of the defined sites matches the domain of the URL (expected site-domain: <xsl:value-of select="$domain"/>)</error>
	</xsl:if>
	<xsl:if test="count(root/theatre/site[@domain=$domain])&gt;1">
		<error>[002] More than one site matches the domain of the URL (expected site domain: <xsl:value-of select="$domain"/>, found <xsl:value-of select="count(root/theatre/site[@domain=$domain])"/> sites)</error>
	</xsl:if>
	<xsl:if test="not(root/context/representation-graph/@uri!='')">
		<error>[003] Non of the defined stages matches the URL for a site at domain: <xsl:value-of select="$domain"/></error>
	</xsl:if>
	<xsl:if test="count(root/theatre/site[@backstage=$domain])&gt;1">
		<error>[004] More than one backstage site matches the domain of the URL (expected site domain: <xsl:value-of select="$domain"/>, found <xsl:value-of select="count(root/theatre/site[@domain=$domain])"/> backstages)</error>
	</xsl:if>
	<xsl:if test="count(root/theatre)!=1">
		<error>[005] No configuration found</error>
	</xsl:if>
	<xsl:if test="not(root/context/configuration-endpoint!='')">
		<error>[006] No configuration-endpoint (SPARQL endpoint for the LDT configuration) found</error>
	</xsl:if>
</xsl:variable>
<xsl:variable name="config">
	<xsl:choose>
		<xsl:when test="exists($configcheck/error)">INVALID</xsl:when>
		<xsl:otherwise>VALID</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:text>Version number:          </xsl:text><xsl:value-of select="root/context/@version"/><xsl:text>
Version timestamp:       </xsl:text><xsl:value-of select="root/context/@timestamp"/><xsl:text>
Environment:             </xsl:text><xsl:value-of select="root/context/@env"/><xsl:text>
Stage:                   </xsl:text><xsl:value-of select="root/context/representation-graph/@uri"/><xsl:text>
Docroot:                 </xsl:text><xsl:if test="not(root/context/@docroot!='')">/</xsl:if><xsl:value-of select="root/context/@docroot"/><xsl:text>
Staticroot:              </xsl:text><xsl:if test="not(root/context/@staticroot!='')">/</xsl:if><xsl:value-of select="root/context/@staticroot"/><xsl:text>
Public SPARQL endpoint:  </xsl:text><xsl:value-of select="root/context/@sparql"/><xsl:text>
Public backstage:        </xsl:text><xsl:choose><xsl:when test="root/context/back-of-stage!=''">yes</xsl:when><xsl:otherwise>no</xsl:otherwise></xsl:choose><xsl:if test="root/context/@env='dev'"><xsl:text>
Request attribute(s):    </xsl:text><xsl:for-each select="root/context/attributes/attribute"><xsl:if test="position()!=1">, </xsl:if><xsl:value-of select="./name"/><xsl:text>:</xsl:text><xsl:value-of select="./value"/></xsl:for-each></xsl:if><xsl:text>
Config:                  </xsl:text><xsl:value-of select="$config"/><xsl:if test="$config='INVALID'"><xsl:text>
Reason for invalid configuration:</xsl:text><xsl:for-each select="$configcheck/error"><xsl:text>
</xsl:text><xsl:value-of select="."/></xsl:for-each></xsl:if>
</xsl:template>

</xsl:stylesheet>
