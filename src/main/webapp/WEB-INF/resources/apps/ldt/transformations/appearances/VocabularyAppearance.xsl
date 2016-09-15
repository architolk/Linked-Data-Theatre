<!--

    NAME     VocabularyAppearance.xsl
    VERSION  1.10.2-SNAPSHOT
    DATE     2016-09-15

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
	xmlns:shacl="http://www.w3.org/ns/shacl#"
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
			<term id="Used with:">Gebruikt bij:</term>
			<term id="Classes">Klassen</term>
			<term id="Properties">Eigenschappen</term>
			<term id="Classes:">Klassen:</term>
			<term id="Properties:">Eigenschappen:</term>
			<term id="Properties include:">Eigenschappen:</term>
			<term id="Property of:">Eigenschap van:</term>
			<term id="Class of object:">Gerelateerde klasse:</term>
			<term id="Datatype:">Datatype:</term>
			<term id="Values from:">Waarden uit:</term>
			<term id="Classes and properties">Klassen en eigenschappen</term>
		</list>
	</xsl:variable>

	<xsl:variable name="label" select="$terms/list[@lang=$language]/term[@id=$labelid]"/>
	<xsl:value-of select="$label"/>
	<xsl:if test="not($label!='')"><xsl:value-of select="$labelid"/></xsl:if>
</xsl:function>

<xsl:template match="@rdf:resource|@rdf:about|@uri" mode="link">
	<xsl:param name="prefix"/>
	
	<xsl:variable name="name" select="replace(.,'^.*(#|/)([^(#|/)]+)$','$2')"/>
	<xsl:choose>
		<xsl:when test="$name=substring-after(.,$prefix)">
			<a href="#{$name}"><xsl:value-of select="$name"/></a>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="resource-uri"><xsl:call-template name="resource-uri"><xsl:with-param name="uri" select="."/></xsl:call-template></xsl:variable>
			<a href="{$resource-uri}"><xsl:value-of select="$name"/></a>
		</xsl:otherwise>
	</xsl:choose>
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
					<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
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
	<!--
	<xsl:if test="exists(key('property-class',@rdf:about))">
		<tr>
			<td><xsl:value-of select="ldt:label('Used with:')"/></td>
			<td>
				<xsl:for-each select="key('property-class',@rdf:about)"><xsl:sort select="shacl:predicate/@rdf:resource"/>
					<xsl:if test="position()!=1">, </xsl:if>
					<xsl:apply-templates select="shacl:predicate/@rdf:resource" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
				</xsl:for-each>
			</td>
		</tr>
	</xsl:if>
	-->
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
	<xsl:variable name="ontology-prefix" select="replace(rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Ontology']/@rdf:about,'#([0-9A-Za-z-_~]*)$','')"/>
	<xsl:variable name="prefix">
		<xsl:choose>
			<xsl:when test="$ontology-prefix!=''"><xsl:value-of select="$ontology-prefix"/>#</xsl:when>
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
			<shape class-uri="{current-group()/shacl:scopeClass[1]/@rdf:resource}">
				<xsl:for-each select="current-group()/shacl:property">
					<xsl:variable name="property" select="@rdf:resource"/>
					<property uri="{$all-predicates/property[@uri=$property]/@predicate}"/>
				</xsl:for-each>
			</shape>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- All classes -->
	<xsl:variable name="all-classes">
		<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Class' or rdf:type/@rdf:resource='http://www.w3.org/2000/01/rdf-schema#Class']" group-by="@rdf:about">
			<xsl:variable name="about" select="@rdf:about"/>
			<class uri="{$about}">
				<xsl:for-each select="current-group()/rdfs:subClassOf">
					<super uri="{@rdf:resource}"/>
				</xsl:for-each>
				<xsl:for-each select="../rdf:Description[rdfs:subClassOf/@rdf:resource=$about]">
					<sub uri="{@rdf:about}"/>
				</xsl:for-each>
				<xsl:for-each select="current-group()/rdfs:comment">
					<comment><xsl:value-of select="."/></comment>
				</xsl:for-each>
				<xsl:copy-of select="$all-shapes/shape[@class-uri=$about]/property"/>
			</class>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- All properties -->
	<xsl:variable name="all-properties">
		<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#DatatypeProperty' or rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#ObjectProperty' or rdf:type/@rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#Property']" group-by="@rdf:about">
			<xsl:variable name="about" select="@rdf:about"/>
			<property uri="{$about}">
				<xsl:for-each select="$all-classes/class/property[@uri=$about]">
					<scope-class uri="{../@uri}"/>
				</xsl:for-each>
				<xsl:for-each-group select="$all-predicates/property[@predicate=$about]/ref-class" group-by="@uri">
					<ref-class uri="{@uri}"/>
				</xsl:for-each-group>
				<xsl:for-each-group select="$all-predicates/property[@predicate=$about]/datatype" group-by="@uri">
					<datatype uri="{@uri}"/>
				</xsl:for-each-group>
				<xsl:for-each-group select="$all-predicates/property[@predicate=$about]/domain" group-by="@uri">
					<domain uri="{@uri}"/>
				</xsl:for-each-group>
				<xsl:for-each select="current-group()/rdfs:comment">
					<comment><xsl:value-of select="."/></comment>
				</xsl:for-each>
			</property>
		</xsl:for-each-group>
	</xsl:variable>
	
	<xsl:copy-of select="$all-shapes"/>
	
	<xsl:variable name="ontology" select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Ontology'][1]"/>
	<xsl:variable name="title">
		<xsl:choose>
			<xsl:when test="$ontology/dcterms:title!=''"><xsl:value-of select="$ontology/dcterms:title"/></xsl:when>
			<xsl:when test="$ontology/rdfs:label!=''"><xsl:value-of select="$ontology/rdfs:label"/></xsl:when>
			<xsl:when test="/root/context/subject!=''"><xsl:value-of select="/root/context/subject"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="ldt:label('Classes and properties')"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
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
			<xsl:variable name="description"><xsl:value-of select="$ontology/rdfs:comment"/></xsl:variable>
			<xsl:if test="$description!=''">
				<div class="row">
					<div class="col-md-12"><xsl:value-of select="$description"/></div>
				</div>
			</xsl:if>
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
			<xsl:for-each select="$all-classes/class[exists(property)]"><xsl:sort select="@uri"/>
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
					</tbody>
				</table>
			</xsl:for-each>
			<xsl:for-each select="$all-classes/class[not(exists(property))]"><xsl:sort select="@uri"/>
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
			<xsl:for-each select="$all-properties/property"><xsl:sort select="@uri"/>
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
						<xsl:if test="exists(class)">
							<tr>
								<td><xsl:value-of select="ldt:label('Class of object:')"/></td>
								<td>
									<xsl:for-each select="class"><xsl:sort select="@uri"/>
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
	</script>
</xsl:template>

</xsl:stylesheet>
