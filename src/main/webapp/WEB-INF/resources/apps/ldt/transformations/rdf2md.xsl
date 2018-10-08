<!--

    NAME     rdf2md.xsl
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
    Transformation of RDF document to md format

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>

<xsl:key name="nested" match="rdf:Description/*[@elmo:appearance='http://bp4mc2.org/elmo/def#NestedAppearance']/rdf:Description" use="@rdf:about"/>

<xsl:variable name="language"><xsl:value-of select="/results/context/language"/></xsl:variable>

<xsl:template match="/">
	<xsl:for-each select="results/rdf:RDF[1]">
		<xsl:apply-templates select="rdf:Description/elmo:data/rdf:Description" mode="iteratelist"/>
	</xsl:for-each>
</xsl:template>

<xsl:template match="rdf:Description" mode="iteratelist">
	<xsl:param name="level">0</xsl:param>

	<xsl:if test="rdf:first/text()!=''">
		<xsl:value-of select="rdf:first/text()"/><xsl:text>

</xsl:text>
	</xsl:if>
	<xsl:variable name="firsturi" select="rdf:first/@rdf:resource"/>
	<xsl:for-each select="rdf:first/rdf:Description|/results/rdf:RDF[1]/rdf:Description[@rdf:about=$firsturi]">
		<xsl:if test="exists(elmo:md)">
			<xsl:value-of select="elmo:md"/><xsl:text>

</xsl:text>
		</xsl:if>
		<xsl:if test="html:img!=''">
			<xsl:text>![](</xsl:text><xsl:value-of select="html:img"/><xsl:text>)

</xsl:text>
		</xsl:if>
		<xsl:if test="html:heading!=''">
			<xsl:value-of select="substring('#####',1,1+$level)"/><xsl:text> </xsl:text>
			<xsl:value-of select="html:heading"/><xsl:text>

</xsl:text>
		</xsl:if>
		<xsl:if test="exists(elmo:contains)">
			<xsl:variable name="query" select="elmo:contains/@rdf:resource"/>
			<xsl:variable name="subject">
					<xsl:value-of select="elmo:subject/@rdf:resource"/>
					<xsl:value-of select="elmo:subject/rdf:Description/@rdf:about"/>
			</xsl:variable>
			<xsl:apply-templates select="/results/rdf:RDF[@elmo:query=$query]" mode="present">
					<xsl:with-param name="subject" select="$subject"/>
			</xsl:apply-templates>
		</xsl:if>
		<xsl:apply-templates select="dcterms:hasPart/rdf:Description" mode="iteratelist">
			<xsl:with-param name="level" select="$level"/>
		</xsl:apply-templates>
	</xsl:for-each>
	<xsl:apply-templates select="rdf:rest/rdf:Description" mode="iteratelist">
		<xsl:with-param name="level">
			<xsl:choose>
				<xsl:when test="exists(rdf:first/rdf:Description/html:heading)"><xsl:value-of select="1+$level"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$level"/></xsl:otherwise>
			</xsl:choose>
		</xsl:with-param>
	</xsl:apply-templates>
</xsl:template>

<!--
<xsl:template match="/">
	<xsl:for-each select="results">
		<xsl:for-each select="rdf:RDF"><xsl:sort select="@elmo:index"/>
			<xsl:apply-templates select="." mode="present"/>
		</xsl:for-each>
	</xsl:for-each>
</xsl:template>
-->

