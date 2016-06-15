<!--

    NAME     rdf2graphml.xsl
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
	Transformation of RDF document to graphml format
	
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">

<xsl:key name="nodes" match="rdf:RDF/rdf:Description" use="@rdf:about"/>
<xsl:key name="blanks" match="rdf:RDF/rdf:Description" use="@rdf:nodeID"/>

<xsl:template match="/">
<xsl:for-each select="results/rdf:RDF[1]">
<graphml>
	<xsl:for-each-group select="rdf:Description/*" group-by="name()">
		<xsl:variable name="name" select="replace(name(),':','-')"/>
		<key id="{$name}" for="node" attr.name="{$name}" attr.type="string" />
	</xsl:for-each-group>
	<key id="uri" for="node" attr.name="uri" attr.type="string"/>
	<key id="uri" for="edge" attr.name="uri" attr.type="string"/>
	<key id="label" for="node" attr.name="label" attr.type="string"/>
	<key id="label" for="edge" attr.name="label" attr.type="string"/>
	<graph id="G" edgedefault="directed">
		<!-- Nodes -->
		<xsl:for-each select="rdf:Description">
			<node id="{@rdf:about}{@rdf:nodeID}"> <!-- URI nodes and blank nodes -->
				<xsl:variable name="slabel"><xsl:value-of select="substring-after(@rdf:about,'#')"/></xsl:variable>
				<xsl:variable name="label">
					<xsl:value-of select="rdfs:label"/>
					<xsl:if test="not(rdfs:label!='')">
						<xsl:value-of select="$slabel"/>
						<xsl:if test="$slabel=''"><xsl:value-of select="@rdf:about"/></xsl:if>
					</xsl:if>
				</xsl:variable>
				<data key="uri"><xsl:value-of select="@rdf:about"/></data>
				<data key="label"><xsl:value-of select="$label"/></data>
				<xsl:for-each select="*[not(exists(key('nodes',@rdf:resource)))]">
					<xsl:variable name="name" select="replace(name(),':','-')"/>
					<data key="{$name}"><xsl:value-of select="."/><xsl:value-of select="@rdf:resource"/></data>
				</xsl:for-each>
			</node>
		</xsl:for-each>
		<!-- Edges for URI nodes -->
		<xsl:for-each select="rdf:Description/*[exists(key('nodes',@rdf:resource))]">
			<edge source="{../@rdf:about}" target="{@rdf:resource}">-
				<data key="uri"><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></data>
				<data key="label"><xsl:value-of select="name()"/></data>
			</edge>
		</xsl:for-each>
		<!-- Edges for blank nodes -->
		<xsl:for-each select="rdf:Description/*[exists(key('blanks',@rdf:nodeID))]">
			<edge source="{../@rdf:about}" target="{@rdf:nodeID}">-
				<data key="uri"><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></data>
				<data key="label"><xsl:value-of select="name()"/></data>
			</edge>
		</xsl:for-each>
	</graph>
</graphml>
</xsl:for-each>
</xsl:template>

</xsl:stylesheet>