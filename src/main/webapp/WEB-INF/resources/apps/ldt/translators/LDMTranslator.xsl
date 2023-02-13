<!--

    NAME     SimpleTranslator.xsl
    VERSION  1.25.3-SNAPSHOT
    DATE     2020-11-25

    Copyright 2012-2020

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
  xmlns:xs="http://www.w3.org/2001/XMLSchema"

	xmlns:o="object"
	xmlns:a="attribute"
	xmlns:c="collection"
>

	<xsl:key name="item" match="//*" use="@Id"/>

	<xsl:variable name="prefix">urn:uuid:</xsl:variable>

	<!-- Property parsing -->
	<xsl:template match="a:SessionID" mode="properties">
		<ldm:sessionID><xsl:value-of select="."/></ldm:sessionID>
	</xsl:template>

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
		<ldm:creationDate rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
      <!-- Powerdesigner uses Epoch time format, change RDF time format -->
      <xsl:value-of select="xs:dateTime('1970-01-01T00:00:00') + xs:dayTimeDuration(concat('PT', ., 'S'))"/>
    </ldm:creationDate>
	</xsl:template>

	<xsl:template match="a:ModificationDate" mode="properties">
    <ldm:modificationDate rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
      <!-- Powerdesigner uses Epoch time format, change RDF time format -->
      <xsl:value-of select="xs:dateTime('1970-01-01T00:00:00') + xs:dayTimeDuration(concat('PT', ., 'S'))"/>
		</ldm:modificationDate>
	</xsl:template>

	<xsl:template match="a:Comment" mode="properties">
		<ldm:comment><xsl:value-of select="."/></ldm:comment>
	</xsl:template>

	<xsl:template match="a:Description" mode="properties">
    <xsl:variable name="html" xmlns:Rtf2html="nl.architolk.ldt.utils.Rtf2html" select="Rtf2html:rtf2html(.)"/>
    <ldm:description>
      <xsl:for-each xmlns:saxon="http://saxon.sf.net/" select="saxon:parse($html)/html/body/p[.!='']">
        <xsl:if test="position()!=1"><xsl:text>\n</xsl:text></xsl:if>
        <xsl:value-of select="."/>
      </xsl:for-each>
    </ldm:description>
	</xsl:template>

  <xsl:template match="a:Annotation" mode="properties">
    <xsl:variable name="html" xmlns:Rtf2html="nl.architolk.ldt.utils.Rtf2html" select="Rtf2html:rtf2html(.)"/>
    <ldm:annotation>
      <xsl:for-each xmlns:saxon="http://saxon.sf.net/" select="saxon:parse($html)/html/body/p[.!='']">
        <xsl:if test="position()!=1"><xsl:text>\n</xsl:text></xsl:if>
        <xsl:value-of select="."/>
      </xsl:for-each>
    </ldm:annotation>
	</xsl:template>

	<xsl:template match="a:Stereotype" mode="properties">
		<ldm:stereotype><xsl:value-of select="."/></ldm:stereotype>
	</xsl:template>

	<xsl:template match="a:Version" mode="properties">
		<ldm:version><xsl:value-of select="."/></ldm:version>
	</xsl:template>

	<xsl:template match="a:Author" mode="properties">
		<ldm:author><xsl:value-of select="."/></ldm:author>
	</xsl:template>

	<xsl:template match="a:RepositoryFilename" mode="properties">
		<ldm:repositoryFilename><xsl:value-of select="."/></ldm:repositoryFilename>
	</xsl:template>

	<xsl:template match="a:LogicalAttribute.Mandatory|a:BaseAttribute.Mandatory" mode="properties">
		<xsl:choose>
			<xsl:when test=".='1'"><ldm:mandatory rdf:datatype="http://www.w3.org/2001/XMLSchema#boolean">true</ldm:mandatory></xsl:when>
			<xsl:when test=".='0'"><ldm:mandatory rdf:datatype="http://www.w3.org/2001/XMLSchema#boolean">false</ldm:mandatory></xsl:when>
			<xsl:otherwise><ldm:mandatory><xsl:value-of select="."/></ldm:mandatory></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="a:DataType" mode="properties">
		<ldm:dataType><xsl:value-of select="."/></ldm:dataType>
	</xsl:template>

	<xsl:template match="a:Length" mode="properties">
		<ldm:length><xsl:value-of select="."/></ldm:length>
	</xsl:template>

	<xsl:template match="a:ListOfValues" mode="properties">
    <ldm:listOfValues>
      <rdf:Seq>
        <xsl:for-each select="tokenize(.,'\n')">
          <rdf:li>
            <ldm:Value>
              <xsl:variable name="value"><xsl:value-of select="tokenize(.,'\t')[1]"/></xsl:variable>
              <xsl:variable name="label"><xsl:value-of select="tokenize(.,'\t')[2]"/></xsl:variable>
              <ldm:value><xsl:value-of select="$value"/></ldm:value>
              <xsl:choose>
                <xsl:when test="$label!=''">
                  <ldm:label><xsl:value-of select="$label"/></ldm:label>
                  <rdfs:label><xsl:value-of select="$label"/></rdfs:label>
                </xsl:when>
                <xsl:otherwise>
                  <rdfs:label><xsl:value-of select="$value"/></rdfs:label>
                </xsl:otherwise>
              </xsl:choose>
            </ldm:Value>
          </rdf:li>
        </xsl:for-each>
      </rdf:Seq>
    </ldm:listOfValues>
	</xsl:template>

	<xsl:template match="a:Entity1ToEntity2Role" mode="properties">
		<ldm:entity1toEntity2role><xsl:value-of select="."/></ldm:entity1toEntity2role>
	</xsl:template>

	<xsl:template match="a:Entity2ToEntity1Role" mode="properties">
		<ldm:entity2toEntity1role><xsl:value-of select="."/></ldm:entity2toEntity1role>
	</xsl:template>

	<xsl:template match="a:Entity1ToEntity2RoleCardinality" mode="properties">
		<ldm:entity1toEntity2roleCardinality><xsl:value-of select="."/></ldm:entity1toEntity2roleCardinality>
	</xsl:template>

	<xsl:template match="a:Entity2ToEntity1RoleCardinality" mode="properties">
		<ldm:entity2toEntity1roleCardinality><xsl:value-of select="."/></ldm:entity2toEntity1roleCardinality>
	</xsl:template>

	<xsl:template match="a:DependentRole" mode="properties">
    <!-- Seems to be some reference list: A en B? -->
		<ldm:dependentRole><xsl:value-of select="."/></ldm:dependentRole>
	</xsl:template>

  <xsl:template match="a:DominantRole" mode="properties">
    <!-- Seems to be some reference list: A en B? -->
		<ldm:dominantRole><xsl:value-of select="."/></ldm:dominantRole>
	</xsl:template>

	<xsl:template match="a:MutuallyExclusive" mode="properties">
		<ldm:mutuallyExclusive><xsl:value-of select="."/></ldm:mutuallyExclusive>
	</xsl:template>

	<xsl:template match="a:InheritAll" mode="properties">
		<ldm:inheritAll><xsl:value-of select="."/></ldm:inheritAll>
	</xsl:template>

	<xsl:template match="a:BaseLogicalInheritance.Complete" mode="properties">
		<ldm:complete><xsl:value-of select="."/></ldm:complete>
	</xsl:template>

	<xsl:template match="a:Format" mode="properties">
		<ldm:format><xsl:value-of select="."/></ldm:format>
	</xsl:template>

	<xsl:template match="a:LowValue" mode="properties">
		<ldm:lowValue><xsl:value-of select="."/></ldm:lowValue>
	</xsl:template>

  <xsl:template match="a:HighValue" mode="properties">
		<ldm:highValue><xsl:value-of select="."/></ldm:highValue>
	</xsl:template>

	<xsl:template match="a:Precision" mode="properties">
		<ldm:precision><xsl:value-of select="."/></ldm:precision>
	</xsl:template>

  <xsl:template match="a:DefaultValue" mode="properties">
    <ldm:defaultValue><xsl:value-of select="."/></ldm:defaultValue>
  </xsl:template>

  <xsl:template match="a:TargetModelURL" mode="properties">
    <ldm:targetModelURL><xsl:value-of select="."/></ldm:targetModelURL>
  </xsl:template>

  <xsl:template match="a:TargetModelID" mode="properties">
    <ldm:targetModelID rdf:resource="{$prefix}{.}"/>
  </xsl:template>

  <xsl:template match="a:TargetModelClassID" mode="properties">
    <ldm:targetModelClassID rdf:resource="{$prefix}{.}"/>
