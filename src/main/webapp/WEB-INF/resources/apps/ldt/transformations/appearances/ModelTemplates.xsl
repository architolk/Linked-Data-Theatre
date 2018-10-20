<!--

    NAME     ModelTemplates.xsl
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
	Model templates contains some generic templates for processing a shacl graph, vocabulary or ontology

	This template is used by:
	- VocabularyAppearance
	- ModelAppearance
	- rdf2yed

	NB: This templates uses both versions of shacl (for backward compatibility):
		sh:path and sh:predicate (old)
		sh:targetClass and sh:scopeClass (old)

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:sh="http://www.w3.org/ns/shacl#"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:yed="http://bp4mc2.org/yed#"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:skos="http://www.w3.org/2004/02/skos/core#"
	xmlns:owl="http://www.w3.org/2002/07/owl#"
>

<xsl:template match="rdf:Description" mode="supershape-rec">
<!-- Input: class, Output: the supertype of the shape of the class, recursive -->
<!-- WARNING: No check is made regarding loops!!! -->
	<xsl:for-each select="rdfs:subClassOf">
		<xsl:variable name="super" select="@rdf:resource"/>
		<xsl:for-each select="../../rdf:Description[sh:targetClass/@rdf:resource=$super]">
			<inherited-shape uri="{@rdf:about}"/>
		</xsl:for-each>
		<xsl:apply-templates select="../../rdf:Description[@rdf:about=$super]" mode="supershape-rec"/>
	</xsl:for-each>
</xsl:template>

<xsl:template match="rdf:Description" mode="traverse-list">
	<xsl:choose>
		<xsl:when test="exists(rdf:first/@rdf:resource)"><item uri="{rdf:first/@rdf:resource}"/></xsl:when>
		<xsl:when test="rdf:first!=''"><item><xsl:value-of select="rdf:first"/></item></xsl:when>
		<xsl:otherwise />
	</xsl:choose>
	<xsl:variable name="rest" select="rdf:rest/@rdf:nodeID"/>
	<xsl:apply-templates select="../rdf:Description[@rdf:nodeID=$rest]" mode="traverse-list"/>
</xsl:template>

