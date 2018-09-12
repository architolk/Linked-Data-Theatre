<!--

    NAME     GenericodeTranslator.xsl
    VERSION  1.22.0
    DATE     2018-06-13

    Copyright 2012-2018

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
	Translates XML to a simple RDF format. Most usable for debugging purposes

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:csvw="http://www.w3.org/ns/csvw#"
	xmlns:gc="http://docs.oasis-open.org/codelist/ns/genericode/1.0/"
>
	<xsl:template match="/">
		<rdf:RDF>
			<xsl:variable name="container" select="replace(/root/container/url,'container','id')"/>
			<xsl:variable name="containerdef" select="replace(/root/container/url,'container','def')"/>
			<xsl:variable name="gcfilename" select="replace(/root/file/@name,'(.*)\.[^\.]+$','$1')"/>
			<xsl:for-each select="root/gc:CodeList">
				<xsl:variable name="gcname">
						<xsl:value-of select="Identification/ShortName"/>
						<xsl:if test="not(Identification/ShortName!='')"><xsl:value-of select="$gcfilename"/></xsl:if>
				</xsl:variable>
				<csvw:TableGroup rdf:about="{$container}{$gcname}/gc">
					<csvw:table>
						<csvw:Table rdf:about="{$container}/{$gcname}/table">
							<csvw:url>
								<xsl:value-of select="Identification/LocationUri"/>
								<xsl:if test="not(Identification/LocationUri!='')"><xsl:value-of select="/root/file/@name"/></xsl:if>
							</csvw:url>
							<rdfs:label>
								<xsl:value-of select="Identification/LongName"/>
								<xsl:if test="not(Identification/LongName!='')"><xsl:value-of select="$gcname"/></xsl:if>
							</rdfs:label>
							<xsl:for-each select="SimpleCodeList/Row">
								<xsl:variable name="pos" select="position()"/>
								<csvw:row>
									<csvw:Row rdf:about="{$container}/{$gcname}/r{$pos}">
										<csvw:rownum><xsl:value-of select="$pos"/></csvw:rownum>
										<rdfs:label>#<xsl:value-of select="$pos"/></rdfs:label>
										<csvw:describes>
											<rdf:Description rdf:about="{$container}/{$gcname}/r{$pos}s">
												<xsl:for-each select="Value">
													<xsl:if test="SimpleValue!=''">
														<xsl:element name="{@ColumnRef}" namespace="{$containerdef}#"><xsl:value-of select="SimpleValue"/></xsl:element>
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
