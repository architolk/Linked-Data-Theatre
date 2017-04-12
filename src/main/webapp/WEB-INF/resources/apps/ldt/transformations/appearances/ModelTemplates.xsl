<!--

    NAME     ModelTemplates.xsl
    VERSION  1.16.1-SNAPSHOT
    DATE     2017-04-11

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
	Model templates contains some generic templates for processing a shacl graph, vocabulary or ontology
	
	This template is used by:
	- VocabularyAppearance
	- ModelAppearance
	
	NB: This templates uses both versions of shacl (for backward compatibility):
		sh:path and sh:predicate (old)
		sh:targetClass and sh:scopeClass (old)
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:sh="http://www.w3.org/ns/shacl#"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:foaf="http://xmlns.com/foaf/0.1/"
>

<xsl:template match="rdf:Description" mode="supershape-rec">
<!-- Input: class, Output: the supertype of the shape of the class, recursive -->
<!-- WARNING: No check is made regarding loops!!! -->
	<xsl:for-each select="rdfs:subClassOf">
		<xsl:variable name="super" select="@rdf:resource"/>
		<xsl:for-each select="../../rdf:Description[(sh:scopeClass|sh:targetClass)/@rdf:resource=$super]"> <!-- TODO: Remove deprecated sh:scopeClass -->
			<inherited-shape uri="{@rdf:about}"/>
		</xsl:for-each>
		<xsl:apply-templates select="../../rdf:Description[@rdf:about=$super]" mode="supershape-rec"/>
	</xsl:for-each>
</xsl:template>