<xsl:template match="rdf:RDF" mode="present">
	<xsl:param name="subject"/>
	<xsl:choose>
		<!-- Appearances that should not be in a md serialization -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance'"/>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#HeaderAppearance'"/>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#FooterAppearance'"/>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#NavbarAppearance'"/>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#NavbarSearchAppearance'"/>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#TreeAppearance'"/>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#LoginAppearance'"/>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#CarouselAppearance'">
			<xsl:apply-templates select="." mode="CarouselAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ShortTableAppearance'">
			<xsl:apply-templates select="." mode="TableAppearance"><xsl:with-param name="paging">false</xsl:with-param></xsl:apply-templates>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#TableAppearance' or @elmo:appearance='http://bp4mc2.org/elmo/def#TextSearchAppearance'">
			<xsl:apply-templates select="." mode="TableAppearance"><xsl:with-param name="paging">true</xsl:with-param></xsl:apply-templates>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#IndexAppearance'">
			<xsl:apply-templates select="." mode="IndexAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#HtmlAppearance'">
			<xsl:apply-templates select="." mode="HtmlAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#GraphAppearance'">
			<xsl:apply-templates select="." mode="GraphAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#TextAppearance'">
			<xsl:apply-templates select="." mode="TextAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#FormAppearance'">
			<xsl:apply-templates select="." mode="FormAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#GeoAppearance' or @elmo:appearance='http://bp4mc2.org/elmo/def#GeoSelectAppearance'">
			<xsl:apply-templates select="." mode="GeoAppearance"><xsl:with-param name="backmap"><xsl:value-of select="rdf:Description[elmo:applies-to='http://bp4mc2.org/elmo/def#Appearance']/elmo:backmap[1]"/></xsl:with-param><xsl:with-param name="appearance" select="substring-after(@elmo:appearance,'http://bp4mc2.org/elmo/def#')"/></xsl:apply-templates>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ImageAppearance'">
			<xsl:apply-templates select="." mode="GeoAppearance"><xsl:with-param name="backmap">image</xsl:with-param><xsl:with-param name="appearance">ImageAppearance</xsl:with-param></xsl:apply-templates>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ChartAppearance'">
			<xsl:apply-templates select="." mode="ChartAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#CesiumAppearance'">
			<xsl:apply-templates select="." mode="CesiumAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#VocabularyAppearance'">
			<xsl:apply-templates select="." mode="VocabularyAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#FrameAppearance'">
			<xsl:apply-templates select="." mode="FrameAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ModelAppearance'">
			<xsl:apply-templates select="." mode="ModelAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#MarkdownAppearance'">
			<xsl:apply-templates select="." mode="MarkdownAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#TurtleAppearance'">
			<xsl:apply-templates select="." mode="TurtleAppearance"/>
		</xsl:when>
		<xsl:otherwise>
			<!-- No, or an unknown appearance, use the data to select a suitable appearance -->
			<xsl:apply-templates select="." mode="ContentAppearance">
				<xsl:with-param name="subject" select="$subject"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose><xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="rdf:RDF" mode="TableAppearance">
	<!-- A select query will have @rdf:nodeID elements, with id 'rset' -->
	<xsl:for-each select="rdf:Description[@rdf:nodeID='rset']">
		<xsl:if test="exists(res:solution)">
			<xsl:for-each select="res:resultVariable[not(@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance' or matches(.,'[^_]*_(label|details|count|uri)'))]">
				<xsl:text>|</xsl:text>
				<xsl:choose>
					<xsl:when test="exists(@elmo:label)"><xsl:value-of select="@elmo:label"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
				</xsl:choose>
			</xsl:for-each><xsl:text>
</xsl:text>
			<xsl:for-each select="res:resultVariable[not(@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance' or matches(.,'[^_]*_(label|details|count|uri)'))]">
				<xsl:text>|---</xsl:text>
			</xsl:for-each><xsl:text>
</xsl:text>
			<xsl:choose>
				<xsl:when test="exists(res:resultVariable[@elmo:name='SUBJECT'])">
					<xsl:variable name="key" select="res:resultVariable[@elmo:name='SUBJECT'][1]"/>
					<xsl:for-each-group select="res:solution" group-by="res:binding[res:variable=$key]/res:value/@rdf:resource">
						<xsl:variable name="group" select="current-group()"/>
						<xsl:for-each select="../res:resultVariable[not(@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance' or matches(.,'[^_]*_(label|details|count|uri)'))]">
							<xsl:variable name="var" select="."/>
							<xsl:text>|</xsl:text>
							<!-- Remove duplicates, so still a for-each-group -->
							<xsl:for-each-group select="$group/res:binding[res:variable=$var]" group-by="concat(res:value,res:value/@rdf:resource)">
								<xsl:if test="position()!=1">, </xsl:if>
								<xsl:apply-templates select="." mode="tableobject"/>
							</xsl:for-each-group>
						</xsl:for-each><xsl:text>
</xsl:text>
					</xsl:for-each-group>
				</xsl:when>
				<xsl:otherwise>
					<xsl:for-each select="res:solution">
						<xsl:variable name="binding" select="res:binding"/>
						<xsl:for-each select="../res:resultVariable[not(@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance' or matches(.,'[^_]*_(label|details|count|uri)'))]">
							<xsl:variable name="var" select="."/>
							<xsl:text>|</xsl:text>
							<xsl:apply-templates select="$binding[res:variable=$var]" mode="tableobject"/>
						</xsl:for-each><xsl:text>
