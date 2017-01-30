<!--

    NAME     ModelAppearance.xsl
    VERSION  1.15.1-SNAPSHOT
    DATE     2017-01-30

    Copyright 2012-2017

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
	ModelAppearance, add-on of rdf2html.xsl
	
	A Model appearance creates a model from some linked data. It looks a bit like the GraphAppearance, but used for static models.
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:shacl="http://www.w3.org/ns/shacl#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
>

<xsl:output method="xml" indent="yes"/>

<!-- These parts are from VocabularyAppearance and should be reused! -->
<xsl:template match="rdf:RDF" mode="VocabularyVariable">
	<!-- All predicates -->
	<xsl:variable name="all-predicates">
		<xsl:for-each-group select="rdf:Description[exists(shacl:predicate)]" group-by="@rdf:about">
			<property uri="{@rdf:about}" predicate="{shacl:predicate/@rdf:resource}">
				<xsl:for-each select="current-group()/shacl:class">
					<ref-class uri="{@rdf:resource}"/>
				</xsl:for-each>
				<xsl:for-each select="current-group()/shacl:datatype">
					<datatype uri="{@rdf:resource}"/>
				</xsl:for-each>
				<xsl:for-each select="current-group()/shacl:in">
					<domain uri="{@rdf:resource}"/>
				</xsl:for-each>
				<xsl:for-each select="current-group()/shacl:minCount">
					<mincount><xsl:value-of select="."/></mincount>
				</xsl:for-each>
				<xsl:for-each select="current-group()/shacl:maxCount">
					<maxcount><xsl:value-of select="."/></maxcount>
				</xsl:for-each>
			</property>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- All shapes -->
	<xsl:variable name="all-shapes">
		<xsl:for-each-group select="rdf:Description[exists(shacl:scopeClass|shacl:targetClass|shacl:property)]" group-by="@rdf:about">
			<xsl:variable name="class" select="current-group()/(shacl:scopeClass|shacl:targetClass)[1]/@rdf:resource"/>
			<shape class-uri="{$class}">
				<xsl:for-each select="current-group()/shacl:property">
					<xsl:variable name="property" select="@rdf:resource"/>
					<xsl:variable name="predicate" select="$all-predicates/property[@uri=$property]"/>
					<!-- If predicate doesn't exists, the shacl shape refers to an unknown predicate constraint! -->
					<xsl:if test="exists($predicate)">
						<property uri="{$predicate/@predicate}">
							<xsl:if test="$predicate/ref-class/@uri!=''">
								<xsl:attribute name="refclass"><xsl:value-of select="$predicate/ref-class/@uri"/></xsl:attribute>
							</xsl:if>
							<xsl:attribute name="mincount">
								<xsl:choose>
									<xsl:when test="$predicate/mincount[1]!=''"><xsl:value-of select="$predicate/mincount[1]"/></xsl:when>
									<xsl:otherwise>0</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							<xsl:attribute name="maxcount">
								<xsl:choose>
									<xsl:when test="$predicate/maxcount[1]!=''"><xsl:value-of select="$predicate/maxcount[1]"/></xsl:when>
									<xsl:otherwise>n</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
						</property>
					</xsl:if>
				</xsl:for-each>
				<xsl:apply-templates select="../rdf:Description[@rdf:about=$class]" mode="shape-propertyrec"/>
			</shape>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- All classes -->
	<xsl:variable name="all-classes">
		<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Class' or rdf:type/@rdf:resource='http://www.w3.org/2000/01/rdf-schema#Class']" group-by="@rdf:about">
			<xsl:variable name="about" select="@rdf:about"/>
			<xsl:variable name="name"><xsl:value-of select="replace($about,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:variable>
			<xsl:variable name="label">
				<xsl:value-of select="rdfs:label"/>
				<xsl:if test="not(rdfs:label!='')"><xsl:value-of select="$name"/></xsl:if>
			</xsl:variable>
			<class uri="{$about}" label="{$label}">
				<xsl:if test="not(exists(* except rdf:type))"><xsl:attribute name="ref">true</xsl:attribute></xsl:if>
				<xsl:for-each select="current-group()/rdfs:subClassOf">
					<super uri="{@rdf:resource}">
						<xsl:variable name="ref" select="@rdf:resource"/>
						<xsl:if test="not(exists(../../rdf:Description[@rdf:about=$ref]/(* except rdf:type)))"><xsl:attribute name="label" select="$ref"/></xsl:if>
					</super>
				</xsl:for-each>
				<xsl:for-each select="../rdf:Description[rdfs:subClassOf/@rdf:resource=$about]">
					<sub uri="{@rdf:about}"/>
				</xsl:for-each>
				<xsl:for-each select="current-group()/rdfs:comment">
					<comment><xsl:value-of select="."/></comment>
				</xsl:for-each>
				<xsl:for-each select="current-group()/rdfs:seeAlso">
					<seeAlso uri="{@rdf:resource}">
						<xsl:variable name="ref" select="@rdf:resource"/>
						<xsl:if test="not(exists(../../rdf:Description[@rdf:about=$ref]/(* except rdf:type)))"><xsl:attribute name="label" select="$ref"/></xsl:if>
					</seeAlso>
				</xsl:for-each>
				<xsl:copy-of select="$all-shapes/shape[@class-uri=$about]/property"/>
				<xsl:for-each-group select="$all-shapes/shape/property[@refclass=$about]" group-by="@uri">
					<refproperty uri="{@uri}" predicate="{@predicate}"/>
				</xsl:for-each-group>
				<xsl:for-each-group select="$all-shapes/shape[@class-uri=$about]/inherited-property" group-by="@uri">
					<inherited-property uri="{@uri}"/>
				</xsl:for-each-group>
			</class>
		</xsl:for-each-group>
		<!-- All superclasses that are not defined in the ontology -->
		<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Class' or rdf:type/@rdf:resource='http://www.w3.org/2000/01/rdf-schema#Class']/rdfs:subClassOf" group-by="@rdf:resource">
			<xsl:variable name="classuri" select="@rdf:resource"/>
			<xsl:if test="not(exists(../../rdf:Description[@rdf:about=$classuri]))">
				<class uri="{@rdf:resource}" ref="true">
					<xsl:for-each select="current-group()">
						<sub uri="{../@rdf:about}"/>
					</xsl:for-each>
				</class>
			</xsl:if>
		</xsl:for-each-group>
	</xsl:variable>
	<classes>
		<xsl:copy-of select="$all-classes"/>
	</classes>
	<!-- All properties -->
	<properties>
		<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#DatatypeProperty' or rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#ObjectProperty' or rdf:type/@rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#Property']" group-by="@rdf:about">
			<xsl:variable name="about" select="@rdf:about"/>
			<xsl:variable name="name"><xsl:value-of select="replace($about,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:variable>
			<xsl:variable name="label">
				<xsl:value-of select="rdfs:label"/>
				<xsl:if test="not(rdfs:label!='')"><xsl:value-of select="$name"/></xsl:if>
			</xsl:variable>
			<xsl:variable name="predicate" select="$all-predicates/property[@predicate=$about]"/>
			<property uri="{$about}" label="{$label}">
				<xsl:if test="not(exists(* except rdf:type))"><xsl:attribute name="ref">true</xsl:attribute></xsl:if>
				<xsl:choose>
					<xsl:when test="exists($all-classes/class/property[@uri=$about])">
						<xsl:for-each select="$all-classes/class/property[@uri=$about]">
							<scope-class uri="{../@uri}"/>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<xsl:for-each select="current-group()/rdfs:domain">
							<scope-class uri="{@rdf:resource}"/>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:for-each-group select="$predicate/ref-class" group-by="@uri">
					<ref-class uri="{@uri}"/>
				</xsl:for-each-group>
				<xsl:for-each-group select="$predicate/datatype" group-by="@uri">
					<datatype uri="{@uri}"/>
				</xsl:for-each-group>
				<xsl:for-each-group select="$predicate/domain" group-by="@uri">
					<domain uri="{@uri}"/>
				</xsl:for-each-group>
				<xsl:for-each select="current-group()/rdfs:subPropertyOf">
					<super uri="{@rdf:resource}">
						<xsl:variable name="ref" select="@rdf:resource"/>
						<xsl:if test="not(exists(../../rdf:Description[@rdf:about=$ref]/(* except rdf:type)))"><xsl:attribute name="label" select="$ref"/></xsl:if>
					</super>
				</xsl:for-each>
				<xsl:for-each select="../rdf:Description[rdfs:subPropertyOf/@rdf:resource=$about]">
					<sub uri="{@rdf:about}"/>
				</xsl:for-each>
				<xsl:for-each select="current-group()/rdfs:comment">
					<comment><xsl:value-of select="."/></comment>
				</xsl:for-each>
			</property>
		</xsl:for-each-group>
	</properties>
