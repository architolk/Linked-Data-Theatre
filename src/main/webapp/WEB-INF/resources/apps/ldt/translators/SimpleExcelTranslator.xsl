<!--

    NAME     SimpleExcelTranslator.xsl
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
	Simple translator for excel files. Assumes only one excel worksheet and a header row containing the properties.
	
-->
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
>
	<xsl:key name="header" match="root/workbook/sheet[1]/row[1]/column" use="@id"/>

	<xsl:variable name="container-ns"><xsl:value-of select="root/container/url"/>#</xsl:variable>
	<xsl:variable name="container-url"><xsl:value-of select="root/container/url"/></xsl:variable>
	
	<xsl:template match="/">
		<rdf:RDF>
			<xsl:namespace name="container" select="$container-ns"/>
			<xsl:for-each select="root/workbook/sheet[1]/row[position()!=1]">
				<rdf:Description rdf:about="{$container-url}/{@id}">
					<xsl:for-each select="column">
						<xsl:element name="container:{key('header',@id)}" namespace="{$container-ns}"><xsl:value-of select="."/></xsl:element>
					</xsl:for-each>
				</rdf:Description>
			</xsl:for-each>
		</rdf:RDF>
	</xsl:template>
</xsl:stylesheet>