</xsl:template>

  <xsl:template match="a:TargetModelLastModificationDate" mode="properties">
    <ldm:targetModelLastModificationDate><xsl:value-of select="."/></ldm:targetModelLastModificationDate>
  </xsl:template>

  <xsl:template match="a:TargetStereotype" mode="properties">
    <xsl:if test=".!=''">
      <ldm:targetStereotype><xsl:value-of select="."/></ldm:targetStereotype>
    </xsl:if>
  </xsl:template>

  <xsl:template match="a:TargetID" mode="properties">
    <ldm:targetID rdf:resource="{$prefix}{.}"/>
  </xsl:template>

  <xsl:template match="a:TargetClassID" mode="properties">
    <ldm:targetClassID rdf:resource="{$prefix}{.}" />
  </xsl:template>

  <xsl:template match="a:TargetPackagePath" mode="properties">
    <ldm:targetPackagePath><xsl:value-of select="."/></ldm:targetPackagePath>
  </xsl:template>

  <xsl:template match="a:DataFormat.Type" mode="properties">
    <ldm:dataFormatType><xsl:value-of select="."/></ldm:dataFormatType>
  </xsl:template>

  <xsl:template match="a:DataFormat.Expression" mode="properties">
    <ldm:dataFormatExpression><xsl:value-of select="."/></ldm:dataFormatExpression>
  </xsl:template>

  <xsl:template match="a:Generated" mode="properties">
    <!-- Lijkt een boolean? Waarde kan in ieder geval 0 zijn -->
    <ldm:generated><xsl:value-of select="."/></ldm:generated>
  </xsl:template>

  <xsl:template match="a:Displayed" mode="properties">
    <!-- Lijkt een boolean? Waarde kan in ieder geval 0 zijn -->
    <ldm:displayed><xsl:value-of select="."/></ldm:displayed>
  </xsl:template>

  <xsl:template match="a:OriginalUOL" mode="properties">
    <ldm:originalUOL><xsl:value-of select="."/></ldm:originalUOL>
  </xsl:template>

  <xsl:template match="a:OriginalClassID" mode="properties">
    <ldm:originalClassID rdf:resource="{$prefix}{.}"/>
  </xsl:template>

  <xsl:template match="a:OriginalID" mode="properties">
    <ldm:originalID rdf:resource="{$prefix}{.}"/>
  </xsl:template>

  <xsl:template match="a:History" mode="properties">
    <!-- TODO: History is a string, but seems to be structured -->
  </xsl:template>

  <xsl:template match="a:ExtendedAttributesText" mode="properties">
    <!-- Extended attributes text contains the particular extensions to the "normal" fields -->
    <!-- Related to a XEM, but haven't parsed one yet... -->
    <xsl:for-each select="tokenize(.,'\n')">
      <xsl:variable name="key" select="substring-before(substring-after(.,'{'),'}')"/>
      <xsl:if test="$key!=''">
        <ldm:extendedAttributeText>
          <rdf:Description>
            <ldm:key rdf:resource="{$prefix}{$key}"/>
            <ldm:unparsedText><xsl:value-of select="."/></ldm:unparsedText> <!-- TODO: Parse this! -->
          </rdf:Description>
        </ldm:extendedAttributeText>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="a:ExtendedBaseCollection.CollectionName" mode="properties">
    <ldm:collectionName><xsl:value-of select="."/></ldm:collectionName>
  </xsl:template>

  <xsl:template match="a:BaseDataSource.ModelType" mode="properties">
    <ldm:modelType rdf:resource="{$prefix}{.}"/>
  </xsl:template>

  <xsl:template match="a:AccessType" mode="properties">>
    <!-- Seems to be a list of values. Value RO is allowed -->
    <ldm:accessType><xsl:value-of select="."/></ldm:accessType>
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

	<xsl:template match="c:AttachedRules" mode="properties">
		<xsl:for-each select="o:BusinessRule">
			<ldm:attachedRule rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="c:Object1" mode="properties">
		<xsl:for-each select="o:Entity|o:Shortcut"> <!--Not sure if shortcut is always an entity, but cannot find out... -->
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
		<xsl:for-each select="o:Entity|o:Shortcut"> <!--Not sure if shortcut is always an entity, but cannot find out... -->
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

	<xsl:template match="c:Domain" mode="properties">
		<xsl:for-each select="o:Domain|o:Shortcut">
			<ldm:domain rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="c:ParentEntity" mode="properties">
		<xsl:for-each select="o:Entity">
			<ldm:parentEntity rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="c:DataItem" mode="properties">
		<xsl:for-each select="o:DataItem">
			<ldm:dataItem rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
		</xsl:for-each>
	</xsl:template>

  <xsl:template match="c:ExtendedModelDefinitions" mode="properties">
    <xsl:for-each select="o:Shortcut">
      <ldm:hasExtendedModelDefinition rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:Domains" mode="properties">
    <xsl:for-each select="o:Domain">
      <ldm:hasDomain rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
    <xsl:for-each select="o:Shortcut">
      <ldm:hasDomain rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:TargetModels" mode="properties">
    <xsl:for-each select="o:TargetModel">
      <ldm:hasTargetModel rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:Relationships" mode="properties">
    <xsl:for-each select="o:Relationship">
      <ldm:hasRelationship rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:Replications" mode="properties">
    <xsl:for-each select="o:Replication">
      <ldm:hasReplication rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:SubReplications" mode="properties">
    <xsl:for-each select="o:SubReplication">
      <ldm:hasSubReplication rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:Entities" mode="properties">
    <xsl:for-each select="o:Entity">
      <ldm:hasEntity rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:SubEntities" mode="properties">
    <xsl:for-each select="o:Shortcut">
      <ldm:hasSubEntity rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:FullShortcutReplica" mode="properties">
    <xsl:for-each select="o:Replication|o:SubReplication">
      <ldm:hasFullShortcutReplica rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:SubShortcuts" mode="properties">
    <xsl:for-each select="o:Shortcut">
      <ldm:subShortcut rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:FormatObjects" mode="properties">
    <xsl:for-each select="o:DataFormat">
      <ldm:formatObject rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:GeneratedModels" mode="properties">
    <xsl:for-each select="o:Shortcut">
      <ldm:hasGeneratedModel rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:SourceModels" mode="properties">
    <xsl:for-each select="o:Shortcut">
      <ldm:hasSourceModel rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:Mappings" mode="properties">
    <xsl:for-each select="o:DefaultObjectMapping">
      <ldm:hasMapping rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:Classifier" mode="properties">
    <xsl:for-each select="o:Entity">
      <ldm:classifier rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:SourceClassifiers" mode="properties">
    <xsl:for-each select="o:Shortcut">
      <ldm:sourceClassifier rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:DefaultMapping" mode="properties">
    <xsl:for-each select="o:DefaultObjectMapping">
      <ldm:defaultMapping rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:SessionShortcuts" mode="properties">
    <xsl:for-each select="o:Shortcut">
      <ldm:sessionShortcut rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:PersistentSelectionManagers" mode="properties">
    <!-- TODO: Voorlopig niet -->
    <!--
    <xsl:for-each select="o:PersistentSelectionManager" mode="properties">
      <ldm:hasPersistentSelectionManager rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
    -->
  </xsl:template>

  <xsl:template match="c:ListReports" mode="properties">
    <!-- TODO: Voorlopig niet -->
  </xsl:template>

  <xsl:template match="c:SessionReplications" mode="properties">
    <xsl:for-each select="o:Replication">
      <ldm:sessionReplication rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:FullShortcutModel" mode="properties">
    <xsl:for-each select="o:Model">
      <ldm:hasFullShortcutModel rdf:resource="{$prefix}{a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:LinkShortcutExtremities" mode="properties">
    <xsl:for-each select="o:Shortcut">
      <ldm:linkShortcutExtremities rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:Content" mode="properties">
    <xsl:for-each select="o:Shortcut">
      <ldm:hasContent rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:ReplicaObject" mode="properties">
    <!-- Replica objects can be anything, so a * for-each -->
    <xsl:for-each select="*">
      <ldm:hasReplicaObject rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:BaseStructuralFeatureMapping.Feature" mode="properties">
    <xsl:for-each select="a:EntityAttribute">
      <ldm:feature rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:SourceFeatures" mode="properties">
    <xsl:for-each select="a:Shortcut">
      <ldm:sourceFeature rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:DataSource" mode="properties">
    <xsl:for-each select="o:DefaultDataSource">
      <ldm:dataSource rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="c:BaseDataSource.SourceModels" mode="properties">
    <xsl:for-each select="o:Shortcut">
      <ldm:sourceModel rdf:resource="{$prefix}{key('item',@Ref)/a:ObjectID}"/>
    </xsl:for-each>
  </xsl:template>

	<!-- Catch all properties -->
	<xsl:template match="*" mode="properties">
		<rdfs:label>TODO: <xsl:value-of select="../local-name()"/>/<xsl:value-of select="local-name()"/></rdfs:label>
	</xsl:template>

	<!-- Resource parsing -->
	<xsl:template match="o:Model" mode="parse">
		<ldm:Model rdf:about="{$prefix}{a:ObjectID}">
      <!-- Literal properties -->
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment|a:Author|a:Version|a:RepositoryFilename|a:History" mode="properties"/>
      <!-- Relations properties -->
      <xsl:apply-templates select="c:ExtendedModelDefinitions|c:Domains|c:TargetModels|c:Relationships|c:Replications|c:Entities|c:GeneratedModels|c:SourceModels|c:PersistentSelectionManagers|c:ListReports" mode="properties"/>
		</ldm:Model>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

  <xsl:template match="c:TargetModels" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="o:TargetModel" mode="parse">
    <ldm:Targetmodel rdf:about="{$prefix}{a:ObjectID}">
      <!-- Literal properties -->
      <xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:TargetModelURL|a:TargetModelID|a:TargetModelClassID|a:TargetModelLastModificationDate" mode="properties"/>
      <!-- Relations properties -->
      <xsl:apply-templates select="c:SessionReplications|c:FullShortcutModel" mode="properties"/>
    </ldm:Targetmodel>
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="c:FullShortcutModel" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

	<xsl:template match="c:LogicalDiagrams|c:DefaultDiagram|c:Reports|a:PackageOptionsText|a:ModelOptionsText" mode="parse">
		<!-- Don't process diagrams or technical options: that's visualisation! -->
	</xsl:template>

	<xsl:template match="c:Entities" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:Entity" mode="parse">
		<ldm:Entity rdf:about="{$prefix}{a:ObjectID}">
			<!-- Literal properties -->
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment|a:Generated|a:History" mode="properties"/>
			<!-- Relations properties -->
			<xsl:apply-templates select="c:Attributes/o:EntityAttribute" mode="properties"/> <!-- Inline -->
			<xsl:apply-templates select="c:Identifiers/o:Identifier" mode="properties"/> <!-- Inline -->
			<xsl:apply-templates select="c:PrimaryIdentifier" mode="properties"/> <!-- Refs -->
			<xsl:apply-templates select="c:AttachedRules" mode="properties"/> <!-- Refs -->
      <xsl:apply-templates select="c:SubEntities" mode="properties"/> <!-- Inline -->
		</ldm:Entity>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

  <xsl:template match="c:SubEntities" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="c:ExtendedCollections" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="o:ExtendedCollection" mode="parse">
    <ldm:ExtenedCollection rdf:about="{$prefix}{a:ObjectID}">
      <!-- Literal properties -->
      <xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:ExtendedBaseCollection.CollectionName" mode="properties"/>
      <!-- Relations properties -->
			<xsl:apply-templates select="c:Content" mode="properties"/>
    </ldm:ExtenedCollection>
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

	<xsl:template match="c:Attributes" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:EntityAttribute" mode="parse">
		<ldm:Attribute rdf:about="{$prefix}{a:ObjectID}">
		<xsl:choose>
			<xsl:when test="c:DataItem/o:DataItem/@Ref!=''">
				<!-- When DataItem exists, the DataItems are the "first class citizens" -->
				<rdfs:label><xsl:value-of select="key('item',c:DataItem/o:DataItem/@Ref)/a:Name"/></rdfs:label>
				<xsl:apply-templates select="a:ObjectID|a:BaseAttribute.Mandatory" mode="properties"/>
				<!-- Relations propertie -->
				<xsl:apply-templates select="c:DataItem" mode="properties"/>
			</xsl:when>
			<xsl:otherwise>
					<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment|a:LogicalAttribute.Mandatory|a:DataType|a:Length|a:ListOfValues|a:LowValue|a:HighValue|a:Format|a:Precision|a:DefaultValue|a:History|a:Displayed|a:ExtendedAttributesText" mode="properties"/>
					<!-- Relations properties -->
					<xsl:apply-templates select="c:InheritedFrom|c:Domain|c:FormatObjects" mode="properties"/>
			</xsl:otherwise>
		</xsl:choose>
		</ldm:Attribute>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:DataItems" mode="parse">
			<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:DataItem" mode="parse">
		<ldm:DataItem rdf:about="{$prefix}{a:ObjectID}">
			<xsl:apply-templates select="*|a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment|a:DataType|a:Length|a:ListOfValues" mode="properties"/>
			<!-- Relations properties -->
			<xsl:apply-templates select="c:Domain" mode="properties"/>
		</ldm:DataItem>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:Identifiers" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:Identifier" mode="parse">
		<ldm:Identifier rdf:about="{$prefix}{a:ObjectID}">
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment|a:History" mode="properties"/>
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
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment|a:Entity1ToEntity2Role|a:Entity2ToEntity1Role|a:Entity1ToEntity2RoleCardinality|a:Entity2ToEntity1RoleCardinality|a:DependentRole|a:DominantRole|a:History" mode="properties"/>
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
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment" mode="properties"/>
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
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment|a:MutuallyExclusive|a:InheritAll" mode="properties"/>
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
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment" mode="properties"/>
			<!-- Relations properties -->
			<xsl:apply-templates select="c:Object1|c:Object2" mode="properties"/>
		</ldm:InheritanceLink>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:RootObject" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
		<!-- RootObject doesn't seem to have informative content, ignore -->
		<!-- Only available property currently is o:SessionID -->
	</xsl:template>

	<xsl:template match="c:Children" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:Domains" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:Domain" mode="parse">
		<ldm:Domain rdf:about="{$prefix}{a:ObjectID}">
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment|a:DataType|a:Length|a:ListOfValues|a:LowValue|a:HighValue|a:Format|a:Precision|a:DefaultValue" mode="properties"/>
      <!-- Relations properties -->
      <xsl:apply-templates select="c:FormatObjects" mode="properties"/>
		</ldm:Domain>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

  <!-- Shortcuts can be anything, some information is available from the shortcut itself -->
  <xsl:template match="o:Shortcut" mode="parse">
    <ldm:Shortcut rdf:about="{$prefix}{a:ObjectID}">
      <!-- Literal properties -->
      <xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:TargetStereotype|a:TargetID|a:TargetClassID|a:TargetPackagePath|a:History" mode="properties"/>
      <!-- Relations properties -->
      <xsl:apply-templates select="c:FullShortcutReplica|c:SubShortcuts|c:LinkShortcutExtremities" mode="properties"/>
    </ldm:Shortcut>
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="c:SubShortcuts" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

	<xsl:template match="c:BusinessRules" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:BusinessRule" mode="parse">
		<ldm:BusinessRule rdf:about="{$prefix}{a:ObjectID}">
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment" mode="properties"/>
		</ldm:BusinessRule>
	</xsl:template>

	<xsl:template match="c:ChildTraceabilityLinks" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="o:ExtendedDependency" mode="parse">
		<ldm:ExtendedDependency rdf:about="{$prefix}{a:ObjectID}">
      <!-- Literal properties -->
			<xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment" mode="properties"/>
			<!-- Relations properties -->
			<xsl:apply-templates select="c:Object1|c:Object2" mode="properties"/>
		</ldm:ExtendedDependency>
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

	<xsl:template match="c:GeneratedModels" mode="parse">
		<xsl:apply-templates select="*" mode="parse"/>
	</xsl:template>

  <xsl:template match="c:SourceModels" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="c:Mappings" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

	<xsl:template match="c:ConceptualDiagrams" mode="parse">
		<!-- Don't bother with layout -->
	</xsl:template>

  <xsl:template match="c:Replications" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="o:Replication" mode="parse">
    <ldm:Replication rdf:about="{$prefix}{a:ObjectID}">
      <!-- Literal properties -->
      <xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:OriginalUOL|a:OriginalClassID|a:OriginalID" mode="properties"/>
      <!-- Relations properties -->
			<xsl:apply-templates select="c:SubReplications|c:ReplicaObject" mode="properties"/>
    </ldm:Replication>
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="c:SubReplications" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="o:SubReplication" mode="parse">
    <ldm:SubReplication rdf:about="{$prefix}{a:ObjectID}">
      <xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:OriginalUOL|a:OriginalClassID|a:OriginalID" mode="properties"/>
    </ldm:SubReplication>
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="c:ExtendedModelDefinitions" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="c:DataFormats" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="o:DataFormat" mode="parse">
    <ldm:DataFormat rdf:about="{$prefix}{a:ObjectID}">
      <xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:DataFormat.Type|a:DataFormat.Expression" mode="properties"/>
    </ldm:DataFormat>
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="o:DefaultObjectMapping" mode="parse">
    <ldm:DefaultObjectMapping rdf:about="{$prefix}{a:ObjectID}">
      <!-- Literal properties -->
      <xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate" mode="properties"/>
      <!-- Relations properties -->
			<xsl:apply-templates select="c:Classifier|c:SourceClassifiers|c:DataSource" mode="properties"/>
    </ldm:DefaultObjectMapping>
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="c:StructuralFeatureMaps" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="o:DefaultStructuralFeatureMapping" mode="parse">
    <ldm:DefaultStructuralFeatureMapping rdf:about="{$prefix}{a:ObjectID}">
      <!-- Literal properties -->
      <xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate" mode="properties"/>
      <!-- Relations properties -->
			<xsl:apply-templates select="c:BaseStructuralFeatureMapping.Feature|c:SourceFeatures" mode="properties"/>
    </ldm:DefaultStructuralFeatureMapping>
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="c:PersistentSelectionManagers" mode="parse">
    <xsl:apply-templates select="o:PersistentSelectionManager" mode="parse"/>
  </xsl:template>

  <xsl:template match="o:PersistentSelectionManager" mode="parse">
    <!-- TODO: Doesn't seem that important -->
  </xsl:template>

  <xsl:template match="c:ListReports" mode="parse">
    <xsl:apply-templates select="o:ListReport" mode="parse"/>
  </xsl:template>

  <xsl:template match="o:ListReport" mode="parse">
    <!-- TODO: Doesn't seem that important -->
  </xsl:template>

  <xsl:template match="c:DataSources" mode="parse">
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

  <xsl:template match="o:DefaultDataSource" mode="parse">
    <ldm:DefaultDataSource rdf:about="{$prefix}{a:ObjectID}">
      <!-- Literal properties -->
      <xsl:apply-templates select="a:ObjectID|a:Name|a:Code|a:Creator|a:CreationDate|a:Modifier|a:ModificationDate|a:BaseDataSource.ModelType|a:AccessType" mode="properties"/>
      <!-- Relations properties -->
      <xsl:apply-templates select="c:BaseDataSource.SourceModels" mode="properties"/>
    </ldm:DefaultDataSource>
    <xsl:apply-templates select="*" mode="parse"/>
  </xsl:template>

	<!-- Properties, don't parse them as resources -->
	<xsl:template match="a:SessionID|a:ObjectID|a:Name|a:Code|a:Creator|a:Modifier|a:CreationDate|a:ModificationDate|a:Description|a:Annotation|a:Stereotype|a:Comment|a:Author|a:Version|a:RepositoryFilename|a:BaseAttribute.Mandatory|a:LogicalAttribute.Mandatory|a:DataType|a:Length|a:ListOfValues|a:Entity1ToEntity2Role|a:Entity2ToEntity1Role|a:Entity1ToEntity2RoleCardinality|a:Entity2ToEntity1RoleCardinality|a:DependentRole|a:DominantRole|a:MutuallyExclusive|a:InheritAll|a:BaseLogicalInheritance.Complete|a:LowValue|a:HighValue|a:Format|a:Precision|a:TargetModelURL|a:TargetModelID|a:TargetModelClassID|a:TargetModelLastModificationDate|a:TargetStereotype|a:TargetID|a:TargetClassID|a:TargetPackagePath|a:DefaultValue|a:DataFormat.Type|a:DataFormat.Expression|a:Generated|a:OriginalUOL|a:OriginalClassID|a:OriginalID|a:History|a:Displayed|a:ExtendedAttributesText|a:ExtendedBaseCollection.CollectionName|a:BaseDataSource.ModelType|a:AccessType" mode="parse">
		<!-- Nothing to do -->
	</xsl:template>

	<!-- Relation properties, don't parse them as resources -->
	<xsl:template match="c:PrimaryIdentifier|c:Identifier.Attributes|c:Object1|c:Object2|c:AttachedRules|c:ParentIdentifier|c:InheritedFrom|c:Domain|c:ParentEntity|c:DataItem|c:FullShortcutReplica|c:FormatObjects|c:Classifier|c:SourceClassifiers|c:DefaultMapping|c:SessionShortcuts|c:SessionReplications|c:LinkShortcutExtremities|c:Content|c:ReplicaObject|c:BaseStructuralFeatureMapping.Feature|c:SourceFeatures|c:DataSource|c:BaseDataSource.SourceModels" mode="parse">
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