<xsl:template match="rdf:RDF" mode="VocabularyVariable">
	<!-- All property shapes -->
	<!-- Currently limited to simple paths, where the path is equal to the predicate -->
	<xsl:variable name="all-property-shapes">
		<xsl:for-each-group select="rdf:Description[exists(sh:path|sh:predicate)]" group-by="@rdf:about|@rdf:nodeID"> <!-- TODO: Remove deprecated sh:path -->
			<propertyShape name="{sh:name[1]}" uri="{@rdf:about|@rdf:nodeID}" predicate="{(sh:path|sh:predicate)/@rdf:resource}"> <!-- TODO: Remove deprecated sh:path -->
				<xsl:for-each select="current-group()/sh:class">
					<ref-class uri="{@rdf:resource}"/>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:datatype">
					<datatype uri="{@rdf:resource}"/>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:in"> <!-- TODO: Remove this part: sh:in is deprecated, and should be done differently -->
					<domain uri="{@rdf:resource}"/>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:node">
					<xsl:variable name="refnode" select="@rdf:nodeID|@rdf:resource"/>
					<ref-node uri="{$refnode}"/> <!-- Ref-node is an alternative to sh:class, more specific to a specific shape. But also blank ref-nodes are possible! -->
					<!-- A particular refnode could be defined as scoping the values. This defines the domain -->
					<!-- Conditions should be: only the first sh:property (such a node should have only one sh:property), and should contain a targetNode -->
					<xsl:for-each select="../../rdf:Description[@rdf:about=$refnode or @rdf:nodeID=$refnode]/sh:property">
						<xsl:if test="position()=1"> <!-- Only the first -->
							<xsl:variable name="refproperty" select="@rdf:resource|@rdf:nodeID"/>
							<xsl:for-each select="../../rdf:Description[@rdf:about=$refproperty or @rdf:nodeID=$refproperty]/sh:targetNode">
								<domain uri="{@rdf:resource}"/>
							</xsl:for-each>
						</xsl:if>
					</xsl:for-each>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:minCount">
					<mincount><xsl:value-of select="."/></mincount>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:maxCount">
					<maxcount><xsl:value-of select="."/></maxcount>
				</xsl:for-each>
				<xsl:for-each select="current-group()/rdfs:label">
					<label>
						<xsl:if test="@xml:lang!=''"><xsl:attribute name="xml:lang"><xsl:value-of select="@xml:lang"/></xsl:attribute></xsl:if>
						<xsl:value-of select="."/>
					</label>
				</xsl:for-each>
			</propertyShape>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- All node shapes -->
	<xsl:variable name="all-node-shapes">
		<xsl:for-each-group select="rdf:Description[exists(sh:scopeClass|sh:targetClass|sh:property|rdf:type[@rdf:resource='http://www.w3.org/ns/shacl#NodeShape'])]" group-by="@rdf:about"> <!-- TODO: Remove deprecated sh:scopeClass -->
			<xsl:variable name="class"><xsl:value-of select="current-group()/(sh:scopeClass|sh:targetClass)[1]/@rdf:resource"/></xsl:variable> <!-- TODO: Remove deprecated sh:scopeClass -->
			<shape name="{sh:name[1]}" uri="{@rdf:about}">
				<xsl:if test="$class!=''"><xsl:attribute name="class-uri"><xsl:value-of select="$class"/></xsl:attribute></xsl:if>
				<xsl:for-each select="current-group()/rdfs:label">
					<label>
						<xsl:if test="@xml:lang!=''"><xsl:attribute name="xml:lang"><xsl:value-of select="@xml:lang"/></xsl:attribute></xsl:if>
						<xsl:value-of select="."/>
					</label>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:property">
					<xsl:variable name="property" select="@rdf:resource|@rdf:nodeID"/>
					<xsl:variable name="predicate" select="$all-property-shapes/propertyShape[@uri=$property]"/>
					<!-- If predicate doesn't exists, the shacl shape refers to an unknown predicate constraint! -->
					<xsl:if test="exists($predicate)">
						<xsl:variable name="refclass" select="$predicate/ref-class/@uri"/>
						<xsl:variable name="refnode" select="$predicate/ref-node/@uri"/>
						<property name="{$predicate/@name}" uri="{$predicate/@predicate}">
							<xsl:if test="$refclass!=''">
								<xsl:attribute name="refclass"><xsl:value-of select="$refclass"/></xsl:attribute>
							</xsl:if>
							<xsl:if test="$refnode!=''">
								<xsl:attribute name="refnode"><xsl:value-of select="$refnode"/></xsl:attribute>
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
							<xsl:if test="$predicate/datatype[1]/@uri!=''">
								<xsl:attribute name="datatype"><xsl:value-of select="$predicate/datatype[1]/@uri"/></xsl:attribute>
							</xsl:if>
							<xsl:if test="$predicate/domain[1]/@uri!=''">
								<xsl:attribute name="domain"><xsl:value-of select="$predicate/domain[1]/@uri"/></xsl:attribute>
							</xsl:if>
							<!-- A particular refnode could be defined as scoping the values. This defines the domain -->
							<!-- Conditions should be: only the first sh:property (such a node should have only one sh:property), and should contain a targetNode -->
							<!--
							<xsl:for-each select="../../rdf:Description[@rdf:about=$refnode or @rdf:nodeID=$refnode]/sh:property">
								<xsl:if test="position()=1">
									<xsl:variable name="refproperty" select="@rdf:resource|@rdf:nodeID"/>
									<xsl:variable name="domain" select="$all-property-shapes/propertyShape[@uri=$refproperty]/target-node/@uri"/>
									<xsl:if test="$domain!=''">
										<xsl:attribute name="domain"><xsl:value-of select="$domain"/></xsl:attribute>
									</xsl:if>
								</xsl:if>
							</xsl:for-each>
							-->
							<xsl:copy-of select="$predicate/label"/>
							<!-- Refshapes are all shapes that have the particular refclass as target. @refnode contains a particular explicitly definied shape. Typically, this is one of the refshapes -->
							<xsl:for-each select="../../rdf:Description[(sh:scopeClass|sh:targetClass)/@rdf:resource=$refclass]"> <!-- TODO: Remove deprecated sh:scopeClass -->
								<refshape uri="{@rdf:about}"/>
							</xsl:for-each>
						</property>
					</xsl:if>
				</xsl:for-each>
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
				<xsl:for-each select="$all-node-shapes/shape[@class-uri=$about]">
					<shape uri="{@uri}"/>
				</xsl:for-each>
				<xsl:for-each-group select="$all-property-shapes/propertyShape[ref-class/@uri=$about]" group-by="@uri">
					<refproperty uri="{@uri}" predicate="{@predicate}"/>
				</xsl:for-each-group>
				<xsl:apply-templates select="." mode="supershape-rec"/>
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

	<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Ontology']" group-by="@rdf:about">
		<xsl:variable name="ontology-prefix" select="replace(@rdf:about,'(#|/)[0-9A-Za-z-_~]*$','$1')"/>
		<xsl:variable name="prefix">
			<xsl:choose>
				<xsl:when test="$ontology-prefix!=''"><xsl:value-of select="$ontology-prefix"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="/results/context/url"/>#</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="title">
			<xsl:choose>
				<xsl:when test="dcterms:title!=''"><xsl:value-of select="dcterms:title"/></xsl:when>
				<xsl:when test="dc:title!=''"><xsl:value-of select="dc:title"/></xsl:when>
				<xsl:when test="rdfs:label!=''"><xsl:value-of select="rdfs:label"/></xsl:when>
				<xsl:when test="/root/context/subject!=''"><xsl:value-of select="/root/context/subject"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="/root/context/url"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<ontology uri="{@rdf:about}" title="{$title}" prefix="{$prefix}">
			<description><xsl:value-of select="rdfs:comment|dc:description|dcterms:description"/></description>
			<xsl:for-each select="foaf:homepage/@rdf:resource"><homepage><xsl:value-of select="."/></homepage></xsl:for-each>
			<xsl:for-each select="rdfs:seeAlso/@rdf:resource"><see-also><xsl:value-of select="."/></see-also></xsl:for-each>
			<xsl:for-each select="dcterms:status/@rdf:resource"><status><xsl:value-of select="."/></status></xsl:for-each>
			<xsl:for-each select="dcterms:creator/@rdf:resource"><creator><xsl:value-of select="."/></creator></xsl:for-each>
			<xsl:for-each select="dcterms:contributor/@rdf:resource"><contributor><xsl:value-of select="."/></contributor></xsl:for-each>
			<xsl:for-each select="dcterms:publisher/@rdf:resource"><publisher><xsl:value-of select="."/></publisher></xsl:for-each>
		</ontology>
	</xsl:for-each-group>

	<nodeShapes>
		<xsl:copy-of select="$all-node-shapes"/>
		<!-- Create shapes for all classes that do not have a node shape, but are defined in this ontology -->
		<xsl:for-each select="$all-classes/class">
			<xsl:variable name="class" select="@uri"/>
			<xsl:if test="not(exists($all-node-shapes[@class-uri=$class]))">
				<shape uri="{$class}" class-uri="{$class}"/>
			</xsl:if>
		</xsl:for-each>
	</nodeShapes>
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
			<xsl:variable name="predicate" select="$all-property-shapes/propertyShape[@predicate=$about]"/>
			<property uri="{$about}" label="{$label}">
				<xsl:if test="not(exists(* except rdf:type))"><xsl:attribute name="ref">true</xsl:attribute></xsl:if>
				<xsl:choose>
					<xsl:when test="exists($all-node-shapes/shape/property[@uri=$about])">
						<xsl:for-each select="$all-node-shapes/shape/property[@uri=$about]">
							<scope-class uri="{../@class-uri}"/>
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

</xsl:stylesheet>