</xsl:template>

<xsl:template match="rdf:RDF" mode="ModelAppearance">
	<xsl:variable name="vocabulary"><xsl:apply-templates select="." mode="VocabularyVariable"/></xsl:variable>
	<link rel="stylesheet" href="{$staticroot}/css/joint.min.css" />
    <script src="{$staticroot}/js/lodash.min.js"></script>
    <script src="{$staticroot}/js/backbone-min.js"></script>
	<script src="{$staticroot}/js/graphlib.min.js"></script>
	<script src="{$staticroot}/js/dagre.min.js"></script>
    <script src="{$staticroot}/js/joint.min.js"></script>
	<div id="graphcanvas" style="position:relative;">
		<div class="panel panel-primary">
			<div class="panel-heading">
				<h3 class="panel-title">Model<span class="glyphicon glyphicon-fullscreen" style="position:absolute;right:10px;margin-top:10px;cursor:pointer" onclick="togglefullscreen()"/></h3>
			</div>
			<div class="panel-body">
				<div id="jointmodel"/>
				<xsl:variable name="cells">
					<!-- Nodes -->
					<xsl:for-each select="$vocabulary/classes/class">
						<xsl:if test="position()!=1">,</xsl:if>
						<xsl:text>{id:"</xsl:text><xsl:value-of select="@uri"/><xsl:text>"</xsl:text>
						<xsl:text>,type:"uml.State"</xsl:text>
						<xsl:text>,name:"</xsl:text><xsl:value-of select="@label"/><xsl:text>"</xsl:text>
						<xsl:text>,events:[</xsl:text>
						<xsl:for-each select="property[not(exists(@refclass))]">
							<xsl:variable name="propertyuri" select="@uri"/>
							<xsl:variable name="property" select="../../../properties/property[@uri=$propertyuri]"/>
							<xsl:variable name="label"><xsl:value-of select="$property/@label"/></xsl:variable>
							<xsl:variable name="datatype"><xsl:value-of select="$property/datatype/@uri"/></xsl:variable>
							<xsl:if test="position()!=1">,</xsl:if>
							<xsl:text>"</xsl:text>
								<xsl:value-of select="$label"/><xsl:if test="$label=''"><xsl:value-of select="replace($propertyuri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:if>
								<xsl:if test="$datatype!=''"> (<xsl:value-of select="replace($datatype,'^.*(#|/)([^(#|/)]+)$','$2')"/>)</xsl:if>
								<xsl:text> [</xsl:text><xsl:value-of select="@mincount"/>,<xsl:value-of select="@maxcount"/>
							<xsl:text>]"</xsl:text>
						</xsl:for-each>
						<xsl:text>]</xsl:text>
						<xsl:text>,position:{x:300,y:300}</xsl:text>
						<xsl:text>,size:{width:100,height:100}</xsl:text>
						<xsl:text>}</xsl:text>
					</xsl:for-each>
					<!-- Links: superclasses -->
					<xsl:for-each select="$vocabulary/classes/class/super">
						<xsl:variable name="target" select="@uri"/>
						<xsl:if test="exists($vocabulary/classes/class[@uri=$target])">
							<xsl:text>,{id:"</xsl:text><xsl:value-of select="../@uri"/><xsl:value-of select="$target"/><xsl:text>"</xsl:text>
							<xsl:text>,type:"link"</xsl:text>
							<xsl:text>,source:{id:"</xsl:text><xsl:value-of select="../@uri"/><xsl:text>"}</xsl:text>
							<xsl:text>,target:{id:"</xsl:text><xsl:value-of select="$target"/><xsl:text>"}</xsl:text>
							<xsl:text>,router:{name:"manhattan"}</xsl:text>
							<xsl:text>,connector:{name:"normal"}</xsl:text>
							<xsl:text>,ldttype: "isa"</xsl:text>
							<xsl:text>}</xsl:text>
						</xsl:if>
					</xsl:for-each>
					<!-- Links: objectproperties -->
					<xsl:for-each select="$vocabulary/classes/class/property[@refclass!='']">
						<xsl:variable name="target" select="@refclass"/>
						<xsl:if test="exists($vocabulary/classes/class[@uri=$target])">
							<xsl:variable name="propertyuri" select="@uri"/>
							<xsl:variable name="property" select="../../../properties/property[@uri=$propertyuri]"/>
							<xsl:variable name="label"><xsl:value-of select="$property/@label"/></xsl:variable>
							<xsl:text>,{id:"</xsl:text><xsl:value-of select="../@uri"/><xsl:value-of select="$propertyuri"/><xsl:value-of select="$target"/><xsl:text>"</xsl:text>
							<xsl:text>,type:"link"</xsl:text>
							<xsl:text>,source:{id:"</xsl:text><xsl:value-of select="../@uri"/><xsl:text>"}</xsl:text>
							<xsl:text>,target:{id:"</xsl:text><xsl:value-of select="$target"/><xsl:text>"}</xsl:text>
							<xsl:text>,router:{name:"manhattan"}</xsl:text>
							<xsl:text>,connector:{name:"normal"}</xsl:text>
							<xsl:text>,labels: [{ position: 0.5, attrs: { text: { text: "</xsl:text>
								<xsl:value-of select="$label"/><xsl:if test="$label=''"><xsl:value-of select="replace($propertyuri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:if>
								<xsl:text> [</xsl:text><xsl:value-of select="@mincount"/>,<xsl:value-of select="@maxcount"/>
							<xsl:text>]" } } }]</xsl:text>
							<xsl:text>}</xsl:text>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				<script type="text/javascript">
					var cells = {cells: [<xsl:value-of select="$cells"/>]};
				</script>
				<script src="{$staticroot}/js/linkedmodel.min.js"></script>
			</div>
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>