<!--

    NAME     VocabularyAppearance.xsl
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
	VocabularyAppearance, add-on of rdf2html.xsl
	
	A Vocabulary appearance presents a vocabulary as a single html page with anchors.

	Depended on: ModelTemplates.xsl

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
			<term id="Properties from ">Eigenschappen via </term>
			<term id="Property of:">Eigenschap van:</term>
			<term id="Class of object:">Gerelateerde klasse:</term>
			<term id="Datatype:">Datatype:</term>
			<term id="Values from:">Waarden uit:</term>
			<term id="Possible values:">Mogelijke waarden:</term>
			<term id="Classes and properties">Klassen en eigenschappen</term>
			<term id="Used with property:">Gebruikt bij eigenschap:</term>
			<term id="Value pattern:">Waarde patroon:</term>
			<term id="Max length:">Maximale lengte:</term>
			<term id="between ">tussen </term>
			<term id=" and "> en </term>
			<term id="from ">vanaf </term>
			<term id="up to ">tot en met </term>
		</list>
	</xsl:variable>

	<xsl:variable name="label" select="$terms/list[@lang=$language]/term[@id=$labelid]"/>
	<xsl:value-of select="$label"/>
	<xsl:if test="not($label!='')"><xsl:value-of select="$labelid"/></xsl:if>
</xsl:function>

<xsl:template match="@rdf:resource|@rdf:about|@uri|@predicate" mode="link">
	<xsl:param name="owneditems"/>
	<xsl:param name="label"/>

	<xsl:variable name="uri" select="."/>
	<xsl:variable name="name"><xsl:value-of select="replace($uri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:variable>
	<xsl:variable name="label">
		<xsl:value-of select="$label"/>
		<xsl:if test="not($label!='')"><xsl:value-of select="$name"/></xsl:if>
	</xsl:variable>
	<xsl:variable name="owned">
		<xsl:for-each select="$owneditems/prefix">
			<xsl:if test="starts-with($uri,.)">x</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$owned!='' or exists($owneditems/item[.=$uri])">
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

<xsl:template match="class" mode="class-header2">
	<xsl:param name="owneditems"/> <!-- TODO: Waarom is deze parameter nodig? -->
	
	<xsl:variable name="name" select="replace(@uri,'^.*(#|/)([^(#|/)]+)$','$2')"/>
	<xsl:variable name="resource-uri"><xsl:call-template name="resource-uri"><xsl:with-param name="uri" select="@uri"/></xsl:call-template></xsl:variable>
	<h4 id="{$name}"><a href="{$resource-uri}"><xsl:value-of select="$name"/></a></h4>
	<p><i><xsl:value-of select="comment"/></i></p>
</xsl:template>

<xsl:template match="class" mode="class-table2">
	<xsl:param name="owneditems"/>

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
						<xsl:with-param name="owneditems" select="$owneditems"/>
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
					<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="owneditems" select="$owneditems"/></xsl:apply-templates>
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
						<xsl:with-param name="owneditems" select="$owneditems"/>
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
	<xsl:param name="owneditems"/>
	<xsl:variable name="class-uri" select="@uri"/>
	<xsl:variable name="new">
		<xsl:for-each select="sub">
			<xsl:variable name="about" select="@uri"/>
			<xsl:if test="not(exists($done[uri=$about]))">
				<uri><xsl:value-of select="$about"/></uri>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	<li>
		<xsl:if test="exists($new/uri) or exists(role-shape)"><xsl:attribute name="class">has-child tree-collapsed</xsl:attribute></xsl:if>
		<p><xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="owneditems" select="$owneditems"/></xsl:apply-templates></p>
		<xsl:if test="exists($new/uri) or exists(role-shape)">
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
							<xsl:with-param name="owneditems" select="$owneditems"/>
						</xsl:apply-templates>
					</xsl:if>
				</xsl:for-each>
				<xsl:for-each select="role-shape"><xsl:sort select="@uri"/>
					<li>
						<p>
							<xsl:apply-templates select="$class-uri" mode="link">
								<xsl:with-param name="owneditems" select="$owneditems"/>
								<xsl:with-param name="label">&#x00AB;<xsl:value-of select="replace(@uri,'^.*(#|/)([^(#|/)]+)$','$2')"/>&#x00BB;</xsl:with-param>
							</xsl:apply-templates>
						</p>
					</li>
				</xsl:for-each>
			</ul>
		</xsl:if>
	</li>
</xsl:template>
<xsl:template match="property" mode="makeClassTree2">
	<!-- To avoid cycles, a resource can be present only ones -->
	<xsl:param name="done"/>
	<xsl:param name="owneditems"/>
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
		<p><xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="owneditems" select="$owneditems"/></xsl:apply-templates></p>
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
							<xsl:with-param name="owneditems" select="$owneditems"/>
						</xsl:apply-templates>
					</xsl:if>
				</xsl:for-each>
			</ul>
		</xsl:if>
	</li>
</xsl:template>

