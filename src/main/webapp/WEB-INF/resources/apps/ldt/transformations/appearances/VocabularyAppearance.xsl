<!--

    NAME     VocabularyAppearance.xsl
    VERSION  1.12.3-SNAPSHOT
    DATE     2016-12-06

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
	VocabularyAppearance, add-on of rdf2html.xsl
	
	A Vocabulary appearance presents a vocabulary as a single html page with anchors.
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:shacl="http://www.w3.org/ns/shacl#"
	xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:ldt="http://ldt/"
>

<xsl:output method="xml" indent="yes"/>

<xsl:function name="ldt:label">
	<xsl:param name="labelid"/>
	
	<!-- Multilanguage (only dutch and english) -->
	<xsl:variable name="terms">
		<list lang="nl">
			<term id="URI:">URI:</term>
			<term id="Subclass of:">Subklasse van:</term>
			<term id="Has subclasses:">Heeft subklassen:</term>
			<term id="Classes">Klassen</term>
			<term id="Properties">Eigenschappen</term>
			<term id="Classes:">Klassen:</term>
			<term id="Properties:">Eigenschappen:</term>
			<term id="Subproperty of:">Subeigenschap van:</term>
			<term id="Properties include:">Eigenschappen:</term>
			<term id="Inherited properties:">Geërfde eigenschappen:</term>
			<term id="Property of:">Eigenschap van:</term>
			<term id="Class of object:">Gerelateerde klasse:</term>
			<term id="Datatype:">Datatype:</term>
			<term id="Values from:">Waarden uit:</term>
			<term id="Classes and properties">Klassen en eigenschappen</term>
			<term id="Used with property:">Gebruikt bij eigenschap:</term>
		</list>
	</xsl:variable>

	<xsl:variable name="label" select="$terms/list[@lang=$language]/term[@id=$labelid]"/>
	<xsl:value-of select="$label"/>
	<xsl:if test="not($label!='')"><xsl:value-of select="$labelid"/></xsl:if>
</xsl:function>

<xsl:template match="@rdf:resource|@rdf:about|@uri" mode="link">
	<xsl:param name="prefix">~</xsl:param>
	<xsl:param name="label"/>

	<xsl:variable name="name"><xsl:value-of select="replace(.,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:variable>
	<xsl:variable name="label">
		<xsl:value-of select="$label"/>
		<xsl:if test="not($label!='')"><xsl:value-of select="$name"/></xsl:if>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="starts-with(.,$prefix)">
			<a href="#{$name}"><xsl:value-of select="$label"/></a>
		</xsl:when>
		<xsl:otherwise>
			<!--
			<xsl:variable name="resource-uri"><xsl:call-template name="resource-uri"><xsl:with-param name="uri" select="."/></xsl:call-template></xsl:variable>
			<a href="{$resource-uri}"><xsl:value-of select="$name"/></a>
			-->
			<a href="{.}" style="font-style: italic"><xsl:value-of select="$label"/></a>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="rdf:Description" mode="shape-propertyrec">
<!-- Input: class, Output: all properties of the supertype of the shape of the class, recursive -->
<!-- WARNING: No check is made regarding loops!!! -->
	<xsl:for-each select="rdfs:subClassOf">
		<xsl:variable name="super" select="@rdf:resource"/>
		<xsl:for-each select="../../rdf:Description[shacl:scopeClass/@rdf:resource=$super]">
			<xsl:for-each select="shacl:property">
				<xsl:variable name="property" select="@rdf:resource"/>
				<inherited-property uri="{../../rdf:Description[@rdf:about=$property]/shacl:predicate/@rdf:resource}"/>
			</xsl:for-each>
		</xsl:for-each>
		<xsl:apply-templates select="../../rdf:Description[@rdf:about=$super]" mode="shape-propertyrec"/>
	</xsl:for-each>
</xsl:template>

<xsl:template match="class" mode="class-header2">
	<xsl:param name="prefix"/>
	
	<xsl:variable name="name" select="replace(@uri,'^.*(#|/)([^(#|/)]+)$','$2')"/>
	<xsl:variable name="resource-uri"><xsl:call-template name="resource-uri"><xsl:with-param name="uri" select="@uri"/></xsl:call-template></xsl:variable>
	<h4 id="{$name}"><a href="{$resource-uri}"><xsl:value-of select="$name"/></a></h4>
	<p><i><xsl:value-of select="comment"/></i></p>
</xsl:template>

