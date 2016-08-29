<!--

    NAME     VocabularyAppearance.xsl
    VERSION  1.10.0
    DATE     2016-08-29

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

<xsl:key name="node" match="rdf:RDF/rdf:Description" use="@rdf:about"/>
<xsl:key name="shape" match="rdf:RDF/rdf:Description" use="shacl:property/@rdf:resource"/>
<xsl:key name="shape-class" match="rdf:RDF/rdf:Description" use="shacl:scopeClass/@rdf:resource"/>
<xsl:key name="pc" match="rdf:RDF/rdf:Description" use="shacl:predicate/@rdf:resource"/>
<xsl:key name="super" match="rdf:RDF/rdf:Description" use="rdfs:subClassOf/@rdf:resource"/>
<xsl:key name="property-class" match="rdf:RDF/rdf:Description" use="shacl:class/@rdf:resource"/>

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
		</list>
	</xsl:variable>

	<xsl:variable name="label" select="$terms/list[@lang=$language]/term[@id=$labelid]"/>
	<xsl:value-of select="$label"/>
	<xsl:if test="not($label!='')"><xsl:value-of select="$labelid"/></xsl:if>
</xsl:function>

<xsl:template match="@rdf:resource|@rdf:about" mode="link">
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

<xsl:template match="rdf:Description" mode="class-header">
	<xsl:param name="prefix"/>
	
	<xsl:variable name="name" select="replace(@rdf:about,'^.*(#|/)([^(#|/)]+)$','$2')"/>
	<xsl:variable name="resource-uri"><xsl:call-template name="resource-uri"><xsl:with-param name="uri" select="@rdf:about"/></xsl:call-template></xsl:variable>
	<h4 id="{$name}"><a href="{$resource-uri}"><xsl:value-of select="$name"/></a></h4>
	<p><i><xsl:value-of select="rdfs:comment"/></i></p>
</xsl:template>

<xsl:template match="rdf:Description" mode="class-table">
	<xsl:param name="prefix"/>

	<tr>
		<td><xsl:value-of select="ldt:label('URI:')"/></td>
		<td><xsl:value-of select="@rdf:about"/></td>
	</tr>
	<xsl:if test="exists(rdfs:subClassOf)">
		<tr>
			<td><xsl:value-of select="ldt:label('Subclass of:')"/></td>
			<td><xsl:apply-templates select="rdfs:subClassOf/@rdf:resource" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates></td>
		</tr>
	</xsl:if>
	<xsl:if test="exists(key('super',@rdf:about))">
		<tr>
			<td><xsl:value-of select="ldt:label('Has subclasses:')"/></td>
			<td>
				<xsl:for-each select="key('super',@rdf:about)"><xsl:sort select="@rdf:about"/>
					<xsl:if test="position()!=1">, </xsl:if>
					<xsl:apply-templates select="@rdf:about" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
				</xsl:for-each>
			</td>
		</tr>
	</xsl:if>
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
</xsl:template>