<xsl:template match="rdf:RDF" mode="VocabularyAppearance">
	<!-- Parse RDF graph and put result in vocabulary variable -->
	<xsl:variable name="vocabulary"><xsl:apply-templates select="." mode="VocabularyVariable"/></xsl:variable>
	<!-- Expect one ontology -->
	<xsl:variable name="onto-prefix"><xsl:value-of select="$vocabulary/ontology[1]/@prefix"/></xsl:variable>
	<!-- All classes that have non-empty shapes are part of the deal as well -->
	<xsl:variable name="owneditems">
		<xsl:choose>
			<xsl:when test="$onto-prefix!=''">
				<xsl:for-each select="$vocabulary/ontology[@prefix!='']/@prefix">
					<prefix><xsl:value-of select="."/></prefix>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise><prefix>~</prefix></xsl:otherwise>
		</xsl:choose>
		<xsl:for-each-group select="$vocabulary/nodeShapes/shape[@class-uri!='' and @empty='false']" group-by="@class-uri">
			<item><xsl:value-of select="@class-uri"/></item>
		</xsl:for-each-group>
		<xsl:for-each-group select="$vocabulary/nodeShapes/shape/property" group-by="@uri">
			<item><xsl:value-of select="@uri"/></item>
		</xsl:for-each-group>
	</xsl:variable>