</xsl:text>
					</xsl:for-each>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:for-each>
	<!-- If it's not a select query, construct the table: a column for a property, and a row for a resource -->
	<xsl:if test="not(exists(rdf:Description[@rdf:nodeID='rset']))">
		<xsl:variable name="columns">
			<xsl:for-each-group select="rdf:Description[exists(@rdf:about)]/*" group-by="local-name()">
				<xsl:variable name="label">
					<xsl:value-of select="@elmo:label"/>
					<xsl:if test="not(@elmo:label!='')"><xsl:value-of select="local-name()"/></xsl:if>
				</xsl:variable>
				<column name="{local-name()}" label="{$label}"/>
			</xsl:for-each-group>
		</xsl:variable>
		<table class="table table-striped table-bordered">
			<thead>
				<tr>
					<xsl:for-each select="$columns/column">
						<th><xsl:value-of select="@label"/></th>
					</xsl:for-each>
				</tr>
			</thead>
			<tbody>
				<xsl:for-each-group select="rdf:Description" group-by="@rdf:about">
					<tr>
						<xsl:variable name="group" select="current-group()"/>
						<xsl:for-each select="$columns/column">
							<xsl:variable name="column" select="@name"/>
							<td><xsl:value-of select="$group/*[local-name()=$column]"/></td>
						</xsl:for-each>
					</tr>
				</xsl:for-each-group>
			</tbody>
		</table>
	</xsl:if>
</xsl:template>

<xsl:template match="res:binding" mode="tableobject">
	<xsl:variable name="varname" select="res:variable"/>
	<xsl:variable name="vars" select="../../res:resultVariable"/>
	<xsl:variable name="parname" select="res:variable"/>
	<xsl:choose>
		<xsl:when test="exists($vars[.=$parname]/@elmo:template)">
			<xsl:variable name="uri" select="res:value/@rdf:resource"/>
			<xsl:variable name="templatestring" select="tokenize(substring($vars[.=$parname]/@elmo:template,2,string-length($vars[.=$parname]/@elmo:template)-2),'&quot;; &quot;')"/>
			<xsl:variable name="template">
				<xsl:for-each select="$templatestring">
					<item pos="{position()}" name="{substring-before(substring-after(.,'&lt;'),'>')}" first="{substring-before(.,'&lt;')}" next="{substring-after(.,'>')}"/>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="context">
				<xsl:for-each-group select="key('rdf',$vars[.=$parname]/@html:glossary)/rdf:Description/*[@rdf:resource=$uri]" group-by="local-name()">
					<xsl:variable name="name" select="local-name()"/>
					<xsl:for-each select="current-group()">
						<item prio="{$template/item[@name=$name]/@pos}" pos="{position()}" first="{$template/item[@name=$name]/@first}" next="{$template/item[@name=$name]/@next}" uri="{../@rdf:about}" rel="{$name}"><xsl:value-of select="../elmo:name"/></item>
					</xsl:for-each>
				</xsl:for-each-group>
			</xsl:variable>
			<xsl:value-of select="$template/item[1]/@first"/>
			<a href="{$uri}" style="{$vars[.=$parname]/@html:stylesheet}"><xsl:value-of select="$context/item[@uri=$uri]"/></a>

			<xsl:for-each select="$context/item[@uri!=$uri and @prio!='']"><xsl:sort select="@prio"/>
				<xsl:text> </xsl:text>
				<xsl:choose>
					<xsl:when test="position()=1"><xsl:value-of select="@first"/></xsl:when>
					<xsl:when test="@pos!=1"><xsl:value-of select="replace(@next,'\([^\)]*\)','')"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="replace(@next,'\(|\)','')"/></xsl:otherwise>
				</xsl:choose>
				<xsl:text> </xsl:text><a href="{@uri}" style="{$vars[.=$parname]/@html:stylesheet}"><xsl:value-of select="."/></a>
			</xsl:for-each>
		</xsl:when>
		<xsl:when test="exists(res:value/@rdf:resource)">
			<!-- _label is used for the label of a resource -->
			<xsl:variable name="labelvar"><xsl:value-of select="$varname"/>_label</xsl:variable>
			<xsl:variable name="qlabel"><xsl:value-of select="../res:binding[res:variable=$labelvar]/res:value"/></xsl:variable>
			<xsl:variable name="plabel"><xsl:value-of select="substring-after(res:value/@rdf:resource,'#')"/></xsl:variable>
			<xsl:variable name="label">
				<xsl:value-of select="$qlabel"/>
				<xsl:if test="$qlabel=''">
					<xsl:value-of select="$plabel"/>
					<xsl:if test="$plabel=''"><xsl:value-of select="res:value/@rdf:resource"/></xsl:if>
				</xsl:if>
			</xsl:variable>
			<!-- _count is used for a count of a resource -->
			<xsl:variable name="countvar"><xsl:value-of select="res:variable"/>_count</xsl:variable>
			<xsl:variable name="count"><xsl:value-of select="../res:binding[res:variable=$countvar]/res:value"/></xsl:variable>
			<xsl:variable name="detailsvar"><xsl:value-of select="res:variable"/>_details</xsl:variable>
			<xsl:variable name="details"><xsl:value-of select="../res:binding[res:variable=$detailsvar]/res:value"/></xsl:variable>
			<xsl:text>[</xsl:text><xsl:value-of select="$label"/><xsl:text>](</xsl:text>
			<xsl:value-of select="res:value/@rdf:resource"/><xsl:text>)</xsl:text>
			<xsl:if test="$count!=''">
				<xsl:text> (</xsl:text><xsl:value-of select="$count"/><xsl:text>)</xsl:text>
			</xsl:if>
			<!--
			<xsl:if test="$details!=''">
				<br /><xsl:value-of select="$details"/>
			</xsl:if>
			-->
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="res:value"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="rdf:RDF" mode="MarkdownAppearance">
	<!-- Titel -->
	<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description/rdfs:label"/></xsl:call-template></xsl:variable>
	<xsl:if test="$label!=''">
		<xsl:text># </xsl:text>
		<xsl:value-of select="$label"/>
		<xsl:text>

