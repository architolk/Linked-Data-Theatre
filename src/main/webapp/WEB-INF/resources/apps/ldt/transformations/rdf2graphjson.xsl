<!--

    NAME     rdf2graphjson.xsl
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
	Transformation of RDF document to json format for d3 processing
	
-->
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
>

<xsl:output method="text" encoding="utf-8" indent="yes" />

<xsl:variable name="dblquote"><xsl:text>"&#10;&#13;</xsl:text></xsl:variable>
<xsl:variable name="quote">'  </xsl:variable>

<xsl:key name="resource" match="/root/results/rdf:RDF[1]/rdf:Description" use="@rdf:about"/>

<xsl:template match="/root">
	<xsl:text>{</xsl:text>
	<xsl:apply-templates select="key('resource',context/subject)[1]"/>
	<xsl:text>}</xsl:text>
</xsl:template>

<xsl:template match="rdf:Description">
	<!-- Subject -->
	<xsl:variable name="uri"><xsl:value-of select="@rdf:about"/></xsl:variable>
	<xsl:variable name="rdfs-label"><xsl:value-of select="key('resource',$uri)/rdfs:label"/></xsl:variable>
	<xsl:variable name="label">
		<xsl:value-of select="$rdfs-label"/>
		<xsl:if test="$rdfs-label=''"><xsl:value-of select="$uri"/></xsl:if>
	</xsl:variable>
	<xsl:variable name="style"><xsl:value-of select="key('resource',$uri)/elmo:style/@rdf:resource"/></xsl:variable>
	<xsl:variable name="class"><xsl:value-of select="key('resource',$style)/elmo:name"/></xsl:variable>
	<xsl:text>"nodes":[</xsl:text>
	<xsl:text>{"@id":"</xsl:text><xsl:value-of select="$uri"/><xsl:text>"</xsl:text>
	<xsl:text>,"label":"</xsl:text><xsl:value-of select="translate($label,$dblquote,$quote)"/><xsl:text>"</xsl:text>
	<xsl:if test="$class!=''">
		<xsl:text>,"class":"</xsl:text><xsl:value-of select="$class"/><xsl:text>"</xsl:text>
	</xsl:if>
	<xsl:text>,"data":{</xsl:text>
		<xsl:for-each select="key('resource',$uri)/*[not(exists(@rdf:resource)) and local-name()!='label']">
			<xsl:if test="position()!=1">,</xsl:if>
			<xsl:text>"</xsl:text><xsl:value-of select="local-name()"/><xsl:text>":"</xsl:text>
			<xsl:value-of select="."/><xsl:text>"</xsl:text>
		</xsl:for-each>
	<xsl:text>}</xsl:text>
	<xsl:text>}</xsl:text>
	<!-- Outgoing objects --> <!-- Elmo items uitgesloten, niet zo netjes... -->
	<xsl:for-each-group select="key('resource',$uri)/*[exists(@rdf:resource) and namespace-uri()!='http://bp4mc2.org/elmo/def#']" group-by="@rdf:resource">
		<xsl:variable name="ouri"><xsl:value-of select="@rdf:resource"/></xsl:variable>
		<xsl:variable name="ordfs-label"><xsl:value-of select="key('resource',$ouri)/rdfs:label"/></xsl:variable>
		<xsl:variable name="olabel">
			<xsl:value-of select="$ordfs-label"/>
			<xsl:if test="$ordfs-label=''"><xsl:value-of select="$ouri"/></xsl:if>
		</xsl:variable>
		<xsl:variable name="ostyle"><xsl:value-of select="key('resource',$ouri)/elmo:style/@rdf:resource"/></xsl:variable>
		<xsl:variable name="oclass"><xsl:value-of select="key('resource',$ostyle)/elmo:name"/></xsl:variable>
		<xsl:text>,{"@id":"</xsl:text><xsl:value-of select="$ouri"/><xsl:text>"</xsl:text>
		<xsl:text>,"label":"</xsl:text><xsl:value-of select="translate($olabel,$dblquote,$quote)"/><xsl:text>"</xsl:text>
		<xsl:if test="$oclass!=''">
			<xsl:text>,"class":"</xsl:text><xsl:value-of select="$oclass"/><xsl:text>"</xsl:text>
		</xsl:if>
		<xsl:text>,"data":{</xsl:text>
			<xsl:for-each select="key('resource',$ouri)/*[not(exists(@rdf:resource)) and local-name()!='label']">
				<xsl:if test="position()!=1">,</xsl:if>
				<xsl:text>"</xsl:text><xsl:value-of select="local-name()"/><xsl:text>":"</xsl:text>
				<xsl:value-of select="."/><xsl:text>"</xsl:text>
			</xsl:for-each>
		<xsl:text>}</xsl:text>
		<xsl:text>}</xsl:text>
	</xsl:for-each-group>
	<!-- Incomming objects -->
	<xsl:for-each-group select="../rdf:Description[@rdf:about!=$uri and */@rdf:resource=$uri]" group-by="@rdf:about">
		<xsl:variable name="ouri"><xsl:value-of select="@rdf:about"/></xsl:variable>
		<xsl:variable name="ordfs-label"><xsl:value-of select="key('resource',$ouri)/rdfs:label"/></xsl:variable>
		<xsl:variable name="olabel">
			<xsl:value-of select="$ordfs-label"/>
			<xsl:if test="$ordfs-label=''"><xsl:value-of select="$ouri"/></xsl:if>
		</xsl:variable>
		<xsl:variable name="ostyle"><xsl:value-of select="key('resource',$ouri)/elmo:style/@rdf:resource"/></xsl:variable>
		<xsl:variable name="oclass"><xsl:value-of select="key('resource',$ostyle)/elmo:name"/></xsl:variable>
		<xsl:text>,{"@id":"</xsl:text><xsl:value-of select="$ouri"/><xsl:text>"</xsl:text>
		<xsl:text>,"label":"</xsl:text><xsl:value-of select="translate($olabel,$dblquote,$quote)"/><xsl:text>"</xsl:text>
		<xsl:if test="$oclass!=''">
			<xsl:text>,"class":"</xsl:text><xsl:value-of select="$oclass"/><xsl:text>"</xsl:text>
		</xsl:if>
		<xsl:text>,"data":{}</xsl:text>
		<xsl:text>}</xsl:text>
	</xsl:for-each-group>
	<xsl:text>]</xsl:text>
	<xsl:text>,"links":[</xsl:text>
	<!-- Outgoing links, elmo:style en blank nodes doen niet mee -->
	<xsl:for-each select="key('resource',$uri)/(*[exists(@rdf:resource)] except elmo:style)">
		<xsl:variable name="ruri"><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></xsl:variable>
		<xsl:variable name="rlabel"><xsl:value-of select="key('resource',$ruri)/rdfs:label"/></xsl:variable>
		<xsl:variable name="relatielabel">
			<xsl:value-of select="$rlabel"/>
			<xsl:if test="$rlabel=''"><xsl:value-of select="local-name()"/></xsl:if>
		</xsl:variable>
		<xsl:if test="position()!=1">,</xsl:if>
		<xsl:text>{"source":"</xsl:text><xsl:value-of select="$uri"/><xsl:text>"</xsl:text>
		<xsl:text>,"target":"</xsl:text><xsl:value-of select="@rdf:resource"/><xsl:text>"</xsl:text>
		<xsl:text>,"uri":"</xsl:text><xsl:value-of select="$ruri"/><xsl:text>"</xsl:text>
		<xsl:text>,"label":"</xsl:text><xsl:value-of select="translate($relatielabel,$dblquote,$quote)"/><xsl:text>"</xsl:text>
		<xsl:text>}</xsl:text>
	</xsl:for-each>
	<xsl:variable name="out-count" select="count(key('resource',$uri)/(*[exists(@rdf:resource)] except elmo:style))"/>
	<!-- Incomming links, blank nodes doen niet mee -->
	<xsl:for-each select="../rdf:Description[@rdf:about!=$uri]/*[@rdf:resource=$uri]">
		<xsl:variable name="ruri"><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></xsl:variable>
		<xsl:variable name="rlabel"><xsl:value-of select="key('resource',$ruri)/rdfs:label"/></xsl:variable>
		<xsl:variable name="relatielabel">
			<xsl:value-of select="$rlabel"/>
			<xsl:if test="$rlabel=''"><xsl:value-of select="local-name()"/></xsl:if>
		</xsl:variable>
		<xsl:if test="$out-count!=0 or position()!=1">,</xsl:if>
		<xsl:text>{"source":"</xsl:text><xsl:value-of select="../@rdf:about"/><xsl:text>"</xsl:text>
		<xsl:text>,"target":"</xsl:text><xsl:value-of select="@rdf:resource"/><xsl:text>"</xsl:text>
		<xsl:text>,"uri":"</xsl:text><xsl:value-of select="$ruri"/><xsl:text>"</xsl:text>
		<xsl:text>,"label":"</xsl:text><xsl:value-of select="translate($relatielabel,$dblquote,$quote)"/><xsl:text>"</xsl:text>
		<xsl:text>}</xsl:text>
	</xsl:for-each>
	<xsl:text>]</xsl:text>
</xsl:template>

</xsl:stylesheet>
