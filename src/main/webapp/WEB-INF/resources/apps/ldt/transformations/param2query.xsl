<!--

    NAME     param2query.xsl
    VERSION  1.18.1
    DATE     2017-07-03

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
    Templating: replaces @..@ in the query with the values of parameters from the URL (context)

	This stylesheet is used by query.xpl, container.xpl (for postquery and assertions) and production.xpl
	
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
	<xsl:template match="parameter" mode="replace">
		<!-- Escape characters that could be used for SPARQL insertion -->
		<!-- The solution is quite harsh: all ', ", <, > and \ are deleted -->
		<!-- A better solution could be to know if a parameter is a literal or a URI -->
		<xsl:variable name="problems">("|'|&lt;|&gt;|\\|\$)</xsl:variable>
		<xsl:variable name="value">
			<xsl:value-of select="replace(value[1],$problems,'')"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="exists(following-sibling::*[1])">
				<xsl:variable name="query"><xsl:apply-templates select="following-sibling::*[1]" mode="replace"/></xsl:variable>
				<xsl:value-of select="replace($query,concat('@',upper-case(name),'@'),$value)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="replace(/root/(scene|representation)/query,concat('@',upper-case(name),'@'),$value)"/> <!-- In case of query or production -->
				<xsl:value-of select="replace(/root/container/postquery,concat('@',upper-case(name),'@'),$value)"/> <!-- In case of container post-query -->
				<xsl:value-of select="replace(/root/assert,concat('@',upper-case(name),'@'),$value)"/> <!-- In case of assertion -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="/root">
		<parameters>
			<xsl:variable name="query1">
				<xsl:apply-templates select="/root/parameters/parameter[1]" mode="replace"/>
				<xsl:if test="not(exists(/root/parameters/parameter))">
					<xsl:value-of select="/root/(scene|representation)/query"/> <!-- In case of query or production -->
					<xsl:value-of select="/root/container/postquery"/> <!-- In case of container post-query -->
					<xsl:value-of select="/root/assert"/> <!-- In case of assertion -->
				</xsl:if>
			</xsl:variable>
			<xsl:variable name="query2" select="replace($query1,'@LANGUAGE@',/root/context/language)"/>
			<xsl:variable name="query3" select="replace($query2,'@USER@',/root/context/user)"/>
			<xsl:variable name="query4" select="replace($query3,'@CURRENTMOMENT@',string(current-dateTime()))"/>
			<xsl:variable name="query5" select="replace($query4,'@STAGE@',/root/context/back-of-stage)"/>
			<xsl:variable name="query6" select="replace($query5,'@TIMESTAMP@',/root/context/timestamp)"/>
			<xsl:variable name="query7" select="replace($query6,'@DATE@',/root/context/date)"/>
			<xsl:variable name="query8" select="replace($query7,'@DOCSUBJECT@',/root/context/docsubject)"/>
			<xsl:variable name="query9" select="replace($query8,'@IDSUBJECT@',/root/context/idsubject)"/>
			<query><xsl:value-of select="replace($query9,'@SUBJECT@',/root/context/subject)"/></query>
			<default-graph-uri />
			<error type=""/>
		</parameters>
	</xsl:template>
</xsl:stylesheet>