</xsl:text>
	</xsl:if>
	<!--Text -->
	<!-- HTML as part of a construct query -->
	<xsl:for-each select="rdf:Description/elmo:md">
		<xsl:value-of select="."/><xsl:text>
</xsl:text>
	</xsl:for-each>
	<!-- HTML as part of a select query -->
	<xsl:for-each select="rdf:Description/res:solution/res:binding[res:variable='md']/res:value">
		<xsl:value-of select="."/><xsl:text>
</xsl:text>
	</xsl:for-each>
</xsl:template>

<xsl:template match="rdf:RDF" mode="ContentAppearance">
	<xsl:param name="subject"/>
	<!-- A construct query will have @rdf:about elements -->
	<xsl:if test="exists(rdf:Description/@rdf:about)">
		<xsl:for-each select="rdf:Description">
			<!-- Only show resources that are subject -->
			<xsl:if test="not($subject!='') or elmo:subject/@rdf:resource=$subject or elmo:subject/rdf:Description/@rdf:about=$subject">
				<!-- Don't show already nested resources -->
				<xsl:if test="not(exists(key('nested',@rdf:about)))">
					<xsl:apply-templates select="." mode="PropertyTable"/>
				</xsl:if>
			</xsl:if>
		</xsl:for-each>
	</xsl:if>
</xsl:template>

<xsl:template match="rdf:Description" mode="PropertyTable">
	<!-- Content -->
	<xsl:text>|Eigenschap|Waarde
</xsl:text>
	<xsl:text>|----------|------
</xsl:text>
	<xsl:for-each-group select="*" group-by="name()"><xsl:sort select="@elmo:index"/>
		<xsl:if test="not(@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance')">
			<xsl:text>|</xsl:text><xsl:apply-templates select="." mode="predicate"/><xsl:text>|</xsl:text>
			<xsl:choose>
				<xsl:when test="count(current-group())=1">
					<xsl:apply-templates select="." mode="object"/>
				</xsl:when>
				<xsl:otherwise>
					<!-- Nested resources sorteren -->
					<xsl:for-each select="current-group()"><xsl:sort select="rdf:Description/@rdf:about"/>
						<xsl:if test="position()!=1">, </xsl:if>
						<xsl:apply-templates select="." mode="object"/>
					</xsl:for-each>
				</xsl:otherwise>
			</xsl:choose><xsl:text>
</xsl:text>
		</xsl:if>
	</xsl:for-each-group>
	<xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="*" mode="object">
	<xsl:choose>
		<!-- Image -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ImageAppearance'">
			<xsl:text>![](</xsl:text><xsl:value-of select="@rdf:resource"/><xsl:text>)