<xsl:template match="rdf:Description" mode="makeClassTree">
	<!-- To avoid cycles, a resource can be present only ones -->
	<xsl:param name="done"/>
	<xsl:param name="prefix"/>
	<xsl:variable name="uri" select="@rdf:about"/>
	<xsl:variable name="new">
		<xsl:for-each select="../rdf:Description[rdfs:subClassOf/@rdf:resource=$uri]">
			<xsl:variable name="about" select="@rdf:about"/>
			<xsl:if test="not(exists($done[uri=$about]))">
				<uri><xsl:value-of select="."/></uri>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	<li>
		<xsl:if test="exists($new/uri)"><xsl:attribute name="class">has-child tree-collapsed</xsl:attribute></xsl:if>
		<p><xsl:apply-templates select="@rdf:about" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates></p>
		<xsl:if test="exists($new/uri)">
			<a class="" href="#" onclick="toggleNode(this);return false;"><i class="fa fa-plus-square"></i></a>
			<ul class="hide"> <!-- Default: collapsed tree -->
				<xsl:for-each select="../rdf:Description[rdfs:subClassOf/@rdf:resource=$uri]"><xsl:sort select="@rdf:about"/>
					<xsl:variable name="about" select="@rdf:about"/>
					<xsl:if test="not(exists($done[uri=$about]))">
						<xsl:apply-templates select="." mode="makeClassTree">
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
	
	<xsl:for-each select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Ontology']">
		<div class="panel panel-primary">
			<div class="panel-heading">
				<h3 class="panel-title"><a href="{@rdf:about}"><xsl:value-of select="rdfs:label|dcterms:title"/></a></h3>
			</div>
			<div class="panel-body">
				<xsl:variable name="description"><xsl:value-of select="rdfs:comment|dcterms:description"/></xsl:variable>
				<xsl:if test="$description!=''">
					<div class="row">
						<xsl:value-of select="$description"/>
					</div>
				</xsl:if>
				<div class="row">
					<div class="col-md-6">
						<div class="nav-tree"><b><xsl:value-of select="ldt:label('Classes')"/></b>
							<ul>
								<xsl:variable name="done">
									<xsl:for-each select="../rdf:Description[(rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Class' or rdf:type/@rdf:resource='http://www.w3.org/2000/01/rdf-schema#Class') and not(exists(rdfs:subClassOf/@rdf:resource))]/@rdf:about">
										<uri><xsl:value-of select="."/></uri>
									</xsl:for-each>
								</xsl:variable>
								<xsl:for-each select="../rdf:Description[(rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Class' or rdf:type/@rdf:resource='http://www.w3.org/2000/01/rdf-schema#Class') and not(exists(rdfs:subClassOf/@rdf:resource))]"><xsl:sort select="@rdf:about"/>
									<xsl:apply-templates select="." mode="makeClassTree">
										<xsl:with-param name="done" select="$done"/>
										<xsl:with-param name="prefix" select="$prefix"/>
									</xsl:apply-templates>
								</xsl:for-each>
							</ul>
						</div>
					</div>
					<div class="col-md-6">
						<div class="nav-tree"><b><xsl:value-of select="ldt:label('Properties')"/></b>
							<ul>
								<xsl:variable name="done">
									<xsl:for-each select="../rdf:Description[(rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#DatatypeProperty' or rdf:type/@rdf:resource='http://www.w3.org/2000/01/rdf-schema#ObjectProperty') and not(exists(rdfs:subPropertyOf/@rdf:resource))]/@rdf:about">
										<uri><xsl:value-of select="."/></uri>
									</xsl:for-each>
								</xsl:variable>
								<xsl:for-each select="../rdf:Description[(rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#DatatypeProperty' or rdf:type/@rdf:resource='http://www.w3.org/2000/01/rdf-schema#ObjectProperty') and not(exists(rdfs:subPropertyOf/@rdf:resource))]"><xsl:sort select="@rdf:about"/>
									<xsl:apply-templates select="." mode="makeClassTree">
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
	</xsl:for-each>
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title"><xsl:value-of select="ldt:label('Classes')"/></h3>
		</div>
		<div class="panel-body">
			<xsl:for-each select="rdf:Description[exists(shacl:scopeClass)]"><xsl:sort select="@rdf:about"/>
				<xsl:apply-templates select="key('node',shacl:scopeClass/@rdf:resource)" mode="class-header">
					<xsl:with-param name="prefix" select="$prefix"/>
				</xsl:apply-templates>
				<table class="basic-text-table">
					<tbody>
						<xsl:apply-templates select="key('node',shacl:scopeClass/@rdf:resource)" mode="class-table">
							<xsl:with-param name="prefix" select="$prefix"/>
						</xsl:apply-templates>
						<tr>
							<td><xsl:value-of select="ldt:label('Properties include:')"/></td>
							<td>
								<xsl:for-each select="key('node',shacl:property/@rdf:resource)"><xsl:sort select="shacl:predicate/@rdf:resource"/>
									<xsl:if test="position()!=1">, </xsl:if>
									<xsl:apply-templates select="shacl:predicate/@rdf:resource" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
								</xsl:for-each>
							</td>
						</tr>
					</tbody>
				</table>
			</xsl:for-each>
			<xsl:for-each select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Class' or rdf:type/@rdf:resource='http://www.w3.org/2000/01/rdf-schema#Class']">
				<xsl:if test="not(exists(key('shape-class',@rdf:about)))">
					<xsl:apply-templates select="." mode="class-header">
						<xsl:with-param name="prefix" select="$prefix"/>
					</xsl:apply-templates>
					<table class="basic-text-table">
						<tbody>
							<xsl:apply-templates select="." mode="class-table">
								<xsl:with-param name="prefix" select="$prefix"/>
							</xsl:apply-templates>
						</tbody>
					</table>
				</xsl:if>
			</xsl:for-each>
		</div>
	</div>
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title"><xsl:value-of select="ldt:label('Properties')"/></h3>
		</div>
		<div class="panel-body">
			<xsl:for-each select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#DatatypeProperty' or rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#ObjectProperty' or rdf:type/@rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#Property']"><xsl:sort select="@rdf:about"/>
				<xsl:variable name="puri" select="@rdf:about"/>
				<xsl:variable name="name" select="replace(@rdf:about,'^.*(#|/)([^(#|/)]+)$','$2')"/>
				<xsl:variable name="resource-uri"><xsl:call-template name="resource-uri"><xsl:with-param name="uri" select="@rdf:about"/></xsl:call-template></xsl:variable>
				<h4 id="{$name}"><a href="{$resource-uri}"><xsl:value-of select="$name"/></a></h4>
				<p><i><xsl:value-of select="rdfs:comment"/></i></p>
				<table class="basic-text-table">
					<tbody>
						<tr>
							<td><xsl:value-of select="ldt:label('URI:')"/></td>
							<td><xsl:value-of select="@rdf:about"/></td>
						</tr>
						<tr>
							<td><xsl:value-of select="ldt:label('Property of:')"/></td>
							<td>
								<xsl:for-each select="key('shape',key('pc',$puri)/@rdf:about)/shacl:scopeClass"><xsl:sort select="@rdf:resource"/>
									<xsl:if test="position()!=1">, </xsl:if>
									<xsl:apply-templates select="@rdf:resource" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
								</xsl:for-each>
							</td>
						</tr>
						<xsl:if test="exists(key('pc',$puri)/shacl:class)">
							<tr>
								<td><xsl:value-of select="ldt:label('Class of object:')"/></td>
								<td>
									<xsl:for-each-group select="key('pc',$puri)/shacl:class" group-by="@rdf:resource">
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@rdf:resource" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
									</xsl:for-each-group>
								</td>
							</tr>
						</xsl:if>
						<xsl:if test="exists(key('pc',$puri)/shacl:datatype)">
							<tr>
								<td><xsl:value-of select="ldt:label('Datatype:')"/></td>
								<td>
									<xsl:for-each-group select="key('pc',$puri)/shacl:datatype" group-by="@rdf:resource">
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@rdf:resource" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
									</xsl:for-each-group>
								</td>
							</tr>
						</xsl:if>
						<xsl:if test="exists(key('pc',$puri)/shacl:in)">
							<tr>
								<td><xsl:value-of select="ldt:label('Values from:')"/></td>
								<td>
									<xsl:for-each-group select="key('pc',$puri)/shacl:in" group-by="@rdf:resource">
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@rdf:resource" mode="link"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
									</xsl:for-each-group>
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