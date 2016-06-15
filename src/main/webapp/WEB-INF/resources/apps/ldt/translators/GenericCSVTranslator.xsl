<!--

    NAME     GenericCSVTranslator.xsl
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
	Generic translator for csv files.
	Translates a csv file to the W3C recommendation for tabular data on the web (http://www.w3.org/TR/csv2rdf)
	
-->
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:csvw="http://www.w3.org/ns/csvw#"
>
	<xsl:template match="/">
		<rdf:RDF>
			<xsl:variable name="container" select="replace(/root/container/url,'container','id')"/>
			<xsl:variable name="containerdef" select="replace(/root/container/url,'container','def')"/>
			<xsl:variable name="csvname" select="replace(/root/file/@name,'(.*)\.[^\.]+$','$1')"/>
			<xsl:namespace name="container"><xsl:value-of select="$container"/>/</xsl:namespace>
			<xsl:namespace name="containerdef"><xsl:value-of select="$containerdef"/>#</xsl:namespace>
			<xsl:for-each select="/root/csv">
				<csvw:TableGroup rdf:about="{$container}/{$csvname}/csv">
					<csvw:table>
						<csvw:Table rdf:about="{$container}/{$csvname}/table">
							<csvw:url><xsl:value-of select="/root/file/@name"/></csvw:url>
							<rdfs:label><xsl:value-of select="$csvname"/></rdfs:label>
							<xsl:for-each select="row">
								<xsl:variable name="pos" select="position()"/>
								<csvw:row>
									<csvw:Row rdf:about="{$container}/{$csvname}/r{$pos}">
										<csvw:rownum><xsl:value-of select="$pos"/></csvw:rownum>
										<rdfs:label>#<xsl:value-of select="$pos"/></rdfs:label>
										<csvw:describes>
											<rdf:Description rdf:about="{$container}/{$csvname}/r{$pos}s">
												<xsl:for-each select="column">
													<xsl:if test=".!=''">
														<xsl:element name="{@name}" namespace="{$containerdef}#"><xsl:value-of select="."/></xsl:element>
													</xsl:if>
												</xsl:for-each>
											</rdf:Description>
										</csvw:describes>
									</csvw:Row>
								</csvw:row>
							</xsl:for-each>
						</csvw:Table>
					</csvw:table>
				</csvw:TableGroup>
			</xsl:for-each>
		</rdf:RDF>
	</xsl:template>
</xsl:stylesheet>
