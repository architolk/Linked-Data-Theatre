<!--

    NAME     rdf2config.xsl
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
    Extracts the config for morph-rdb from the rdf
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:morph="http://bp4mc2.org/morph/def#"
>

<xsl:key name="bnode" match="/rdf:RDF/rdf:Description" use="@rdf:nodeID"/>
<xsl:key name="node" match="/rdf:RDF/rdf:Description" use="@rdf:about"/>

<xsl:template match="rdf:Description" mode="database">
	<config>
		<database><xsl:value-of select="morph:database"/></database>
		<url><xsl:value-of select="morph:url"/></url>
		<user><xsl:value-of select="morph:username"/></user>
		<password><xsl:value-of select="morph:password"/></password>
		<uriEncode><xsl:value-of select="morph:uri-encode"/></uriEncode>
		<uriTransform><xsl:value-of select="morph:uri-transform"/></uriTransform>
		<xsl:choose>
			<xsl:when test="rdf:type/@rdf:resource='http://bp4mc2.org/morph/def#ProgresqlDatabase'">
				<driver>org.postgresql.Driver</driver>
				<type>postgresql</type>
			</xsl:when>
			<xsl:otherwise />
		</xsl:choose>
	</config>
</xsl:template>

<xsl:template match="/">
	<results>
		<xsl:for-each select="rdf:RDF/rdf:Description[rdf:type/@rdf:resource='http://bp4mc2.org/elmo/def#Conversion'][1]">
			<conversion><xsl:value-of select="@rdf:about"/></conversion>
			<graph>
				<xsl:value-of select="elmo:replaces/@rdf:resource"/>
				<xsl:if test="not(elmo:replaces/@rdf:resource!='')"><xsl:value-of select="@rdf:about"/></xsl:if>
			</graph>
			<xsl:for-each select="elmo:database[1]">
				<xsl:choose>
					<xsl:when test="exists(@rdf:nodeID)"><xsl:apply-templates select="key('bnode',@rdf:nodeID)" mode="database"/></xsl:when>
					<xsl:when test="exists(@rdf:resource)"><xsl:apply-templates select="key('node',@rdf:resource)" mode="database"/></xsl:when>
					<xsl:otherwise />
				</xsl:choose>
			</xsl:for-each>
		</xsl:for-each>
		<xsl:copy-of select="rdf:RDF"/>
	</results>
</xsl:template>

</xsl:stylesheet>