<!--

    NAME     rdf2rdfa.xsl
    VERSION  1.23.0
    DATE     2018-10-20

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
    Transformation of RDF document to a RDF document with mark-up annotations

	TODO: Transfer functionality to sparql2rdfa

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
>

<!-- bnodes and resources from all queries, this is not perfectly right, because it should be local to the specific query (more than one rdf:RDF is possible) -->
<xsl:key name="resource" match="/root/results/rdf:RDF/rdf:Description" use="@rdf:about"/>
<xsl:key name="bnodes" match="/root/results/rdf:RDF/rdf:Description" use="@rdf:nodeID"/>

<xsl:template match="*" mode="property">
	<xsl:param name="fragments"/>

	<xsl:element name="{name()}" namespace="{namespace-uri()}">
		<xsl:if test="@xml:lang!=''"><xsl:attribute name="xml:lang" select="@xml:lang"/></xsl:if>
		<!-- full uri of the property -->
		<xsl:variable name="uri"><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></xsl:variable>
		<!-- Default fragment -->
		<xsl:variable name="defaultFragment" select="$fragments[@applies-to='http://bp4mc2.org/elmo/def#Fragment']"/>
		<!-- Find an applicable fragment -->
		<xsl:variable name="keyfragments" select="$fragments[@applies-to=$uri]"/>
		<xsl:variable name="nodeID" select="@rdf:nodeID"/>
		<xsl:variable name="subfragment">
			<xsl:for-each select="$keyfragments[exists(@filter-property)]">
				<xsl:variable name="filter-property" select="@filter-property"/>
				<xsl:variable name="filter-value" select="key('bnodes',$nodeID)/*[concat(namespace-uri(),local-name())=$filter-property]/(text()|@rdf:resource)"/>
				<xsl:if test="@filter-value=$filter-value">
					<xsl:copy-of select="*"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="fragment">
			<xsl:choose>
				<xsl:when test="exists($subfragment/*)"><xsl:copy-of select="$subfragment[1]/*"/></xsl:when>
				<xsl:otherwise><xsl:copy-of select="$keyfragments[not(exists(@filter-property))][1]/*"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- If the label of the property exists, include it (priority for a fragment, then the property-label in the query result -->
		<xsl:variable name="plabels">
			<xsl:choose>
				<xsl:when test="exists($fragment/rdfs:label)"><xsl:copy-of select="$fragment/rdfs:label"/></xsl:when>
				<xsl:otherwise><xsl:copy-of select="key('resource',$uri)/rdfs:label"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="language" select="/root/context/language"/>
		<xsl:variable name="plabel">
			<xsl:choose>
				<xsl:when test="$plabels/rdfs:label[@xml:lang=$language]!=''"><xsl:value-of select="$plabels/rdfs:label[@xml:lang=$language]"/></xsl:when> <!-- First choice: language of browser -->
				<xsl:when test="$plabels/rdfs:label[not(exists(@xml:lang))]!=''"><xsl:value-of select="$plabels/rdfs:label[not(exists(@xml:lang))]"/></xsl:when> <!-- Second choice: no language -->
				<xsl:when test="$plabels/rdfs:label[@xml:lang='nl']!=''"><xsl:value-of select="$plabels/rdfs:label[@xml:lang='nl']"/></xsl:when> <!-- Third choice: dutch -->
				<xsl:when test="$plabels/rdfs:label[@xml:lang='en']!=''"><xsl:value-of select="$plabels/rdfs:label[@xml:lang='en']"/></xsl:when> <!-- Fourth choice: english -->
				<xsl:otherwise><xsl:value-of select="$plabels/rdfs:label[1]"/></xsl:otherwise> <!-- If all fails, the first label -->
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$plabel!=''"><xsl:attribute name="elmo:label"><xsl:value-of select="$plabel"/></xsl:attribute></xsl:if>
		<!-- Same for comments -->
		<xsl:variable name="pcomment">
			<xsl:choose>
				<xsl:when test="exists($fragment/rdfs:comment)"><xsl:copy-of select="$fragment/rdfs:comment"/></xsl:when>
				<xsl:otherwise><xsl:copy-of select="key('resource',$uri)/rdfs:comment"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$pcomment!=''"><xsl:attribute name="elmo:comment"><xsl:value-of select="$pcomment"/></xsl:attribute></xsl:if>
		<!-- Other fragments -->
		<xsl:choose>
			<xsl:when test="$fragment/elmo:appearance[1]/@rdf:resource!=''"><xsl:attribute name="elmo:appearance"><xsl:value-of select="$fragment/elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:when>
			<xsl:when test="exists($fragment)"/> <!-- Don't use default appearance if a fragment exists -->
			<xsl:when test="$defaultFragment/elmo:appearance[1]/@rdf:resource!=''"><xsl:attribute name="elmo:appearance"><xsl:value-of select="$defaultFragment/elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:when>
		</xsl:choose>
		<xsl:if test="$fragment/elmo:select/@rdf:resource!=''"><xsl:attribute name="elmo:select"><xsl:value-of select="$fragment/elmo:select/@rdf:resource"/></xsl:attribute></xsl:if>
		<xsl:if test="$fragment/elmo:appearance[1]/@rdf:resource!=''"><xsl:attribute name="elmo:appearance"><xsl:value-of select="$fragment/elmo:appearance[1]/@rdf:resource"/></xsl:attribute></xsl:if>
		<xsl:if test="$fragment/html:link[1]!=''"><xsl:attribute name="elmo:link"><xsl:value-of select="$fragment/html:link[1]"/></xsl:attribute></xsl:if>
		<xsl:if test="$fragment/elmo:index[1]!=''"><xsl:attribute name="elmo:index"><xsl:value-of select="$fragment/elmo:index[1]"/></xsl:attribute></xsl:if>
		<xsl:if test="$fragment/html:glossary[1]/@rdf:resource!=''"><xsl:attribute name="html:glossary"><xsl:value-of select="$fragment/html:glossary[1]/@rdf:resource"/></xsl:attribute></xsl:if>
		<xsl:choose>
			<xsl:when test="$fragment/html:meta[1]/@rdf:resource!=''"><xsl:attribute name="html:meta"><xsl:value-of select="$fragment/html:meta[1]/@rdf:resource"/></xsl:attribute></xsl:when>
			<xsl:when test="$defaultFragment/html:meta[1]/@rdf:resource!=''"><xsl:attribute name="html:meta"><xsl:value-of select="$defaultFragment/html:meta[1]/@rdf:resource"/></xsl:attribute></xsl:when>
			<xsl:otherwise />
		</xsl:choose>
		<xsl:choose>
			<!-- If the fragment is a nested statement, include the object -->
			<xsl:when test="exists(@rdf:resource) and $fragment/elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#NestedAppearance'">
				<rdf:Description rdf:about="{@rdf:resource}">
					<xsl:apply-templates select="key('resource',@rdf:resource)/*" mode="property">
						<xsl:with-param name="fragments" select="$fragments"/>
					</xsl:apply-templates>
				</rdf:Description>
			</xsl:when>
			<!-- If the object is a resource -->
			<xsl:when test="exists(@rdf:resource)">
				<xsl:variable name="olabels">
					<xsl:copy-of select="key('resource',@rdf:resource)/rdfs:label"/>
				</xsl:variable>
				<!-- if object is a resource, check for the label -->
				<xsl:choose>
					<xsl:when test="$fragment/rdf:value!=''">
						<xsl:variable name="rlabel">
							<xsl:choose>
								<xsl:when test="$fragment/rdf:value[@xml:lang=$language]!=''"><xsl:value-of select="$fragment/rdf:value[@xml:lang=$language]"/></xsl:when> <!-- First choice: language of browser -->
								<xsl:when test="$fragment/rdf:value[not(exists(@xml:lang))]!=''"><xsl:value-of select="$fragment/rdf:value[not(exists(@xml:lang))]"/></xsl:when> <!-- Second choice: no language -->
								<xsl:when test="$fragment/rdf:value[@xml:lang='nl']!=''"><xsl:value-of select="$fragment/rdf:value[@xml:lang='nl']"/></xsl:when> <!-- Third choice: dutch -->
								<xsl:when test="$fragment/rdf:value[@xml:lang='en']!=''"><xsl:value-of select="$fragment/rdf:value[@xml:lang='en']"/></xsl:when> <!-- Fourth choice: english -->
								<xsl:otherwise><xsl:value-of select="$fragment/rdf:value[1]"/></xsl:otherwise> <!-- If all fails, the first label -->
							</xsl:choose>
						</xsl:variable>
						<rdf:Description rdf:about="{@rdf:resource}">
							<rdfs:label><xsl:value-of select="$rlabel"/></rdfs:label>
						</rdf:Description>
					</xsl:when>
					<xsl:when test="exists($olabels/rdfs:label)">
						<rdf:Description rdf:about="{@rdf:resource}">
							<xsl:choose>
								<xsl:when test="$olabels/rdfs:label[@xml:lang=$language]!=''"><xsl:copy-of select="$olabels/rdfs:label[@xml:lang=$language][1]"/></xsl:when> <!-- First choice: language of browser -->
								<xsl:when test="$olabels/rdfs:label[not(exists(@xml:lang))]!=''"><xsl:copy-of select="$olabels/rdfs:label[not(exists(@xml:lang))][1]"/></xsl:when> <!-- Second choice: no language -->
								<xsl:when test="$olabels/rdfs:label[@xml:lang='nl']!=''"><xsl:copy-of select="$olabels/rdfs:label[@xml:lang='nl'][1]"/></xsl:when> <!-- Third choice: dutch -->
								<xsl:when test="$olabels/rdfs:label[@xml:lang='en']!=''"><xsl:copy-of select="$olabels/rdfs:label[@xml:lang='en'][1]"/></xsl:when> <!-- Fourth choice: english -->
								<xsl:otherwise><xsl:copy-of select="$olabels/rdfs:label[1]"/></xsl:otherwise> <!-- If all fails, the first label -->
							</xsl:choose>
						</rdf:Description>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="rdf:resource"><xsl:value-of select="@rdf:resource"/></xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<!-- if object is a blank node, include the blank node -->
			<xsl:when test="exists(@rdf:nodeID)">
				<xsl:choose>
					<xsl:when test="exists(key('bnodes',@rdf:nodeID)/*)">
						<rdf:Description rdf:nodeID="{@rdf:nodeID}">
							<xsl:apply-templates select="key('bnodes',@rdf:nodeID)[1]/*" mode="property">
								<xsl:with-param name="fragments" select="$fragments"/>
							</xsl:apply-templates>
						</rdf:Description>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="rdf:nodeID"><xsl:value-of select="@rdf:nodeID"/></xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:element>
</xsl:template>

<xsl:template match="scene" mode="scene">
	<xsl:param name="index"/>

	<rdf:Description rdf:about="{@uri}">
		<elmo:index elmo:label="Step"><xsl:value-of select="$index"/></elmo:index>
		<xsl:if test="exists(@label)"><rdfs:label elmo:label="Description"><xsl:value-of select="@label"/></rdfs:label></xsl:if>
		<rdf:value elmo:label="Result"><xsl:value-of select="/root/results/rdf:RDF[position()=$index]/rdf:Description[1]/res:solution[1]/res:binding[1]/res:value[1]"/></rdf:value>
	</rdf:Description>
</xsl:template>

<xsl:template match="representation|production" mode="results">
	<xsl:param name="index"/>

	<xsl:variable name="representation-uri" select="@uri"/>
	<xsl:variable name="appearance1">
		<xsl:if test="not(@appearance!='')">http://bp4mc2.org/elmo/def#ContentAppearance</xsl:if>
		<xsl:value-of select="@appearance"/>
	</xsl:variable>
	<xsl:variable name="appearance">
		<xsl:choose>
			<xsl:when test="queryForm/@satisfied!='' and queryForm/@geo='yes'">http://bp4mc2.org/elmo/def#GeoSelectAppearance</xsl:when>
			<xsl:when test="queryForm/@satisfied!=''">http://bp4mc2.org/elmo/def#FormAppearance</xsl:when>
			<xsl:when test="$appearance1='http://bp4mc2.org/elmo/def#ContentAppearance' and /root/results/rdf:RDF[position()=$index]/rdf:Description[@rdf:nodeID='rset']/rdf:type/@rdf:resource='http://www.w3.org/2005/sparql-results#ResultSet'">http://bp4mc2.org/elmo/def#TableAppearance</xsl:when>
			<xsl:otherwise><xsl:value-of select="$appearance1"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<rdf:RDF elmo:index="{@index}" elmo:appearance="{$appearance}" elmo:query="{$representation-uri}">
		<xsl:if test="exists(@container)"><xsl:attribute name="elmo:container"><xsl:value-of select="@container"/></xsl:attribute></xsl:if>
		<xsl:if test="exists(@name)"><xsl:attribute name="elmo:name"><xsl:value-of select="@name"/></xsl:attribute></xsl:if>
		<xsl:if test="exists(@label)"><xsl:attribute name="elmo:label"><xsl:value-of select="@label"/></xsl:attribute></xsl:if>
		<xsl:choose>
			<xsl:when test="queryForm/@satisfied!='' and queryForm/@geo='yes'">
				<!-- If nothing is available, show center of the map (Netherlands, RD Amersfoort) -->
				<rdf:Description rdf:about="locator">
					<geo:long>5.387197444102625</geo:long>
					<geo:lat>52.15516475286759</geo:lat>
				</rdf:Description>
				<xsl:for-each select="fragment">
					<rdf:Description rdf:nodeID="f{position()}">
						<xsl:if test="@applies-to!=''"><elmo:applies-to><xsl:value-of select="@applies-to"/></elmo:applies-to></xsl:if>
						<xsl:copy-of select="*"/>
					</rdf:Description>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="$appearance='http://bp4mc2.org/elmo/def#ContentAppearance' or $appearance='http://bp4mc2.org/elmo/def#CarouselAppearance' or ($appearance='http://bp4mc2.org/elmo/def#TableAppearance' and not(exists(/root/results/rdf:RDF[position()=$index]/rdf:Description[@rdf:nodeID='rset'])))">
				<xsl:variable name="fragments" select="fragment"/>
				<xsl:variable name="properties">
					<xsl:for-each-group select="/root/results/rdf:RDF[position()=$index]/rdf:Description/*" group-by="name()">
						<property><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></property>
					</xsl:for-each-group>
				</xsl:variable>
				<xsl:for-each-group select="/root/results/rdf:RDF[position()=$index]/rdf:Description" group-by="@rdf:about">
					<xsl:variable name="about" select="@rdf:about"/>
					<xsl:if test="exists(current-group()/*[name()!='rdfs:label']) and not(exists($properties/property[.=$about]))"> <!-- Groups with only labels should be ignored -->
						<rdf:Description rdf:about="{$about}">
							<xsl:apply-templates select="current-group()/*" mode="property">
								<xsl:with-param name="fragments" select="$fragments"/>
							</xsl:apply-templates>
						</rdf:Description>
					</xsl:if>
				</xsl:for-each-group>
			</xsl:when>
			<xsl:when test="$appearance='http://bp4mc2.org/elmo/def#FormAppearance'">
				<xsl:for-each select="queryForm">
					<rdf:Description rdf:nodeID="form">
						<xsl:copy-of select="rdfs:label"/>
					</rdf:Description>
					<xsl:for-each select="fragment[@satisfied='']">
						<rdf:Description rdf:nodeID="f{position()}">
							<xsl:if test="@applies-to!=''"><elmo:applies-to><xsl:value-of select="@applies-to"/></elmo:applies-to></xsl:if>
							<xsl:copy-of select="*"/>
						</rdf:Description>
					</xsl:for-each>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="local-name()='production'">
				<!-- Show special ShortTabelAppearance: the result of all stages -->
				<xsl:for-each select="../(representation|scene)">
					<xsl:variable name="scene-index" select="position()"/>
					<xsl:if test="local-name()='scene'">
						<xsl:apply-templates select="." mode="scene">
							<xsl:with-param name="index" select="$scene-index"/>
						</xsl:apply-templates>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="$appearance='http://bp4mc2.org/elmo/def#TableAppearance' or $appearance='http://bp4mc2.org/elmo/def#ShortTableAppearance' or $appearance='http://bp4mc2.org/elmo/def#TextSearchAppearance'">
				<xsl:copy-of select="/root/results/rdf:RDF[position()=$index]/rdf:Description"/>
			</xsl:when>
			<xsl:when test="$appearance='http://bp4mc2.org/elmo/def#GraphAppearance'">
				<xsl:for-each select="fragment">
					<rdf:Description rdf:nodeID="f{position()}">
						<xsl:if test="@applies-to!=''"><elmo:applies-to><xsl:value-of select="@applies-to"/></elmo:applies-to></xsl:if>
						<xsl:copy-of select="*"/>
					</rdf:Description>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="$appearance='http://bp4mc2.org/elmo/def#EditorAppearance'">
				<xsl:for-each select="fragment">
					<rdf:Description rdf:nodeID="f{position()}">
						<xsl:if test="@applies-to!=''"><elmo:applies-to><xsl:value-of select="@applies-to"/></elmo:applies-to></xsl:if>
						<xsl:copy-of select="*"/>
					</rdf:Description>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="$appearance='http://bp4mc2.org/elmo/def#NavbarSearchAppearance'">
				<xsl:for-each-group select="/root/results/rdf:RDF[position()=$index]/rdf:Description" group-by="(@rdf:nodeID|@rdf:about)">
					<rdf:Description rdf:nodeID="{(@rdf:nodeID|@rdf:about)}">
						<xsl:copy-of select="current-group()/*"/>
					</rdf:Description>
				</xsl:for-each-group>
			</xsl:when>
			<xsl:when test="$appearance='http://bp4mc2.org/elmo/def#TreeAppearance'">
				<xsl:for-each-group select="/root/results/rdf:RDF[position()=$index]/rdf:Description" group-by="@rdf:about">
					<rdf:Description rdf:about="{@rdf:about}">
						<xsl:copy-of select="current-group()/*"/>
					</rdf:Description>
				</xsl:for-each-group>
			</xsl:when>
			<xsl:when test="$appearance='http://bp4mc2.org/elmo/def#TextAppearance'">
				<xsl:for-each-group select="/root/results/rdf:RDF[position()=$index]/rdf:Description" group-by="@rdf:about">
					<rdf:Description rdf:about="{@rdf:about}">
						<xsl:copy-of select="current-group()/*"/>
					</rdf:Description>
				</xsl:for-each-group>
				<xsl:for-each-group select="/root/results/rdf:RDF[position()=$index]/rdf:Description" group-by="@rdf:nodeID">
					<rdf:Description rdf:nodeID="{@rdf:nodeID}">
						<xsl:copy-of select="current-group()/*"/>
					</rdf:Description>
				</xsl:for-each-group>
				<xsl:for-each select="fragment">
					<rdf:Description rdf:nodeID="f{position()}">
						<xsl:if test="@applies-to!=''"><elmo:applies-to><xsl:value-of select="@applies-to"/></elmo:applies-to></xsl:if>
						<xsl:copy-of select="*"/>
					</rdf:Description>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="$appearance='http://bp4mc2.org/elmo/def#GeoSelectAppearance' or $appearance='http://bp4mc2.org/elmo/def#GeoAppearance' or $appearance='http://bp4mc2.org/elmo/def#ImageAppearance'">
				<xsl:if test="$appearance='http://bp4mc2.org/elmo/def#GeoSelectAppearance' and not(exists(/root/results/rdf:RDF[position()=$index]/*))">
				<rdf:Description rdf:about="locator">
					<geo:long><xsl:value-of select="/root/context/parameters/parameter[name='long']/value"/></geo:long>
					<geo:lat><xsl:value-of select="/root/context/parameters/parameter[name='lat']/value"/></geo:lat>
				</rdf:Description>
				</xsl:if>
				<xsl:variable name="fragments" select="fragment"/>
				<xsl:for-each-group select="/root/results/rdf:RDF[position()=$index]/rdf:Description" group-by="@rdf:about">
					<rdf:Description rdf:about="{@rdf:about}">
						<xsl:for-each select="current-group()/*">
							<xsl:element name="{name()}" namespace="{namespace-uri()}">
								<!-- full uri of the property -->
								<xsl:variable name="uri"><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></xsl:variable>
								<!-- Find an applicable fragment -->
								<xsl:variable name="fragment" select="$fragments[@applies-to=$uri]"/>
								<xsl:choose>
									<xsl:when test="exists(@rdf:resource)">
										<xsl:if test="exists($fragment/elmo:appearance)">
											<xsl:attribute name="elmo:appearance"><xsl:value-of select="$fragment/elmo:appearance/@rdf:resource"/></xsl:attribute>
										</xsl:if>
										<xsl:attribute name="rdf:resource"><xsl:value-of select="@rdf:resource"/></xsl:attribute>
									</xsl:when>
									<xsl:when test="exists(@rdf:nodeID)">
										<xsl:attribute name="rdf:nodeID"><xsl:value-of select="@rdf:nodeID"/></xsl:attribute>
									</xsl:when>
									<xsl:otherwise>
										<xsl:if test="exists(@xml:lang)">
											<xsl:attribute name="xml:lang"><xsl:value-of select="@xml:lang"/></xsl:attribute>
										</xsl:if>
										<xsl:value-of select="."/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:element>
						</xsl:for-each>
					</rdf:Description>
				</xsl:for-each-group>
				<xsl:for-each select="fragment">
					<rdf:Description rdf:nodeID="f{position()}">
						<xsl:if test="@applies-to!=''"><elmo:applies-to><xsl:value-of select="@applies-to"/></elmo:applies-to></xsl:if>
						<xsl:copy-of select="*"/>
					</rdf:Description>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="/root/results/rdf:RDF[position()=$index]/*"/>
			</xsl:otherwise>
		</xsl:choose>
	</rdf:RDF>

</xsl:template>

<xsl:template match="/root">
	<results>
		<context docroot="{context/@docroot}" staticroot="{context/@staticroot}" version="{context/@version}" linkstrategy="{context/@linkstrategy}">
			<!-- TODO: to much namespaces declarations in resulting XML due to copy-of statement -->
			<xsl:copy-of select="context/*"/>
			<xsl:copy-of select="view/stylesheet"/>
		</context>
		<!-- Don't show scenes, but include it for the correct position count -->
		<xsl:for-each select="view/(representation|scene)">
			<xsl:variable name="index" select="position()"/>
			<xsl:if test="local-name()='representation'">
				<xsl:apply-templates select="." mode="results">
					<xsl:with-param name="index" select="$index"/>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:for-each>
		<!-- Show scene result as part of a production representation -->
		<xsl:if test="exists(view/production[1])">
			<xsl:apply-templates select="view/production[1]" mode="results">
				<xsl:with-param name="index">0</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
	</results>
</xsl:template>

</xsl:stylesheet>
