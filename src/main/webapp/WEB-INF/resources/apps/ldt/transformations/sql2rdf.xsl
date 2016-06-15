<!--

    NAME     sql2rdf.xsl
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
	Transformation of SQL result to RDF (using same convention as with SPARQL SELECT results)
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:sparql="http://www.w3.org/2005/sparql-results#"
>

<xsl:key name="metadata" match="/root/sparql:sparql/sparql:results/sparql:result" use="sparql:binding[@name='uri']/sparql:uri"/>

<xsl:template match="/">
	<xsl:for-each select="root/sqldata/rows">
		<rdf:RDF>
			<rdf:Description rdf:nodeID="rset">
				<rdf:type rdf:resource="http://www.w3.org/2005/sparql-results#ResultSet"/>
				<xsl:for-each-group select="row/column" group-by="@name">
					<res:resultVariable><xsl:value-of select="@name"/></res:resultVariable>
				</xsl:for-each-group>
				<xsl:for-each select="row">
					<xsl:variable name="rindex" select="position()"/>
					<res:solution rdf:nodeID="r{$rindex}">
						<!-- data -->
						<xsl:for-each select="column">
							<res:binding rdf:nodeID="r{$rindex}c{position()}">
								<res:variable><xsl:value-of select="@name"/></res:variable>
								<res:value>
									<xsl:choose>
										<xsl:when test="@type='uri'"><xsl:attribute name="rdf:resource"><xsl:value-of select="."/></xsl:attribute></xsl:when>
										<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
									</xsl:choose>
								</res:value>
							</res:binding>
						</xsl:for-each>
						<!-- metadata -->
						<xsl:for-each select="key('metadata',column[@name='_uri'])/sparql:binding[@name!='uri']">
							<res:binding rdf:nodeID="r{$rindex}m{position()}">
								<res:variable><xsl:value-of select="@name"/></res:variable>
								<res:value>
									<xsl:if test="exists(sparql:uri)"><xsl:attribute name="rdf:resource"><xsl:value-of select="sparql:uri"/></xsl:attribute></xsl:if>
									<xsl:value-of select="sparql:literal"/>
								</res:value>
							</res:binding>
						</xsl:for-each>
					</res:solution>
				</xsl:for-each>
			</rdf:Description>
		</rdf:RDF>
	</xsl:for-each>
</xsl:template>

</xsl:stylesheet>