<xsl:template match="sh:property" mode="parse-property">
	<!-- Wat onhandig, maar voorkomt dubbelingen -->
	<xsl:param name="reified"/>
	<xsl:param name="class"/>
	<xsl:param name="real-class"/>
	<xsl:param name="shape"/>
	<xsl:param name="roles" as="node()"/>
	<xsl:param name="all-property-shapes" as="node()"/>
	<xsl:param name="all-metadata" as="node()"/>


	<xsl:variable name="property" select="@rdf:resource|@rdf:nodeID"/>
	<xsl:variable name="predicate" select="$all-property-shapes/propertyShape[@uri=$property]"/>
	<!-- If this property is part of a reified statement, we need to check the nodeshape... -->
	<xsl:if test="$predicate/@reified='yes'">
		<xsl:for-each select="../../rdf:Description[@rdf:nodeID=$predicate/ref-node/@uri]">
			<xsl:apply-templates select="sh:property" mode="parse-property">
				<xsl:with-param name="reified">yes</xsl:with-param>
				<xsl:with-param name="roles" select="$roles"/>
				<xsl:with-param name="all-property-shapes" select="$all-property-shapes"/>
				<xsl:with-param name="all-metadata" select="$all-metadata"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:if>
	<!-- If predicate doesn't exists, the shacl shape refers to an unknown predicate constraint! -->
	<!-- Also: remove rdf:type property, except when it is used for roles, but NOT when the role is a loop -->
	<!-- Extra (Is this correct??): Remove any property that has no name and is not used as a role -->
	<xsl:variable name="reification">
		<xsl:if test="$reified='yes'">
			<xsl:value-of select="substring-after($predicate/@predicate,'#')"/>
		</xsl:if>
	</xsl:variable>
	<xsl:if test="$reification='object' or $reification='subject' or ($predicate/@name!='' and (exists($roles/role) or not(exists($predicate/role[@uri=$real-class]))))">
		<xsl:variable name="refclass" select="$predicate/ref-class/@uri"/>
		<xsl:variable name="refnode" select="$predicate/ref-node/@uri"/>
		<xsl:variable name="roleclass" select="$predicate/role[@uri!=$real-class]/@uri"/>
		<property name="{$predicate/@name}" uri="{$predicate/@predicate}" shape-uri="{$predicate/@uri}">
			<xsl:if test="$refclass!=''">
				<xsl:attribute name="refclass"><xsl:value-of select="$refclass"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="$reification!=''">
				<xsl:attribute name="reification"><xsl:value-of select="$reification"/></xsl:attribute>
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
			<xsl:variable name="nodekind">
				<xsl:choose>
					<xsl:when test="$predicate/nodekind[1]/@uri='http://www.w3.org/ns/shacl#BlankNodeOrIRI'">BlankNodeOrIRI</xsl:when>
					<xsl:when test="$predicate/nodekind[1]/@uri='http://www.w3.org/ns/shacl#BlankNode'">BlankNode</xsl:when>
					<xsl:when test="$predicate/nodekind[1]/@uri='http://www.w3.org/ns/shacl#IRI'">IRI</xsl:when>
					<xsl:when test="$predicate/nodekind[1]/@uri='http://www.w3.org/ns/shacl#Literal'">Literal</xsl:when>
					<xsl:when test="$refclass!=''">BlankNodeOrIRI</xsl:when>
					<xsl:when test="$predicate/datatype[1]/@uri!=''">Literal</xsl:when>
					<xsl:otherwise />
				</xsl:choose>
			</xsl:variable>
			<xsl:if test="$nodekind!=''">
				<xsl:attribute name="nodekind"><xsl:value-of select="$nodekind"/></xsl:attribute>
			</xsl:if>
			<xsl:copy-of select="$predicate/value[1]"/>
			<xsl:copy-of select="$predicate/label"/>
			<!-- Refshapes are all shapes that have the particular refclass as target. @refnode contains a particular explicitly definied shape. Typically, this is one of the refshapes -->
			<!-- Refshapes can be duplicated, so we need to strip the duplicated items -->
			<xsl:variable name="refshapes">
				<xsl:for-each select="../../rdf:Description[sh:targetClass/@rdf:resource=$refclass]">
					<xsl:variable name="empty">
						<xsl:choose>
							<xsl:when test="exists(sh:property)">false</xsl:when>
							<xsl:when test="exists(../rdf:Description[@rdf:about=$refclass]/rdfs:subClassOf)">false</xsl:when>
							<xsl:when test="exists(../rdf:Description[rdfs:subClassOf/@rdf:resource=$refclass])">false</xsl:when>
							<xsl:otherwise>true</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<refshape uri="{@rdf:about}" empty="{$empty}">
						<xsl:if test="$empty='true'">
							<xsl:attribute name="shapename"><xsl:value-of select="sh:name"/></xsl:attribute>
						</xsl:if>
					</refshape>
				</xsl:for-each>
				<!-- hasValue references with type -->
				<xsl:for-each select="../../rdf:Description[sh:targetClass/@rdf:resource=$roleclass]">
					<xsl:variable name="empty">
						<xsl:choose>
							<xsl:when test="exists(sh:property)">false</xsl:when>
							<xsl:when test="exists(../rdf:Description[@rdf:about=$refclass]/rdfs:subClassOf)">false</xsl:when>
							<xsl:when test="exists(../rdf:Description[rdfs:subClassOf/@rdf:resource=$refclass])">false</xsl:when>
							<xsl:otherwise>true</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<refshape uri="{@rdf:about}" empty="{$empty}" type="role">
						<xsl:if test="$empty='true'">
							<xsl:attribute name="shapename"><xsl:value-of select="sh:name"/></xsl:attribute>
						</xsl:if>
					</refshape>
				</xsl:for-each>
				<!-- Explicit reference to a shape -->
				<xsl:for-each select="../../rdf:Description[@rdf:about=$refnode]">
					<xsl:variable name="empty">
						<xsl:choose>
							<xsl:when test="exists(sh:property)">
								<!-- If the shape is actually a list shape, don't count the shape -->
								<xsl:variable name="property" select="sh:property/(@rdf:nodeID|@rdf:resource)"/>
								<xsl:choose>
									<xsl:when test="$all-property-shapes/propertyShape[@uri=$property]/@list='true'">true</xsl:when>
									<xsl:otherwise>false</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="exists(../rdf:Description[@rdf:about=$refclass]/rdfs:subClassOf)">false</xsl:when>
							<xsl:when test="exists(../rdf:Description[rdfs:subClassOf/@rdf:resource=$refclass])">false</xsl:when>
							<xsl:otherwise>true</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<refshape uri="{@rdf:about}" empty="{$empty}">
						<xsl:if test="$empty='true'">
							<xsl:attribute name="shapename"><xsl:value-of select="sh:name"/></xsl:attribute>
						</xsl:if>
					</refshape>
				</xsl:for-each>
			</xsl:variable>
			<xsl:for-each-group select="$refshapes/refshape" group-by="@uri">
				<!-- Not sure if this is correct, but it seems that you should not elaborate on refshapes when an explicit reference is made! -->
				<xsl:if test="not($refnode!='') or @uri=$refnode">
					<refshape uri="{@uri}" empty="{@empty}">
						<xsl:if test="exists(@shapename)"><xsl:attribute name="shapename"><xsl:value-of select="@shapename"/></xsl:attribute></xsl:if>
						<xsl:if test="exists(@type)"><xsl:attribute name="type"><xsl:value-of select="@type"/></xsl:attribute></xsl:if>
						<!-- Geometry -->
						<xsl:variable name="refshape-uri" select="@uri"/>
						<xsl:copy-of select="$all-metadata/geometry[@subject=$shape and @predicate=$predicate/@predicate and @object=$refshape-uri]/*"/>
					</refshape>
				</xsl:if>
			</xsl:for-each-group>
			<!-- Logic refnodes -->
			<xsl:for-each select="$predicate/ref-nodes">
				<xsl:variable name="logicuri" select="@uri"/>
				<ref-nodes uri="{$logicuri}" logic="{@logic}">
					<xsl:for-each select="item">
						<xsl:variable name="itemuri" select="@uri"/>
						<item uri="{$itemuri}">
							<!-- Geometry of item path -->
							<xsl:copy-of select="$all-metadata/geometry[@subject=$logicuri and @object=$itemuri]/*"/>
						</item>
					</xsl:for-each>
					<xsl:copy-of select="geometry"/>
					<!-- Geometry of path -->
					<xsl:copy-of select="$all-metadata/geometry[@subject=$shape and @predicate=$predicate/@predicate and @object=$logicuri]/*"/>
				</ref-nodes>
			</xsl:for-each>
			<!-- Metadata -->
			<xsl:copy-of select="$all-metadata/statement[@subject=$class and @predicate=$predicate/@predicate and @object=$refclass]"/>
		</property>
	</xsl:if>