</xsl:text>
		</xsl:when>
		<!-- Reference to another resource, without a label -->
		<xsl:when test="exists(@rdf:resource)">
			<xsl:text>[</xsl:text>
			<xsl:choose>
				<xsl:when test="@rdfs:label!=''"><xsl:value-of select="@rdfs:label"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="@rdf:resource"/></xsl:otherwise>
			</xsl:choose>
			<xsl:text>](</xsl:text><xsl:value-of select="@rdf:resource"/><xsl:text>)</xsl:text>
		</xsl:when>
		<!-- Reference to another resource, nested -->
		<xsl:when test="exists(rdf:Description/@rdf:about) and @elmo:appearance='http://bp4mc2.org/elmo/def#NestedAppearance'">
			<table>
				<xsl:for-each-group select="rdf:Description/*" group-by="name()">
					<xsl:if test="not(@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance')">
						<tr>
							<td><xsl:apply-templates select="." mode="predicate"/></td>
							<td>
								<xsl:for-each select="current-group()">
									<xsl:if test="position()!=1">; </xsl:if>
									<xsl:apply-templates select="." mode="object"/>
								</xsl:for-each>
							</td>
						</tr>
					</xsl:if>
				</xsl:for-each-group>
			</table>
		</xsl:when>
		<!-- Reference to another resource, with a label -->
		<xsl:when test="exists(rdf:Description/@rdf:about)">
			<xsl:text>[</xsl:text>
			<xsl:choose>
				<xsl:when test="rdf:Description/rdfs:label!=''"><xsl:value-of select="rdf:Description/rdfs:label"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="rdf:Description/@rdf:about"/></xsl:otherwise>
			</xsl:choose>
			<xsl:text>](</xsl:text><xsl:value-of select="rdf:Description/@rdf:about"/><xsl:text>)</xsl:text>
		</xsl:when>
		<!-- Blank node (list) -->
		<xsl:when test="exists(rdf:Description/rdf:first)">
			<xsl:apply-templates select="rdf:Description/rdf:first" mode="object"/>
			<xsl:if test="not(rdf:Description/rdf:rest/@rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#nil')">
				<xsl:text>, </xsl:text>
				<xsl:apply-templates select="rdf:Description/rdf:rest" mode="object"/>
			</xsl:if>
		</xsl:when>
		<!-- Blank node -->
		<xsl:when test="exists(rdf:Description/@rdf:nodeID)">
			<table>
				<xsl:for-each-group select="rdf:Description/*" group-by="name()">
					<tr>
						<td><xsl:apply-templates select="." mode="predicate"/></td>
						<td>
							<xsl:for-each select="current-group()">
								<xsl:if test="position()!=1">; </xsl:if>
								<xsl:apply-templates select="." mode="object"/>
							</xsl:for-each>
						</td>
					</tr>
				</xsl:for-each-group>
			</table>
		</xsl:when>
		<!-- Lonely blank node -->
		<xsl:when test="exists(@rdf:nodeID)">
			<xsl:value-of select="@rdf:nodeID"/>
		</xsl:when>
		<!-- Literal with glossary -->
		<xsl:otherwise>
			<xsl:value-of select="."/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="normalize-language">
	<xsl:param name="text"/>

	<xsl:choose>
		<xsl:when test="$text[@xml:lang=$language]!=''"><xsl:value-of select="$text[@xml:lang=$language]"/></xsl:when> <!-- First choice: language of browser -->
		<xsl:when test="$text[not(exists(@xml:lang))]!=''"><xsl:value-of select="$text[not(exists(@xml:lang))]"/></xsl:when> <!-- Second choice: no language -->
		<xsl:when test="$text[@xml:lang='nl']!=''"><xsl:value-of select="$text[@xml:lang='nl']"/></xsl:when> <!-- Third choice: dutch -->
		<xsl:when test="$text[@xml:lang='en']!=''"><xsl:value-of select="$text[@xml:lang='en']"/></xsl:when> <!-- Fourth choice: english -->
		<xsl:otherwise><xsl:value-of select="$text[1]"/></xsl:otherwise> <!-- If all fails, the first label -->
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="predicate">
	<xsl:choose>
		<xsl:when test="@elmo:label!=''"><xsl:value-of select="@elmo:label"/></xsl:when>
		<xsl:otherwise><xsl:value-of select="local-name()"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
