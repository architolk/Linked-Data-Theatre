<!--

    NAME     SimpleTranslator.xsl
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
	Translates XML to a simple RDF format. Most usable for debugging purposes

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:ldm="http://powerdesigner.com/def#"

	xmlns:o="object"
	xmlns:a="attribute"
	xmlns:c="collection"
>

	<xsl:key name="item" match="//*" use="@Id"/>

	<xsl:variable name="prefix">urn:powerdesigner:</xsl:variable>

	<!-- Property parsing -->
	<xsl:template match="a:ObjectID" mode="properties">
		<ldm:objectID><xsl:value-of select="."/></ldm:objectID>
	</xsl:template>

	<xsl:template match="a:Name" mode="properties">
		<rdfs:label><xsl:value-of select="."/></rdfs:label>
		<ldm:name><xsl:value-of select="."/></ldm:name>
	</xsl:template>

	<xsl:template match="a:Code" mode="properties">
		<ldm:code><xsl:value-of select="."/></ldm:code>
	</xsl:template>

	<xsl:template match="a:Creator" mode="properties">
		<ldm:creator><xsl:value-of select="."/></ldm:creator>
	</xsl:template>

	<xsl:template match="a:Modifier" mode="properties">
		<ldm:modifier><xsl:value-of select="."/></ldm:modifier>
	</xsl:template>

	<xsl:template match="a:CreationDate" mode="properties">
		<ldm:creationDate><xsl:value-of select="."/></ldm:creationDate>
	</xsl:template>

	<xsl:template match="a:ModificationDate" mode="properties">
		<ldm:modificationDate><xsl:value-of select="."/></ldm:modificationDate>
	</xsl:template>

	<xsl:template match="a:LogicalAttribute.Mandatory" mode="properties">
		<ldm:mandatory><xsl:value-of select="."/></ldm:mandatory>
	</xsl:template>

	<xsl:template match="a:DataType" mode="properties">
		<ldm:dataType><xsl:value-of select="."/></ldm:dataType>
	</xsl:template>

	<xsl:template match="a:Length" mode="properties">
		<ldm:length><xsl:value-of select="."/></ldm:length>
	</xsl:template>

	<xsl:template match="a:Entity1ToEntity2RoleCardinality" mode="properties">
		<ldm:entity1toEntity2roleCardinality><xsl:value-of select="."/></ldm:entity1toEntity2roleCardinality>
	</xsl:template>

	<xsl:template match="a:Entity2ToEntity1RoleCardinality" mode="properties">
		<ldm:entity2toEntity1roleCardinality><xsl:value-of select="."/></ldm:entity2toEntity1roleCardinality>
	</xsl:template>

	<xsl:template match="a:DependentRole" mode="properties">
		<ldm:dependentRole><xsl:value-of select="."/></ldm:dependentRole>
	</xsl:template>

	<xsl:template match="a:MutuallyExclusive" mode="properties">
		<ldm:mutuallyExclusive><xsl:value-of select="."/></ldm:mutuallyExclusive>
	</xsl:template>

	<xsl:template match="a:InheritAll" mode="properties">
		<ldm:inheritAll><xsl:value-of select="."/></ldm:inheritAll>
	</xsl:template>

	<!-- Relatie properties (inline links) -->
	<xsl:template match="o:EntityAttribute" mode="properties">
		<ldm:attribute rdf:resource="{$prefix}{a:ObjectID}"/>
	</xsl:template>

	<xsl:template match="o:Identifier" mode="properties">
		<ldm:identifier rdf:resource="{$prefix}{a:ObjectID}"/>
	</xsl:template>

	<xsl:template match="o:RelationshipJoin" mode="properties">
		<ldm:relationshipJoin rdf:resource="{$prefix}{a:ObjectID}"/>
	</xsl:template>

	<!-- Relatie properties (references) -->
	<xsl:template match="c:Identifier.Attributes" mode="properties">
		<xsl:for-each select="o:EntityAttribute">
			<ldm:attribute rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="c:PrimaryIdentifier" mode="properties">
		<xsl:for-each select="o:Identifier">
			<ldm:primaryIdentifier rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="c:Object1" mode="properties">
		<xsl:for-each select="o:Entity">
			<ldm:object1entity rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
		<xsl:for-each select="o:EntityAttribute">
			<ldm:object1attribute rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
		<xsl:for-each select="o:Inheritance">
			<ldm:object1inheritance rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="c:Object2" mode="properties">
		<xsl:for-each select="o:Entity">
			<ldm:object2entity rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
		<xsl:for-each select="o:EntityAttribute">
			<ldm:object2attribute rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
		<xsl:for-each select="o:Inheritance">
			<ldm:object2inheritance rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="c:ParentIdentifier" mode="properties">
		<xsl:for-each select="o:Identifier">
			<ldm:parentIdentifier rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="c:InheritedFrom" mode="properties">
		<xsl:for-each select="o:EntityAttribute">
			<ldm:inheritedFrom rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="c:ParentEntity" mode="properties">
		<xsl:for-each select="o:Entity">
			<ldm:parentEntity rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
	</xsl:template>

	<!-- Catch all properties -->
	<xsl:template match="*" mode="properties">
		<rdfs:label>TODO: <xsl:value-of select="../local-name()"/>/<xsl:value-of select="local-name()"/></rdfs:label>
	</xsl:template>

	<!-- Resource parsing -->
	<xsl:template match="o:Model" mode="parse">
		<ldm:Model rdf:about="{$prefix}{a:ObjectID}">
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate" mode="properties"/>
		</ldm:Model>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:LogicalDiagrams|c:DefaultDiagram|a:PackageOptionsText|a:ModelOptionsText" mode="parse">
		<!-- Don't process diagrams or technical options: that's visualisation! -->
	</xsl:template>

	<xsl:template match="c:Entities" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:Entity" mode="parse">
		<ldm:Entity rdf:about="{$prefix}{a:ObjectID}">
			<!-- Literal properties -->
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate" mode="properties"/>
			<!-- Relations properties -->
			<xsl:apply-templates select="c:Attributes/o:EntityAttribute" mode="properties"/>
			<xsl:apply-templates select="c:Identifiers/o:Identifier" mode="properties"/>
			<xsl:apply-templates select="c:PrimaryIdentifier" mode="properties"/>
		</ldm:Entity>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:Attributes" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:EntityAttribute" mode="parse">
		<ldm:Attribute rdf:about="{$prefix}{a:ObjectID}">
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:LogicalAttribute.Mandatory|a:DataType|a:Length" mode="properties"/>
			<!-- Relations properties -->
			<xsl:apply-templates select="c:InheritedFrom" mode="properties"/>
		</ldm:Attribute>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:Identifiers" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:Identifier" mode="parse">
		<ldm:Identifier rdf:about="{$prefix}{a:ObjectID}">
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate" mode="properties"/>
			<!-- Relations properties -->
			<xsl:apply-templates select="c:Identifier.Attributes" mode="properties"/>
		</ldm:Identifier>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:Relationships" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:Relationship" mode="parse">
		<ldm:Relationship rdf:about="{$prefix}{a:ObjectID}">
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Entity1ToEntity2RoleCardinality|a:Entity2ToEntity1RoleCardinality|a:DependentRole" mode="properties"/>
			<!-- Relations properties -->
			<xsl:apply-templates select="c:Joins/o:RelationshipJoin" mode="properties"/>
			<xsl:apply-templates select="c:Object1|c:Object2|c:ParentIdentifier" mode="properties"/>
		</ldm:Relationship>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:Joins" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:RelationshipJoin" mode="parse">
		<ldm:RelationshipJoin rdf:about="{$prefix}{a:ObjectID}">
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate" mode="properties"/>
			<!-- Relations properties -->
			<xsl:apply-templates select="c:Object1|c:Object2" mode="properties"/>
		</ldm:RelationshipJoin>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:Inheritances" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:Inheritance" mode="parse">
		<ldm:Inheritance rdf:about="{$prefix}{a:ObjectID}">
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:MutuallyExclusive|a:InheritAll" mode="properties"/>
			<!-- Relations properties -->
			<xsl:apply-templates select="c:ParentEntity" mode="properties"/>
		</ldm:Inheritance>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:InheritanceLinks" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:InheritanceLink" mode="parse">
		<ldm:InheritanceLink rdf:about="{$prefix}{a:ObjectID}">
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate" mode="properties"/>
			<!-- Relations properties -->
			<xsl:apply-templates select="c:Object1|c:Object2" mode="properties"/>
		</ldm:InheritanceLink>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:RootObject" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:Children" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<!-- Properties, don't parse them as resources -->
	<xsl:template match="a:ObjectID|a:Name|a:Code|a:Creator|a:Modifier|a:CreationDate|a:ModificationDate|a:LogicalAttribute.Mandatory|a:DataType|a:Length|a:Entity1ToEntity2RoleCardinality|a:Entity2ToEntity1RoleCardinality|a:DependentRole|a:MutuallyExclusive|a:InheritAll" mode="parse">
		<!-- Nothing to do -->
	</xsl:template>

	<!-- Relation properties, don't parse them as resources -->
	<xsl:template match="c:PrimaryIdentifier|c:Identifier.Attributes|c:Object1|c:Object2|c:ParentIdentifier|c:InheritedFrom|c:ParentEntity" mode="parse">
		<!-- Nothing to do -->
	</xsl:template>

	<!-- Failsafe: catch all non-dealt with elements -->
	<xsl:template match="*" mode="parse">
		<rdf:Description rdf:about="urn:entity:{@Id}">
			<rdfs:label>TODO: <xsl:value-of select="../local-name()"/>/<xsl:value-of select="local-name()"/></rdfs:label>
		</rdf:Description>
	</xsl:template>

	<!-- Helper -->
	<xsl:template match="*" mode="check">
		<rdf:Description rdf:about="urn:test:{@Id}">
			<xsl:for-each select="*">
				<rdfs:label><xsl:value-of select="local-name()"/></rdfs:label>
			</xsl:for-each>
		</rdf:Description>
	</xsl:template>

	<xsl:template match="/">
		<rdf:RDF>
			<xsl:apply-templates select="root/Model/*" mode="parse"/>
		</rdf:RDF>
	</xsl:template>
</xsl:stylesheet>