</xsl:template>

<xsl:template match="rdf:RDF" mode="VocabularyVariable">
	<!-- All reified statements -->
	<xsl:variable name="all-metadata">
		<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#Statement']" group-by="@rdf:about">
			<statement subject="{rdf:subject/@rdf:resource}" predicate="{rdf:predicate/@rdf:resource}" object="{rdf:object/@rdf:resource}">
				<xsl:copy-of select="current-group()/(* except (rdf:subject|rdf:predicate|rdf:object|rdf:type))"/>
			</statement>
		</xsl:for-each-group>
		<xsl:for-each-group select="rdf:Description[exists(yed:path)]" group-by="@rdf:about">
			<geometry subject="{rdf:subject/@rdf:resource}" predicate="{rdf:predicate/@rdf:resource}" object="{rdf:object/@rdf:resource}">
				<xsl:variable name="labelid" select="yed:label/@rdf:nodeID"/>
				<xsl:for-each select="../rdf:Description[@rdf:nodeID=$labelid]">
					<labelpos distance="{yed:distance}" ratio="{yed:ratio}" segment="{yed:segment}"/>
				</xsl:for-each>
				<xsl:variable name="pathid" select="yed:path/@rdf:nodeID"/>
				<xsl:for-each select="../rdf:Description[@rdf:nodeID=$pathid]">
					<path sx="{yed:sx}" sy="{yed:sy}" tx="{yed:tx}" ty="{yed:ty}">
						<xsl:for-each select="yed:wkt">
							<xsl:for-each select="tokenize(.,',')">
								<point x="{substring-before(.,' ')}" y="{substring-after(.,' ')}"/>
							</xsl:for-each>
						</xsl:for-each>
					</path>
				</xsl:for-each>
			</geometry>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- All (other) named entities -->
	<xsl:variable name="all-named-entities">
		<xsl:for-each select="rdf:Description[not(exists(rdf:type)) and exists(sh:name)]/sh:targetNode">
			<named-entity uri="{@rdf:resource}"><xsl:value-of select="../sh:name"/></named-entity>
		</xsl:for-each>
	</xsl:variable>
	<xsl:copy-of select="$all-named-entities"/>
	<!-- All property shapes -->
	<!-- Currently limited to simple paths and inverse paths, where the path is equal to the predicate -->
	<xsl:variable name="all-property-shapes">
		<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/ns/shacl#PropertyShape' or exists(sh:path/(@rdf:resource|@rdf:nodeID))]" group-by="(@rdf:about|@rdf:nodeID)">
			<xsl:variable name="predicate"><xsl:value-of select="sh:path/@rdf:resource"/></xsl:variable>
			<xsl:variable name="path-uri" select="sh:path/@rdf:nodeID"/>
			<xsl:variable name="inverse-predicate"><xsl:value-of select="../rdf:Description[@rdf:nodeID=$path-uri]/sh:inversePath/@rdf:resource"/></xsl:variable>
			<xsl:variable name="property-shape-uri" select="@rdf:about|@rdf:nodeID"/>
			<propertyShape name="{sh:name[1]}" uri="{$property-shape-uri}">
				<xsl:if test="$predicate!=''"><xsl:attribute name="predicate" select="$predicate"/></xsl:if>
				<xsl:if test="$inverse-predicate!=''"><xsl:attribute name="inversePredicate" select="$inverse-predicate"/></xsl:if>
				<xsl:if test="$inverse-predicate='http://www.w3.org/1999/02/22-rdf-syntax-ns#predicate'"><xsl:attribute name="reified">yes</xsl:attribute></xsl:if>
				<!-- rdfs:Literal should not be included as ref-class, because it's a Literal! -->
				<xsl:for-each select="current-group()/sh:class[not(@rdf:resource='http://www.w3.org/2000/01/rdf-schema#Literal')]">
					<ref-class uri="{@rdf:resource}"/>
				</xsl:for-each>
				<!-- Escape to add rdfs:range as ref-class. Only for specific nodekinds (to avoid adding datatypes like xsd:string as ref-class) -->
				<xsl:if test="current-group()/sh:nodeKind/@rdf:resource='http://www.w3.org/ns/shacl#BlankNodeOrIRI' and not(exists(current-group()/sh:class))">
					<xsl:variable name="propertyuri" select="sh:path/@rdf:resource"/>
					<xsl:for-each select="../rdf:Description[@rdf:about=$propertyuri]/rdfs:range[@rdf:resource!='']">
						<ref-class uri="{@rdf:resource}"/>
					</xsl:for-each>
				</xsl:if>
				<!-- Another escape to add rdfs:range -->
				<xsl:if test="not(exists(current-group()/sh:class)) and not(exists(current-group()/sh:datatype))">
					<xsl:variable name="propertyuri" select="sh:path/@rdf:resource"/>
					<xsl:for-each select="../rdf:Description[@rdf:about=$propertyuri]/rdfs:range[@rdf:nodeID!='']">
						<xsl:variable name="bnode" select="@rdf:nodeID"/>
						<xsl:variable name="range" select="../../rdf:Description[@rdf:nodeID=$bnode]"/>
						<ref-class uri="{$range/(owl:someValuesFrom|owl:onClass)/@rdf:resource}"/>
						<xsl:if test="$range/owl:minQualifiedCardinality!=''">
							<mincount><xsl:value-of select="$range/owl:minQualifiedCardinality"/></mincount>
						</xsl:if>
						<xsl:if test="$range/owl:maxQualifiedCardinality!=''">
							<maxcount><xsl:value-of select="$range/owl:maxQualifiedCardinality"/></maxcount>
						</xsl:if>
					</xsl:for-each>
				</xsl:if>
				<xsl:for-each select="current-group()/sh:nodeKind">
					<nodekind uri="{@rdf:resource}"/>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:datatype">
					<datatype uri="{@rdf:resource}"/>
				</xsl:for-each>
				<xsl:if test="not(exists(current-group()/sh:datatype))">
					<xsl:variable name="propertyuri" select="sh:path/@rdf:resource"/>
					<xsl:for-each select="../rdf:Description[@rdf:about=$propertyuri]/rdfs:range[substring(@rdf:resource,1,33)='http://www.w3.org/2001/XMLSchema#']">
						<datatype uri="{@rdf:resource}"/>
					</xsl:for-each>
				</xsl:if>
				<xsl:for-each select="current-group()/sh:hasValue">
					<xsl:variable name="uri" select="@rdf:resource"/>
					<xsl:variable name="entity"><xsl:value-of select="$all-named-entities/named-entity[@uri=$uri]"/></xsl:variable>
					<xsl:variable name="datatype">
						<xsl:choose>
							<xsl:when test="$entity!=''">entity</xsl:when>
							<xsl:when test="exists(@rdf:resource)">uri</xsl:when>
							<xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#integer'">nummeric</xsl:when>
							<xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#decimal'">nummeric</xsl:when>
							<xsl:otherwise>string</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<value datatype="{$datatype}">
						<xsl:if test="$datatype='uri'">
							<xsl:variable name="refuri" select="@rdf:resource"/>
							<xsl:variable name="label"><xsl:value-of select="../../rdf:Description[@rdf:about=$refuri]/sh:name[1]"/></xsl:variable>
							<xsl:if test="$label!=''"><xsl:attribute name="name" select="$label"/></xsl:if>
						</xsl:if>
						<xsl:choose>
							<xsl:when test="$entity!=''"><xsl:value-of select="$entity"/></xsl:when>
							<xsl:otherwise><xsl:value-of select="."/><xsl:value-of select="@rdf:resource"/></xsl:otherwise>
						</xsl:choose>
					</value>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:pattern">
					<pattern><xsl:value-of select="."/></pattern>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:maxLength">
					<maxLength><xsl:value-of select="."/></maxLength>
				</xsl:for-each>
				<xsl:if test="exists((sh:minInclusive|sh:maxInclusive))">
					<pattern minInclusive="{sh:minInclusive}" maxInclusive="{sh:maxInclusive}"><xsl:value-of select="sh:minInclusive"/>-<xsl:value-of select="sh:maxInclusive"/></pattern>
				</xsl:if>
				<xsl:for-each select="current-group()/sh:in">
					<xsl:variable name="listhead" select="@rdf:nodeID"/>
					<valuelist>
						<xsl:apply-templates select="../../rdf:Description[@rdf:nodeID=$listhead]" mode="traverse-list"/>
					</valuelist>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:node">
					<xsl:variable name="refnode" select="@rdf:nodeID|@rdf:resource"/>
					<xsl:choose>
						<!-- Logical expression with regard to nodes -->
						<xsl:when test="exists(../../rdf:Description[@rdf:nodeID=$refnode]/sh:xone)">
							<xsl:for-each select="../../rdf:Description[@rdf:nodeID=$refnode]/sh:xone">
								<xsl:variable name="logicuri" select="concat($predicate,'?shape=',encode-for-uri($property-shape-uri),'&amp;logic=',local-name())"/>
								<ref-nodes uri="{$logicuri}" logic="{local-name()}">
									<xsl:variable name="list" select="@rdf:nodeID"/>
									<xsl:apply-templates select="../../rdf:Description[@rdf:nodeID=$list]" mode="traverse-list"/>
									<!-- Geometry -->
									<xsl:for-each select="../../rdf:Description[@rdf:about=$logicuri]/yed:geometry">
										<xsl:variable name="nodeid" select="@rdf:nodeID"/>
										<xsl:for-each-group select="../../rdf:Description[@rdf:nodeID=$nodeid]" group-by="@rdf:nodeID">
											<geometry height="{yed:height}" width="{yed:width}" x="{yed:x}" y="{yed:y}"/>
										</xsl:for-each-group>
									</xsl:for-each>
								</ref-nodes>
							</xsl:for-each>
						</xsl:when>
						<xsl:otherwise>
							<ref-node uri="{$refnode}"/> <!-- Ref-node is an alternative to sh:class, more specific to a specific shape. But also blank ref-nodes are possible! -->
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:minCount">
					<mincount><xsl:value-of select="."/></mincount>
				</xsl:for-each>
				<xsl:for-each select="current-group()/sh:maxCount">
					<maxcount><xsl:value-of select="."/></maxcount>
				</xsl:for-each>
				<!-- Specific constraint: shape implies another shape -->
				<xsl:if test="exists(current-group()/sh:path[@rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#type'])">
					<xsl:for-each select="current-group()/sh:hasValue">
						<role uri="{@rdf:resource}"/>
					</xsl:for-each>
				</xsl:if>
				<!-- Encoding of enumerations (sh:path skos:inScheme OR sh:path [sh:inversePath skos:member]), and sh:hasValue, the value identifies the enumeration) -->
				<xsl:for-each select="current-group()/sh:path[@rdf:resource='http://www.w3.org/2004/02/skos/core#inScheme' or @rdf:nodeID!='']">
					<xsl:variable name="path-uri" select="@rdf:nodeID"/>
					<xsl:variable name="path" select="../../rdf:Description[@rdf:nodeID=$path-uri]"/>
					<xsl:if test="@rdf:resource='http://www.w3.org/2004/02/skos/core#inScheme' or $path/sh:inversePath/@rdf:resource='http://www.w3.org/2004/02/skos/core#member'">
						<xsl:for-each select="current-group()/sh:hasValue">
							<enumeration uri="{@rdf:resource}"/>
						</xsl:for-each>
						<!-- Enumerations are also possible as instances of sh:in -->
						<xsl:for-each select="current-group()/sh:in">
							<xsl:variable name="listhead" select="@rdf:nodeID"/>
							<enumeration>
								<xsl:apply-templates select="../../rdf:Description[@rdf:nodeID=$listhead]" mode="traverse-list"/>
							</enumeration>
						</xsl:for-each>
					</xsl:if>
				</xsl:for-each>
				<xsl:for-each select="current-group()/rdfs:label">
					<label>
						<xsl:if test="@xml:lang!=''"><xsl:attribute name="xml:lang"><xsl:value-of select="@xml:lang"/></xsl:attribute></xsl:if>
						<xsl:value-of select="."/>
					</label>
				</xsl:for-each>
			</propertyShape>
		</xsl:for-each-group>
		<!-- Special property constraints - lists -->
		<xsl:for-each-group select="rdf:Description[exists(sh:path/@rdf:nodeID)]" group-by="@rdf:about|@rdf:nodeID">
			<xsl:variable name="path" select="sh:path/@rdf:nodeID"/>
			<!-- Check if the path equals something like: sh:path ([sh:zeroOrMorePath rdf:rest] rdf:first) -->
			<xsl:variable name="listCheck">
				<xsl:for-each select="../rdf:Description[@rdf:nodeID=$path]">
					<xsl:variable name="first" select="rdf:first/@rdf:nodeID"/>
					<xsl:for-each select="../rdf:Description[@rdf:nodeID=$first]">
						<xsl:if test="sh:zeroOrMorePath/@rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#rest'">LIST</xsl:if>
					</xsl:for-each>
				</xsl:for-each>
			</xsl:variable>
			<xsl:if test="$listCheck='LIST'">
				<propertyShape name="{sh:name[1]}" uri="{@rdf:about|@rdf:nodeID}" list="true">
					<xsl:for-each select="current-group()/sh:class">
						<ref-class uri="{@rdf:resource}"/>
					</xsl:for-each>
				</propertyShape>
			</xsl:if>
		</xsl:for-each-group>
	</xsl:variable>
	<!--<xsl:copy-of select="$all-property-shapes"/>-->
	<!-- All node shapes -->
	<xsl:variable name="all-node-shapes">
		<xsl:for-each-group select="rdf:Description[exists(sh:targetClass|sh:property|rdf:type[@rdf:resource='http://www.w3.org/ns/shacl#NodeShape'])]" group-by="@rdf:about">
			<xsl:variable name="real-class"><xsl:value-of select="current-group()/sh:targetClass[1]/@rdf:resource"/></xsl:variable>
			<xsl:variable name="real-property"><xsl:value-of select="current-group()/sh:targetNode[1]/@rdf:resource"/></xsl:variable>
			<!-- Find all roles -->
			<xsl:variable name="roles">
				<xsl:for-each select="current-group()/sh:property">
					<xsl:variable name="property" select="@rdf:resource|@rdf:nodeID"/>
					<xsl:variable name="predicate" select="$all-property-shapes/propertyShape[@uri=$property]"/>
					<xsl:for-each select="$predicate/role[@uri!=$real-class]">
						<role uri="{@uri}"/>
					</xsl:for-each>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="class">
				<xsl:value-of select="$real-class"/>
				<!-- Insert role class if a role class exists, only when a targetClass has not been defined -->
				<xsl:if test="$real-class=''">
					<xsl:value-of select="$roles/role[1]/@uri"/>
				</xsl:if>
			</xsl:variable>
			<xsl:variable name="shape" select="@rdf:about"/>
			<shape name="{sh:name[1]}" uri="{$shape}">
				<xsl:if test="$class!=''">
					<xsl:attribute name="class-uri"><xsl:value-of select="$class"/></xsl:attribute>
				</xsl:if>
				<xsl:if test="$real-property!=''">
					<xsl:attribute name="property-uri"><xsl:value-of select="$real-property"/></xsl:attribute>
				</xsl:if>
				<xsl:if test="$roles/role[1]/@uri!=''">
					<xsl:attribute name="role">yes</xsl:attribute>
				</xsl:if>
				<xsl:attribute name="empty">
					<xsl:choose>
						<xsl:when test="exists(../rdf:Description[@rdf:about=$class]/rdfs:subClassOf)">false</xsl:when>
						<xsl:when test="exists(../rdf:Description[rdfs:subClassOf/@rdf:resource=$class])">false</xsl:when>
						<xsl:when test="exists(sh:property)">
							<xsl:variable name="property" select="sh:property/(@rdf:nodeID|@rdf:resource)"/>
							<xsl:choose>
								<!-- If the shape is actually a list shape, don't count the shape -->
								<xsl:when test="$all-property-shapes/propertyShape[@uri=$property]/@list='true'">true</xsl:when>
								<!-- If the shape contains only 1 inverse property, don't count the shape -->
								<xsl:when test="count(sh:property)=1 and not(exists($all-property-shapes/propertyShape[@uri=$property]))">true</xsl:when>
								<xsl:otherwise>false</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>true</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<!-- Check if the shape is actually a enumeration -->
				<xsl:variable name="predicate">
					<xsl:for-each select="current-group()/sh:property">
						<xsl:variable name="property1" select="(@rdf:resource|@rdf:nodeID)"/>
						<xsl:variable name="predicate1" select="$all-property-shapes/propertyShape[@uri=$property1]"/>
						<xsl:if test="exists($predicate1/enumeration)">
							<xsl:copy-of select="$predicate1/*"/>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$predicate/enumeration/@uri!=''">
						<xsl:variable name="enumeration" select="$predicate/enumeration/@uri"/>
						<xsl:attribute name="enumeration"><xsl:value-of select="$enumeration"/></xsl:attribute>
						<xsl:for-each select="../rdf:Description[skos:inScheme/@rdf:resource=$enumeration]"><xsl:sort select="rdfs:label"/>
							<enumvalue name="{rdfs:label}" uri="{@rdf:about}"/>
						</xsl:for-each>
						<xsl:for-each select="../rdf:Description[@rdf:about=$enumeration]/skos:member">
							<xsl:variable name="member" select="@rdf:resource"/>
							<xsl:for-each select="../../rdf:Description[@rdf:about=$member]"><xsl:sort select="rdfs:label"/>
								<enumvalue name="{rdfs:label}" uri="{@rdf:about}"/>
							</xsl:for-each>
						</xsl:for-each>
						<!-- Enumeration might have properties, but only roles for now! -->
						<xsl:for-each select="current-group()/sh:property">
							<xsl:variable name="property" select="@rdf:resource|@rdf:nodeID"/>
							<xsl:variable name="predicate" select="$all-property-shapes/propertyShape[@uri=$property]"/>
							<xsl:if test="exists($predicate/role)">
								<xsl:apply-templates select="current-group()/sh:property" mode="parse-property">
									<xsl:with-param name="class" select="$class"/>
									<xsl:with-param name="real-class" select="$real-class"/>
									<xsl:with-param name="shape" select="$shape"/>
									<xsl:with-param name="roles" select="$roles"/>
									<xsl:with-param name="all-property-shapes" select="$all-property-shapes"/>
									<xsl:with-param name="all-metadata" select="$all-metadata"/>
								</xsl:apply-templates>
							</xsl:if>
						</xsl:for-each>
					</xsl:when>
					<xsl:when test="$predicate/enumeration/item[1]/@uri!=''">
						<xsl:for-each select="$predicate/enumeration/item">
							<enumeration uri="{@uri}"/>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="current-group()/sh:property" mode="parse-property">
							<xsl:with-param name="class" select="$class"/>
							<xsl:with-param name="real-class" select="$real-class"/>
							<xsl:with-param name="shape" select="$shape"/>
							<xsl:with-param name="roles" select="$roles"/>
							<xsl:with-param name="all-property-shapes" select="$all-property-shapes"/>
							<xsl:with-param name="all-metadata" select="$all-metadata"/>
						</xsl:apply-templates>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:for-each select="current-group()/rdfs:label">
					<label>
						<xsl:if test="@xml:lang!=''"><xsl:attribute name="xml:lang"><xsl:value-of select="@xml:lang"/></xsl:attribute></xsl:if>
						<xsl:value-of select="."/>
					</label>
				</xsl:for-each>
				<xsl:copy-of select="$roles/role"/>
				<xsl:for-each select="current-group()/yed:geometry">
					<xsl:variable name="nodeid" select="@rdf:nodeID"/>
					<xsl:for-each-group select="../../rdf:Description[@rdf:nodeID=$nodeid]" group-by="@rdf:nodeID">
						<geometry height="{yed:height}" width="{yed:width}" x="{yed:x}" y="{yed:y}"/>
					</xsl:for-each-group>
				</xsl:for-each>
			</shape>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- All classes -->
	<xsl:variable name="all-classes">
		<CLASSES-1/>
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
				<xsl:for-each select="current-group()/(rdfs:comment|skos:definition)">
					<comment><xsl:value-of select="."/></comment>
				</xsl:for-each>
				<xsl:for-each select="current-group()/dcterms:subject">
					<xsl:variable name="concept" select="@rdf:resource"/>
					<xsl:for-each select="../../rdf:Description[@rdf:about=$concept]/skos:definition">
						<comment concept="{$concept}"><xsl:value-of select="."/></comment>
					</xsl:for-each>
				</xsl:for-each>
				<xsl:for-each select="current-group()/rdfs:seeAlso">
					<seeAlso uri="{@rdf:resource}">
						<xsl:variable name="ref" select="@rdf:resource"/>
						<xsl:if test="not(exists(../../rdf:Description[@rdf:about=$ref]/(* except rdf:type)))"><xsl:attribute name="label" select="$ref"/></xsl:if>
					</seeAlso>
				</xsl:for-each>
				<xsl:for-each select="$all-node-shapes/shape[@class-uri=$about and not(@role='yes')]">
					<shape uri="{@uri}"/>
				</xsl:for-each>
				<xsl:for-each select="$all-node-shapes/shape[role/@uri=$about]">
					<role-shape uri="{@uri}"/>
				</xsl:for-each>
				<xsl:for-each-group select="$all-property-shapes/propertyShape[ref-class/@uri=$about]" group-by="@uri">
					<refproperty uri="{@uri}" predicate="{@predicate}"/>
				</xsl:for-each-group>
				<xsl:apply-templates select="." mode="supershape-rec"/>
			</class>
		</xsl:for-each-group>
		<CLASSES-2/>
		<!-- All classes that are targetClasses of shapes, but not themeselves states in this repo -->
		<xsl:for-each-group select="rdf:Description/sh:targetClass" group-by="@rdf:resource">
			<xsl:variable name="classuri" select="@rdf:resource"/>
			<xsl:if test="not(exists(../../rdf:Description[@rdf:about=$classuri]))">
				<xsl:variable name="name"><xsl:value-of select="replace($classuri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:variable>
				<xsl:variable name="label">
					<xsl:value-of select="../sh:name"/>
					<xsl:if test="not(../sh:name!='')"><xsl:value-of select="$name"/></xsl:if>
				</xsl:variable>
				<class uri="{@rdf:resource}" label="{$label}">
					<xsl:for-each select="../../rdf:Description[rdfs:subClassOf/@rdf:resource=$classuri]">
						<sub uri="{@rdf:about}"/>
					</xsl:for-each>
					<xsl:for-each select="$all-node-shapes/shape[@class-uri=$classuri and not(@role='yes')]">
						<shape uri="{@uri}"/>
					</xsl:for-each>
					<xsl:for-each select="$all-node-shapes/shape[role/@uri=$classuri]">
						<role-shape uri="{@uri}"/>
					</xsl:for-each>
				</class>
			</xsl:if>
		</xsl:for-each-group>
		<CLASSES-3/>
		<!-- All superclasses that are not defined in the ontology, and not a targetclass of a shape -->
		<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Class' or rdf:type/@rdf:resource='http://www.w3.org/2000/01/rdf-schema#Class']/rdfs:subClassOf" group-by="@rdf:resource">
			<xsl:variable name="classuri" select="@rdf:resource"/>
			<xsl:if test="not(exists(../../rdf:Description[@rdf:about=$classuri])) and not(exists($all-node-shapes/shape[@class-uri=$classuri and not(@role='yes')]))">
				<class uri="{@rdf:resource}" ref="true">
					<xsl:for-each select="current-group()">
						<sub uri="{../@rdf:about}"/>
					</xsl:for-each>
				</class>
			</xsl:if>
		</xsl:for-each-group>
	</xsl:variable>

	<xsl:for-each-group select="rdf:Description[rdf:type/@rdf:resource='http://www.w3.org/2002/07/owl#Ontology']" group-by="@rdf:about">
		<xsl:variable name="ontology-prefix" select="replace(@rdf:about,'(/[0-9A-Za-z-_~]*)(#|/)$','$1')"/>
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
			<xsl:if test="not(exists($all-node-shapes/shape[@class-uri=$class]))">
				<shape uri="{$class}" class-uri="{$class}" empty='true'/>
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
						<xsl:for-each select="$all-node-shapes/shape[@class-uri!='']/property[@uri=$about]">
							<scope-class uri="{../@class-uri}"/>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<xsl:for-each select="current-group()/rdfs:domain">
							<xsl:choose>
								<xsl:when test="@rdf:resource!=''"><scope-class uri="{@rdf:resource}"/></xsl:when>
								<xsl:when test="@rdf:nodeID!=''">
									<xsl:variable name="bnode" select="@rdf:nodeID"/>
									<scope-class uri="{../../rdf:Description[@rdf:nodeID=$bnode]/(owl:someValuesFrom|owl:onClass)/@rdf:resource}"/>
								</xsl:when>
								<xsl:otherwise/>
							</xsl:choose>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:for-each-group select="$predicate/ref-class" group-by="@uri">
					<ref-class uri="{@uri}"/>
				</xsl:for-each-group>
				<!-- Added, don't know if this is really OK ? -->
				<xsl:if test="not(exists($predicate/ref-class)) and not(exists($predicate/datatype))">
					<xsl:for-each select="current-group()/rdfs:range">
						<xsl:choose>
							<xsl:when test="@rdf:nodeID!=''">
								<xsl:variable name="bnode" select="@rdf:nodeID"/>
								<ref-class uri="{../../rdf:Description[@rdf:nodeID=$bnode]/(owl:someValuesFrom|owl:onClass)/@rdf:resource}"/>
							</xsl:when>
							<xsl:when test="substring(@rdf:resource,1,33)='http://www.w3.org/2001/XMLSchema#'">
								<datatype uri="{@rdf:resource}"/>
							</xsl:when>
							<xsl:otherwise/>
						</xsl:choose>
					</xsl:for-each>
				</xsl:if>
				<!-- END Adding -->
				<xsl:for-each-group select="$predicate/datatype" group-by="@uri">
					<datatype uri="{@uri}"/>
				</xsl:for-each-group>
				<xsl:for-each-group select="$predicate/pattern" group-by=".">
					<pattern minInclusive="{@minInclusive}" maxInclusive="{@maxInclusive}"><xsl:value-of select="."/></pattern>
				</xsl:for-each-group>
				<xsl:for-each-group select="$predicate/maxLength" group-by=".">
					<maxLength><xsl:value-of select="."/></maxLength>
				</xsl:for-each-group>
				<!-- A particular predicate could have a node that is actually a domain -->
				<xsl:for-each-group select="$predicate/ref-node" group-by="@uri">
					<xsl:variable name="ref" select="@uri"/>
					<xsl:for-each select="$all-node-shapes/shape[@uri=$ref and @enumeration!='']">
						<domain uri="{@enumeration}"/>
					</xsl:for-each>
				</xsl:for-each-group>
				<xsl:copy-of select="$predicate/valuelist"/>
				<xsl:for-each select="current-group()/rdfs:subPropertyOf">
					<super uri="{@rdf:resource}">
						<xsl:variable name="ref" select="@rdf:resource"/>
						<xsl:if test="not(exists(../../rdf:Description[@rdf:about=$ref]/(* except rdf:type)))"><xsl:attribute name="label" select="$ref"/></xsl:if>
					</super>
				</xsl:for-each>
				<xsl:for-each select="../rdf:Description[rdfs:subPropertyOf/@rdf:resource=$about]">
					<sub uri="{@rdf:about}"/>
				</xsl:for-each>
				<xsl:for-each select="current-group()/(rdfs:comment|skos:definition)">
					<comment><xsl:value-of select="."/></comment>
				</xsl:for-each>
				<xsl:for-each select="current-group()/dcterms:subject">
					<xsl:variable name="concept" select="@rdf:resource"/>
					<xsl:for-each select="../../rdf:Description[@rdf:about=$concept]/skos:definition">
						<comment concept="{$concept}"><xsl:value-of select="."/></comment>
					</xsl:for-each>
				</xsl:for-each>
			</property>
		</xsl:for-each-group>
		<!-- All properties that are paths of shapes, but not themeselves states in this repo -->
		<xsl:for-each-group select="rdf:Description/sh:path" group-by="@rdf:resource">
			<xsl:variable name="propertyuri" select="@rdf:resource"/>
			<xsl:if test="not(exists(../../rdf:Description[@rdf:about=$propertyuri]))">
				<xsl:variable name="name"><xsl:value-of select="replace($propertyuri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:variable>
				<xsl:variable name="label">
					<xsl:value-of select="../sh:name"/>
					<xsl:if test="not(../sh:name!='')"><xsl:value-of select="$name"/></xsl:if>
				</xsl:variable>
				<xsl:variable name="predicate" select="$all-property-shapes/propertyShape[@predicate=$propertyuri]"/>
				<xsl:if test="exists($predicate)">
					<property uri="{$propertyuri}" label="{$label}">
						<xsl:for-each select="$all-node-shapes/shape[@class-uri!='']/property[@uri=$propertyuri]">
							<scope-class uri="{../@class-uri}"/>
						</xsl:for-each>
						<xsl:for-each-group select="$predicate/ref-class" group-by="@uri">
							<ref-class uri="{@uri}"/>
						</xsl:for-each-group>
						<xsl:for-each-group select="$predicate/datatype" group-by="@uri">
							<datatype uri="{@uri}"/>
						</xsl:for-each-group>
						<xsl:for-each-group select="$predicate/pattern" group-by=".">
							<pattern minInclusive="{@minInclusive}" maxInclusive="{@maxInclusive}"><xsl:value-of select="."/></pattern>
						</xsl:for-each-group>
						<xsl:for-each-group select="$predicate/maxLength" group-by=".">
							<maxLength><xsl:value-of select="."/></maxLength>
						</xsl:for-each-group>
						<!-- A particular predicate could have a node that is actually a domain -->
						<xsl:for-each-group select="$predicate/ref-node" group-by="@uri">
							<xsl:variable name="ref" select="@uri"/>
							<xsl:for-each select="$all-node-shapes/shape[@uri=$ref and @enumeration!='']">
								<domain uri="{@enumeration}"/>
							</xsl:for-each>
						</xsl:for-each-group>
						<xsl:for-each select="$predicate/valuelist">
							<xsl:variable name="predicate" select="../@uri"/>
							<xsl:variable name="shape" select="$all-node-shapes/shape[property/@shape-uri=$predicate]/@uri"/>
							<xsl:if test="$shape!=''">
								<valuelist shape="{$shape}"><xsl:copy-of select="*"/></valuelist>
							</xsl:if>
						</xsl:for-each>
					</property>
				</xsl:if>
			</xsl:if>
		</xsl:for-each-group>
	</properties>