<xsl:template match="class" mode="class-table2">
	<xsl:param name="prefix"/>

	<tr>
		<td><xsl:value-of select="ldt:label('URI:')"/></td>
		<td><xsl:value-of select="@uri"/></td>
	</tr>
	<xsl:if test="exists(super)">
		<tr>
			<td><xsl:value-of select="ldt:label('Subclass of:')"/></td>
			<td>
				<xsl:for-each select="super"><xsl:sort select="@uri"/>
					<xsl:if test="position()!=1">, </xsl:if>
					<xsl:apply-templates select="@uri" mode="link">
						<xsl:with-param name="prefix" select="$prefix"/>
						<xsl:with-param name="label" select="@label"/>
					</xsl:apply-templates>
				</xsl:for-each>
			</td>
		</tr>
	</xsl:if>
	<xsl:if test="exists(sub)">
		<tr>
			<td><xsl:value-of select="ldt:label('Has subclasses:')"/></td>
			<td>
				<xsl:for-each select="sub"><xsl:sort select="@uri"/>
					<xsl:if test="position()!=1">, </xsl:if>
					<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
				</xsl:for-each>
			</td>
		</tr>
	</xsl:if>
	<xsl:if test="exists(seeAlso)">
		<tr>
			<td><xsl:value-of select="ldt:label('See also:')"/></td>
			<td>
				<xsl:for-each select="seeAlso"><xsl:sort select="@uri"/>
					<xsl:if test="position()!=1">, </xsl:if>
					<xsl:apply-templates select="@uri" mode="link">
						<xsl:with-param name="prefix" select="$prefix"/>
						<xsl:with-param name="label" select="@label"/>
					</xsl:apply-templates>
				</xsl:for-each>
			</td>
		</tr>
	</xsl:if>
</xsl:template>

<xsl:template match="class" mode="makeClassTree2">
	<!-- To avoid cycles, a resource can be present only ones -->
	<xsl:param name="done"/>
	<xsl:param name="prefix"/>
	<xsl:variable name="uri" select="@uri"/>
	<xsl:variable name="new">
		<xsl:for-each select="sub">
			<xsl:variable name="about" select="@uri"/>
			<xsl:if test="not(exists($done[uri=$about]))">
				<uri><xsl:value-of select="$about"/></uri>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	<li>
		<xsl:if test="exists($new/uri)"><xsl:attribute name="class">has-child tree-collapsed</xsl:attribute></xsl:if>
		<p><xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates></p>
		<xsl:if test="exists($new/uri)">
			<a class="" href="#" onclick="toggleNode(this);return false;"><i class="fa fa-plus-square"></i></a>
			<ul class="hide"> <!-- Default: collapsed tree -->
				<xsl:for-each select="sub"><xsl:sort select="@uri"/>
					<xsl:variable name="about" select="@uri"/>
					<xsl:if test="not(exists($done[uri=$about]))">
						<xsl:apply-templates select="../../class[@uri=$about]" mode="makeClassTree2">
							<xsl:with-param name="done">
								<xsl:copy-of select="$done"/>
								<xsl:copy-of select="$new"/>
							</xsl:with-param>
							<xsl:with-param name="prefix" select="$prefix"/>
						</xsl:apply-templates>
					</xsl:if>
				</xsl:for-each>
			</ul>
		</xsl:if>
	</li>
</xsl:template>
<xsl:template match="property" mode="makeClassTree2">
	<!-- To avoid cycles, a resource can be present only ones -->
	<xsl:param name="done"/>
	<xsl:param name="prefix"/>
	<xsl:variable name="uri" select="@uri"/>
	<xsl:variable name="new">
		<xsl:for-each select="sub">
			<xsl:variable name="about" select="@uri"/>
			<xsl:if test="not(exists($done[uri=$about]))">
				<uri><xsl:value-of select="$about"/></uri>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	<li>
		<xsl:if test="exists($new/uri)"><xsl:attribute name="class">has-child tree-collapsed</xsl:attribute></xsl:if>
		<p><xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates></p>
		<xsl:if test="exists($new/uri)">
			<a class="" href="#" onclick="toggleNode(this);return false;"><i class="fa fa-plus-square"></i></a>
			<ul class="hide"> <!-- Default: collapsed tree -->
				<xsl:for-each select="sub"><xsl:sort select="@uri"/>
					<xsl:variable name="about" select="@uri"/>
					<xsl:if test="not(exists($done[uri=$about]))">
						<xsl:apply-templates select="../../property[@uri=$about]" mode="makeClassTree2">
							<xsl:with-param name="done">
								<xsl:copy-of select="$done"/>
								<xsl:copy-of select="$new"/>
							</xsl:with-param>
							<xsl:with-param name="prefix" select="$prefix"/>
						</xsl:apply-templates>
					</xsl:if>
				</xsl:for-each>
			</ul>
		</xsl:if>
	</li>