<!--
<xsl:copy-of select="$vocabulary"/>
-->
	
	<ul class="nav nav-tabs">
		<li><a href="?format=ttl">ttl</a></li>
		<li><a href="?format=xml">xml</a></li>
		<li><a href="?format=json">json</a></li>
		<li><a href="?format=yed">graphml</a></li>
	</ul>
	
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title">
				<xsl:choose>
					<xsl:when test="$vocabulary/ontology/@uri!=''"><a href="{$vocabulary/ontology/@uri}"><xsl:value-of select="$vocabulary/ontology/@title"/></a></xsl:when>
					<xsl:otherwise>Classes and properties</xsl:otherwise>
				</xsl:choose>
			</h3>
		</div>
		<div class="panel-body">
			<div class="row">
				<div class="col-md-12">
					<xsl:for-each select="$vocabulary/ontology">
						<xsl:if test="description!=''">
							<p><xsl:value-of select="description"/></p>
						</xsl:if>
						<table class="basic-text-table">
							<tbody>
								<xsl:for-each select="homepage">
									<tr>
										<td>Homepage:</td>
										<td><a href="{.}"><xsl:value-of select="."/></a></td>
									</tr>
								</xsl:for-each>
								<xsl:for-each select="see-also">
									<tr>
										<td>See also:</td>
										<td><a href="{.}"><xsl:value-of select="."/></a></td>
									</tr>
								</xsl:for-each>
								<xsl:for-each select="status">
									<tr>
										<td>Status</td>
										<td><xsl:apply-templates select="." mode="link"/></td>
									</tr>
								</xsl:for-each>
								<xsl:for-each select="creator">
									<tr>
										<td>Creator</td>
										<td><xsl:apply-templates select="." mode="link"/></td>
									</tr>
								</xsl:for-each>
								<xsl:for-each select="contributor">
									<tr>
										<td>Contributor</td>
										<td><xsl:apply-templates select="." mode="link"/></td>
									</tr>
								</xsl:for-each>
								<xsl:for-each select="publisher">
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
								<xsl:for-each select="$vocabulary/classes/class[not(exists(super))]">
									<uri><xsl:value-of select="@uri"/></uri>
								</xsl:for-each>
							</xsl:variable>
							<xsl:for-each select="$vocabulary/classes/class[not(exists(super))]"><xsl:sort select="@uri"/>
								<xsl:apply-templates select="." mode="makeClassTree2">
									<xsl:with-param name="done" select="$done"/>
									<xsl:with-param name="owneditems" select="$owneditems"/>
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
								<xsl:for-each select="$vocabulary/properties/property[not(exists(super))]">
									<uri><xsl:value-of select="@uri"/></uri>
								</xsl:for-each>
							</xsl:variable>
							<xsl:for-each select="$vocabulary/properties/property[not(exists(super))]"><xsl:sort select="@uri"/>
								<xsl:apply-templates select="." mode="makeClassTree2">
									<xsl:with-param name="done" select="$done"/>
									<xsl:with-param name="owneditems" select="$owneditems"/>
								</xsl:apply-templates>
							</xsl:for-each>
						</ul>
					</div>
				</div>
			</div>
		</div>
	</div>
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title"><xsl:value-of select="ldt:label('Classes')"/></h3>
		</div>
		<div class="panel-body">
			<xsl:for-each select="$vocabulary/classes/class[not(exists(@ref))]"><xsl:sort select="@uri"/>
				<xsl:apply-templates select="." mode="class-header2">
					<xsl:with-param name="owneditems" select="$owneditems"/>
				</xsl:apply-templates>
				<table class="basic-text-table">
					<tbody>
						<xsl:apply-templates select="." mode="class-table2">
							<xsl:with-param name="owneditems" select="$owneditems"/>
						</xsl:apply-templates>
						<xsl:variable name="shape" select="shape/@uri"/>
						<xsl:if test="$shape!=''">
							<tr>
								<td><xsl:value-of select="ldt:label('Properties include:')"/></td>
								<td>
									<xsl:for-each select="$vocabulary/nodeShapes/shape[@uri=$shape]/property"><xsl:sort select="@uri"/>
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="owneditems" select="$owneditems"/></xsl:apply-templates>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
						<xsl:for-each select="role-shape">
							<xsl:variable name="shape" select="@uri"/>
							<tr>
								<td>- <xsl:value-of select="$vocabulary/nodeShapes/shape[@uri=$shape]/@name"/></td>
								<td>
									<xsl:for-each select="$vocabulary/nodeShapes/shape[@uri=$shape]/property"><xsl:sort select="@uri"/>
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="owneditems" select="$owneditems"/></xsl:apply-templates>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:for-each>
						<xsl:if test="exists(inherited-shape/@uri)">
							<tr>
								<td><xsl:value-of select="ldt:label('Inherited properties:')"/></td>
								<td>
									<xsl:for-each select="inherited-shape">
										<xsl:variable name="shape" select="@uri"/>
										<xsl:for-each select="$vocabulary/nodeShapes/shape[@uri=$shape]/property"><xsl:sort select="@uri"/>
											<xsl:if test="position()!=1">, </xsl:if>
											<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="owneditems" select="$owneditems"/></xsl:apply-templates>
										</xsl:for-each>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
						<xsl:if test="exists(refproperty/@uri)">
							<tr>
								<td><xsl:value-of select="ldt:label('Used with property:')"/></td>
								<td>
									<xsl:for-each-group select="refproperty" group-by="@predicate"><xsl:sort select="@predicate"/>
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@predicate" mode="link"><xsl:with-param name="owneditems" select="$owneditems"/></xsl:apply-templates>
									</xsl:for-each-group>
								</td>
							</tr>
						</xsl:if>
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
			<xsl:for-each select="$vocabulary/properties/property[not(exists(@ref))]"><xsl:sort select="@uri"/>
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
						<xsl:if test="exists(scope-class)">
							<tr>
								<td><xsl:value-of select="ldt:label('Property of:')"/></td>
								<td>
									<xsl:for-each select="scope-class"><xsl:sort select="@uri"/>
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="owneditems" select="$owneditems"/></xsl:apply-templates>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
						<xsl:if test="exists(super)">
							<tr>
								<td><xsl:value-of select="ldt:label('Subproperty of:')"/></td>
								<td>
									<xsl:for-each select="super"><xsl:sort select="@uri"/>
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:apply-templates select="@uri" mode="link">
											<xsl:with-param name="owneditems" select="$owneditems"/>
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
										<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="owneditems" select="$owneditems"/></xsl:apply-templates>
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
										<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="owneditems" select="$owneditems"/></xsl:apply-templates>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
						<xsl:if test="exists(pattern)">
							<tr>
								<td><xsl:value-of select="ldt:label('Value pattern:')"/></td>
								<td>
									<xsl:for-each select="pattern">
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:choose>
											<xsl:when test="@minInclusive!='' and @maxInclusive!=''">
												<xsl:value-of select="ldt:label('between ')"/>
												<xsl:value-of select="@minInclusive"/>
												<xsl:value-of select="ldt:label(' and ')"/>
												<xsl:value-of select="@maxInclusive"/>
											</xsl:when>
											<xsl:when test="@minInclusive!=''">
												<xsl:value-of select="ldt:label('from ')"/>
												<xsl:value-of select="@minInclusive"/>
											</xsl:when>
											<xsl:when test="@maxInclusive!=''">
												<xsl:value-of select="ldt:label('up to ')"/>
												<xsl:value-of select="@maxInclusive"/>
											</xsl:when>
											<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
										</xsl:choose>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
						<xsl:if test="exists(maxLength)">
							<tr>
								<td><xsl:value-of select="ldt:label('Max length:')"/></td>
								<td>
									<xsl:for-each select="maxLength">
										<xsl:if test="position()!=1">, </xsl:if>
										<xsl:value-of select="."/>
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
										<xsl:apply-templates select="@uri" mode="link"><xsl:with-param name="owneditems" select="$owneditems"/></xsl:apply-templates>
									</xsl:for-each>
								</td>
							</tr>
						</xsl:if>
						<xsl:if test="exists(valuelist)">
							<xsl:for-each select="valuelist">
								<xsl:variable name="shape" select="@shape"/>
								<tr>
									<td><xsl:value-of select="ldt:label('Possible values:')"/> (<xsl:value-of select="$vocabulary/nodeShapes/shape[@uri=$shape]/@name"/>)</td>
									<td>
										<xsl:for-each select="item">
											<xsl:if test="position()!=1">, </xsl:if>
											<xsl:choose>
												<xsl:when test="exists(@uri)">
													<xsl:apply-templates select="@uri" mode="link">
														<xsl:with-param name="owneditems" select="$owneditems"/>
													</xsl:apply-templates>
												</xsl:when>
												<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</td>
								</tr>
							</xsl:for-each>
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