</xsl:template>

<!-- Used in visualisation of rdf2yed and ModelAppearance -->
<xsl:template match="property" mode="property-placement">
	<xsl:variable name="slabel"><xsl:value-of select="replace(@uri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:variable>
	<xsl:variable name="label">
		<xsl:value-of select="@name"/>
		<xsl:if test="not(@name!='')">
			<xsl:value-of select="$slabel"/>
			<xsl:if test="$slabel=''"><xsl:value-of select="@uri"/></xsl:if>
		</xsl:if>
	</xsl:variable>
	<xsl:value-of select="$label"/>
	<xsl:if test="exists(value)">
		<xsl:text> = </xsl:text>
		<xsl:choose>
			<xsl:when test="value/@datatype='string'">"<xsl:value-of select="value"/>"</xsl:when>
			<xsl:when test="value/@datatype='uri' and value/@name!=''"><xsl:value-of select="value/@name"/></xsl:when>
			<xsl:when test="value/@datatype='uri'">&lt;<xsl:value-of select="value"/>&gt;</xsl:when>
			<xsl:otherwise>[<xsl:value-of select="value"/>]</xsl:otherwise>
		</xsl:choose>
	</xsl:if>
	<xsl:if test="@datatype!=''"><xsl:text> (</xsl:text><xsl:value-of select="replace(@datatype,'^.*(#|/)([^(#|/)]+)$','$2')"/><xsl:text>)</xsl:text></xsl:if>
	<xsl:if test="refshape/@shapename!=''"> &#x2192; <xsl:value-of select="refshape/@shapename"/></xsl:if>
	<xsl:text> [</xsl:text><xsl:value-of select="@mincount"/><xsl:text>,</xsl:text><xsl:value-of select="@maxcount"/><xsl:text>]</xsl:text>
</xsl:template>

</xsl:stylesheet>
