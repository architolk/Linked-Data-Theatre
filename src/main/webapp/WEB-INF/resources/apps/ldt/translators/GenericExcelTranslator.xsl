<!--

    NAME     GenericExcelTranslator.xsl
    VERSION  1.5.0
    DATE     2016-01-05

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
	Generic translator for excel files. Translates an excel file to a SPARQL result set
	
-->
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
>
	<xsl:template match="/">
		<xsl:for-each select="root/workbook">
			<rdf:Description rdf:nodeID="rset" xmlns:res="http://www.w3.org/2005/sparql-results#">
				<rdf:type rdf:resource="http://www.w3.org/2005/sparql-results#ResultSet"/>
				<res:resultVariable>s</res:resultVariable>
				<res:resultVariable>r</res:resultVariable>
				<xsl:for-each-group select="sheet/row/column" group-by="@id">
					<res:resultVariable>c<xsl:value-of select="@id"/></res:resultVariable>
				</xsl:for-each-group>
				<xsl:for-each select="sheet/row">
					<res:solution rdf:nodeID="r{@id}">
						<res:binding rdf:nodeID="r{@id}c">
							<res:variable>s</res:variable>
							<res:value><xsl:value-of select="../@name"/></res:value>
						</res:binding>
						<res:binding rdf:nodeID="r{@id}c">
							<res:variable>r</res:variable>
							<res:value><xsl:value-of select="@id"/></res:value>
						</res:binding>
						<xsl:for-each select="column">
							<res:binding rdf:nodeID="r{../@id}c{@id}">
								<res:variable>c<xsl:value-of select="@id"/></res:variable>
								<res:value><xsl:value-of select="."/></res:value>
							</res:binding>
						</xsl:for-each>
					</res:solution>
				</xsl:for-each>
			</rdf:Description>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
