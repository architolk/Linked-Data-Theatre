<!--

    NAME     GenericExcelTranslator.xsl
    VERSION  1.25.0
    DATE     2020-07-19

    Copyright 2012-2020

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
	Generic translator for excel files.
	Translates a excel file to the W3C recommendation for tabular data on the web (http://www.w3.org/TR/csv2rdf)

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:csvw="http://www.w3.org/ns/csvw#"
  xmlns:owl="http://www.w3.org/2002/07/owl#"

	xmlns:fn="fn" exclude-result-prefixes="fn"
>

	<xsl:function name="fn:qname">
		<xsl:param name="name"/>
		<xsl:param name="alt"/>

		<xsl:variable name="uname">
			<xsl:choose>
				<xsl:when test="$name!=''"><xsl:value-of select="$name"/></xsl:when>
				<xsl:when test="$alt!=''"><xsl:value-of select="$alt"/></xsl:when>
				<xsl:otherwise>property</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="replace(translate($uname,' /\','_--'),'[^a-zA-Z0-9_-]','')"/>
	</xsl:function>

	<xsl:template match="/">
		<rdf:RDF>
			<xsl:variable name="container" select="/root/container/url"/>
			<xsl:namespace name="container"><xsl:value-of select="$container"/>/</xsl:namespace>
			<xsl:namespace name="containerdef"><xsl:value-of select="$container"/>#</xsl:namespace>
			<xsl:for-each select="root/workbook">
				<csvw:TableGroup rdf:about="{$container}/workbook">
					<xsl:for-each select="sheet">
						<xsl:variable name="sheetnr" select="position()"/>
						<csvw:table>
							<csvw:Table rdf:about="{$container}/s{fn:qname(@name,concat('',position()))}">
								<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
								<xsl:variable name="head" select="row[1]"/>
								<xsl:for-each select="row[position()&gt;1]">
									<xsl:variable name="pos" select="@id"/>
									<csvw:row>
										<csvw:Row rdf:about="{$container}/r{$sheetnr}-{$pos}">
											<csvw:rownum rdf:datatype="http://www.w3.org/2001/XMLSchema#integer"><xsl:value-of select="$pos"/></csvw:rownum>
											<csvw:describes>
												<rdf:Description rdf:about="{$container}/r{$sheetnr}-{$pos}s">
                          <owl:sameAs xmlns:uuid="java:java.util.UUID" rdf:resource="urn:uuid:{uuid:randomUUID()}"/>
													<xsl:for-each select="column">
														<xsl:variable name="id" select="@id"/>
														<xsl:if test=".!=''">
															<xsl:element name="{fn:qname($head/column[@id=$id],concat('c',$id))}" namespace="{$container}#"><xsl:value-of select="."/></xsl:element>
														</xsl:if>
													</xsl:for-each>
												</rdf:Description>
											</csvw:describes>
										</csvw:Row>
									</csvw:row>
								</xsl:for-each>
							</csvw:Table>
						</csvw:table>
					</xsl:for-each>
				</csvw:TableGroup>
			</xsl:for-each>
		</rdf:RDF>
	</xsl:template>
</xsl:stylesheet>