</xsl:template>

<xsl:template match="rdf:RDF" mode="VocabularyAppearance">
	<xsl:variable name="ontology-prefix" select="replace(rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Ontology']/@rdf:about,'(#|/)[0-9A-Za-z-_~]*$','$1')"/>
	<xsl:variable name="prefix">
		<xsl:choose>
			<xsl:when test="$ontology-prefix!=''"><xsl:value-of select="$ontology-prefix"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="/results/context/url"/>#</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
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
			</property>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- All shapes -->
	<xsl:variable name="all-shapes">
		<xsl:for-each-group select="rdf:Description[exists(shacl:scopeClass) or exists(shacl:property)]" group-by="@rdf:about">
			<xsl:variable name="class" select="current-group()/shacl:scopeClass[1]/@rdf:resource"/>
			<shape class-uri="{$class}">
				<xsl:for-each select="current-group()/shacl:property">
					<xsl:variable name="property" select="@rdf:resource"/>
					<xsl:variable name="predicate" select="$all-predicates/property[@uri=$property]"/>
					<property uri="{$predicate/@predicate}">
						<xsl:if test="$predicate/ref-class/@uri!=''">
							<xsl:attribute name="refclass"><xsl:value-of select="$predicate/ref-class/@uri"/></xsl:attribute>
						</xsl:if>
					</property>
				</xsl:for-each>
				<xsl:apply-templates select="../rdf:Description[@rdf:about=$class]" mode="shape-propertyrec"/>
			</shape>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- All classes -->
	<xsl:variable name="all-classes">
		<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Class' or rdf:type/@rdf:resource='http://www.w3.org/2000/01/rdf-schema#Class']" group-by="@rdf:about">
			<xsl:variable name="about" select="@rdf:about"/>
			<class uri="{$about}">
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
	<!-- All properties -->
	<xsl:variable name="all-properties">
		<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#DatatypeProperty' or rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#ObjectProperty' or rdf:type/@rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#Property']" group-by="@rdf:about">
			<xsl:variable name="about" select="@rdf:about"/>
			<property uri="{$about}">
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
				<xsl:for-each-group select="$all-predicates/property[@predicate=$about]/ref-class" group-by="@uri">
					<ref-class uri="{@uri}"/>
				</xsl:for-each-group>
				<xsl:for-each-group select="$all-predicates/property[@predicate=$about]/datatype" group-by="@uri">
					<datatype uri="{@uri}"/>
				</xsl:for-each-group>
				<xsl:for-each-group select="$all-predicates/property[@predicate=$about]/domain" group-by="@uri">
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
	</xsl:variable>

	<xsl:variable name="ontology" select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Ontology'][1]"/>
	<xsl:variable name="title">
		<xsl:choose>
			<xsl:when test="$ontology/dcterms:title!=''"><xsl:value-of select="$ontology/dcterms:title"/></xsl:when>
			<xsl:when test="$ontology/dc:title!=''"><xsl:value-of select="$ontology/dc:title"/></xsl:when>
			<xsl:when test="$ontology/rdfs:label!=''"><xsl:value-of select="$ontology/rdfs:label"/></xsl:when>
			<xsl:when test="/root/context/subject!=''"><xsl:value-of select="/root/context/subject"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="ldt:label('Classes and properties')"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<ul class="nav nav-tabs">
		<li><a href="?format=ttl">ttl</a></li>
		<li><a href="?format=xml">xml</a></li>
		<li><a href="?format=json">json</a></li>
	</ul>

	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title">
				<xsl:choose>
					<xsl:when test="$ontology/@rdf:about!=''"><a href="{$ontology/@rdf:about}"><xsl:value-of select="$title"/></a></xsl:when>
					<xsl:otherwise><xsl:value-of select="$title"/></xsl:otherwise>
				</xsl:choose>
			</h3>
		</div>
		<div class="panel-body">
			<xsl:variable name="description"><xsl:value-of select="$ontology/rdfs:comment|$ontology/dc:description|$ontology/dcterms:description"/></xsl:variable>
			<div class="row">
				<div class="col-md-12">
					<xsl:if test="$description!=''">
						<p><xsl:value-of select="$description"/></p>
					</xsl:if>
					<xsl:for-each select="$ontology">
						<table class="basic-text-table">
							<tbody>
								<xsl:for-each select="foaf:homepage/@rdf:resource">
									<tr>
										<td>Homepage:</td>
										<td><a href="{.}"><xsl:value-of select="."/></a></td>
									</tr>
								</xsl:for-each>
								<xsl:for-each select="rdfs:seeAlso/@rdf:resource">
									<tr>
										<td>See also:</td>
										<td><a href="{.}"><xsl:value-of select="."/></a></td>
									</tr>
								</xsl:for-each>
								<xsl:for-each select="dcterms:status/@rdf:resource">
									<tr>
										<td>Status</td>
										<td><xsl:apply-templates select="." mode="link"/></td>
									</tr>
								</xsl:for-each>
								<xsl:for-each select="dcterms:creator/@rdf:resource">
									<tr>
										<td>Creator</td>
										<td><xsl:apply-templates select="." mode="link"/></td>
									</tr>
								</xsl:for-each>
								<xsl:for-each select="dcterms:contributor/@rdf:resource">
									<tr>
										<td>Contributor</td>
										<td><xsl:apply-templates select="." mode="link"/></td>
									</tr>
								</xsl:for-each>
								<xsl:for-each select="dcterms:publisher/@rdf:resource">
									<tr>
										<td>Publisher</td>
										<td><xsl:apply-templates select="." mode="link"/></td>
									</tr>
								</xsl:for-each>
							</tbody>
						</table>
					</xsl:for-each>
				</div>
			</div>
			<div class="row">
				<!-- Class tree -->
				<div class="col-md-6">
					<div class="nav-tree"><b><xsl:value-of select="ldt:label('Classes')"/></b>
						<ul style="max-height:500px; padding-bottom:20px; overflow-y: auto">
							<xsl:variable name="done">
								<xsl:for-each select="$all-classes/class[not(exists(super))]">
									<uri><xsl:value-of select="@uri"/></uri>
								</xsl:for-each>
							</xsl:variable>
							<xsl:for-each select="$all-classes/class[not(exists(super))]"><xsl:sort select="@uri"/>
								<xsl:apply-templates select="." mode="makeClassTree2">
									<xsl:with-param name="done" select="$done"/>
									<xsl:with-param name="prefix" select="$prefix"/>
								</xsl:apply-templates>
							</xsl:for-each>
						</ul>
					</div>
				</div>
				<!-- Property tree -->
				<div class="col-md-6">
					<div class="nav-tree"><b><xsl:value-of select="ldt:label('Properties')"/></b>
						<ul style="max-height:500px; padding-bottom:20px; overflow-y: auto">
							<xsl:variable name="done">
								<xsl:for-each select="$all-properties/property[not(exists(super))]">
									<uri><xsl:value-of select="@uri"/></uri>
								</xsl:for-each>
							</xsl:variable>
							<xsl:for-each select="$all-properties/property[not(exists(super))]"><xsl:sort select="@uri"/>
								<xsl:apply-templates select="." mode="makeClassTree2">
									<xsl:with-param name="done" select="$done"/>
									<xsl:with-param name="prefix" select="$prefix"/>
								</xsl:apply-templates>
							</xsl:for-each>
						</ul>
					</div>
				</div>
			</div>
		</div>
	</div>
	<!-- Show classes -->
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title"><xsl:value-of select="ldt:label('Classes')"/></h3>
		</div>
		<div class="panel-body">
			<xsl:for-each select="$all-classes/class[exists(property) and not(exists(@ref))]"><xsl:sort select="@uri"/>
				<xsl:apply-templates select="." mode="class-header2">
					<xsl:with-param name="prefix" select="$prefix"/>
				</xsl:apply-templates>
				<table class="basic-text-table">
					<tbody>
						<xsl:apply-templates select="." mode="class-table2">
							<xsl:with-param name="prefix" select="$prefix"/>
						</xsl:apply-templates>
						<tr>
							<td><xsl:value-of select="ldt:label('Properties include:')"/></td>
							<td>
								<xsl:for-each select="property"><xsl:sort select="@uri"/>
									<xsl:if test="position()!=1">, </xsl:if>
									<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
								</xsl:for-each>
							</td>
						</tr>
						<xsl:if test="exists(inherited-property)">
							<tr>
								<td><xsl:value-of select="ldt:label('Inherited properties:')"/></td>
								<td>
									<xsl:for-each select="inherited-property"><xsl:sort select="@uri"/>
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
						<xsl:if test="exists(refproperty)">
							<tr>
								<td><xsl:value-of select="ldt:label('Used with property:')"/></td>
								<td>
									<xsl:for-each select="refproperty"><xsl:sort select="@uri"/>
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
					</tbody>
				</table>
			</xsl:for-each>
			<xsl:for-each select="$all-classes/class[not(exists(property)) and not(exists(@ref))]"><xsl:sort select="@uri"/>
				<xsl:apply-templates select="." mode="class-header2">
					<xsl:with-param name="prefix" select="$prefix"/>
				</xsl:apply-templates>
				<table class="basic-text-table">
					<tbody>
						<xsl:apply-templates select="." mode="class-table2">
							<xsl:with-param name="prefix" select="$prefix"/>
						</xsl:apply-templates>
					</tbody>
				</table>
			</xsl:for-each>
		</div>
	</div>
	<!-- Show properties -->
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title"><xsl:value-of select="ldt:label('Properties')"/></h3>
		</div>
		<div class="panel-body">
			<xsl:for-each select="$all-properties/property[not(exists(@ref))]"><xsl:sort select="@uri"/>
				<xsl:variable name="puri" select="@uri"/>
				<xsl:variable name="name" select="replace(@uri,'^.*(#|/)([^(#|/)]+)$','$2')"/>
				<xsl:variable name="resource-uri"><xsl:call-template name="resource-uri"><xsl:with-param name="uri" select="@uri"/></xsl:call-template></xsl:variable>
				<h4 id="{$name}"><a href="{$resource-uri}"><xsl:value-of select="$name"/></a></h4>
				<p><i><xsl:value-of select="comment"/></i></p>
				<table class="basic-text-table">
					<tbody>
						<tr>
							<td><xsl:value-of select="ldt:label('URI:')"/></td>
							<td><xsl:value-of select="@uri"/></td>
						</tr>
						<tr>
							<td><xsl:value-of select="ldt:label('Property of:')"/></td>
							<td>
								<xsl:for-each select="scope-class"><xsl:sort select="@uri"/>
									<xsl:if test="position()!=1">, </xsl:if>
									<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
								</xsl:for-each>
							</td>
						</tr>
						<xsl:if test="exists(super)">
							<tr>
								<td><xsl:value-of select="ldt:label('Subproperty of:')"/></td>
								<td>
									<xsl:for-each select="super"><xsl:sort select="@uri"/>
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@uri" mode="link">
											<xsl:with-param name="prefix" select="$prefix"/>
											<xsl:with-param name="label" select="@label"/>
										</xsl:apply-templates>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
						<xsl:if test="exists(ref-class)">
							<tr>
								<td><xsl:value-of select="ldt:label('Class of object:')"/></td>
								<td>
									<xsl:for-each select="ref-class"><xsl:sort select="@uri"/>
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
						<xsl:if test="exists(datatype)">
							<tr>
								<td><xsl:value-of select="ldt:label('Datatype:')"/></td>
								<td>
									<xsl:for-each select="datatype">
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
						<xsl:if test="exists(domain)">
							<tr>
								<td><xsl:value-of select="ldt:label('Values from:')"/></td>
								<td>
									<xsl:for-each select="domain">
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
					</tbody>
				</table>
			</xsl:for-each>
		</div>
	</div>
	<script>
		function toggleNode(node) {
			if (node.parentElement.children[2].className!='') {
				node.children[0].className='fa fa-minus-square';
				node.parentElement.className='has-child';
				node.parentElement.children[2].className=''
			} else {
				node.children[0].className='fa fa-plus-square';
				node.parentElement.className='has-child tree-collapsed';
				node.parentElement.children[2].className='hide'
			}
		};
		function expandShallowNodes(cnt,node) {
			if ($(node).children("li").length+cnt&lt;20) {
				if (cnt!=0) {
					node.className='';
					node.parentElement.className='has-child';
					node.parentElement.children[1].children[0].className='fa fa-minus-square';
				}
				$(node).children("li").each(function() {
					if(this.children[2]) {
						cnt = expandShallowNodes($(node).children("li").length+cnt,this.children[2]);
					}
				});
			}
			return cnt
		}
		$(".nav-tree").each(function() {
			if ($(this).children("ul")) {
				expandShallowNodes(0,$(this).children("ul")[0]);
			}
		});
	</script>
</xsl:template>

</xsl:stylesheet>
