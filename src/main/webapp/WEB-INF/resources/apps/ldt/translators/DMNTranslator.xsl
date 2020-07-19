<!--

    NAME     DMNTranslator.xsl
    VERSION  1.25.0
    DATE     2020-07-19

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
	Translates XML/DMN to a conforming RDF/DMN representation
	
	TODO (in order of importance)
	- Find a way to resolve namespaces in attributes or text nodes
	- Find a solution for handling properties that have a parent class as related class. Those properties are marked with a comment.
	- Find a solution for handling properties that have more than one related class. Thos properties are marked with a comment. 
	  NOTE: if the solution to the previous todo is general enough, this todo is also fixed.
	
-->
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:dmn="http://www.omg.org/spec/DMN/20151101/dmn.xsd"
	xmlns:dmno="http://www.omg.org/spec/DMN/20151101/dmn#"
	xmlns:uitv="http://data.digitaalstelselomgevingswet.nl/v0.6/Uitvoeringsregels#"
	xmlns:bedr="http://data.digitaalstelselomgevingswet.nl/v0.6/Bedrijfsregels#" 
	xmlns:content="http://data.digitaalstelselomgevingswet.nl/v0.6/Content#"
>

	<!--
		Standard template for all properties. The translation makes all classes explicit and gives them an ID
		which is guaranteed to be unique for the source file, but unlikely to be unique across multiple files.
		TODO: find a way of generating id's that are more likely to be unique across multiple files.
		
		Unfortunately, we cannot be certain all properties have an id. In case it doesn't, we create an id ourselves, based on the predicate
		and the position in which the item appears in the source file.
	-->	

	<xsl:template name="process-property">
		<xsl:param name="property" />
		<xsl:param name="class" />		
		<xsl:param name="namespace" select="'dmno'" />		
		<xsl:param name="namespaceUri" select="'http://www.omg.org/spec/DMN/20151101/dmn#'" />		
		
		<xsl:variable name="propertyWithNs" select="concat($namespace, ':', $property)" />
		<xsl:variable name="classWithNs">
			<xsl:call-template name="namespaceCheck">
				<xsl:with-param name="namespace"><xsl:value-of select="$namespaceUri"/></xsl:with-param>
			</xsl:call-template>
			<xsl:value-of select="$class"/>
		</xsl:variable>
		
		<xsl:element name="{$propertyWithNs}">
			<xsl:choose>
				<xsl:when test="exists(@href)"><xsl:attribute name="rdf:resource"><xsl:value-of select="concat('urn:uuid:',substring-after(@href,'#'))"/></xsl:attribute></xsl:when>
				<xsl:otherwise>
					<rdf:Description>
						<xsl:call-template name="print-id"/>
						<xsl:call-template name="print-name">
							<xsl:with-param name="property"><xsl:value-of select="$property"/></xsl:with-param>
						</xsl:call-template>
						
						<rdf:type rdf:resource="{$classWithNs}"/>
						<xsl:apply-templates select="@*"/>
						<xsl:apply-templates/>
					</rdf:Description>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:template>	
	
	<xsl:template name="print-id">
		<xsl:attribute name="rdf:about"><xsl:call-template name="process-id" /></xsl:attribute>
	</xsl:template>
	
	<xsl:template name="process-id">
		<xsl:variable name="generatedId"><xsl:value-of select="generate-id()" /></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)">urn:uuid:<xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('urn:uuid:',local-name(.),'_',$generatedId)"/></xsl:otherwise>
			</xsl:choose> 
		</xsl:variable>
		<xsl:value-of select="$id"/>
	</xsl:template>
	
	<xsl:template name="print-name">
		<xsl:param name="property"/>
		<rdfs:label><xsl:call-template name="process-name"><xsl:with-param name="property"><xsl:value-of select="$property"/></xsl:with-param></xsl:call-template></rdfs:label>
	</xsl:template>
	
	<xsl:template name="process-name">
		<xsl:param name="property"/>
		<xsl:variable name="generatedId"><xsl:value-of select="generate-id()" /></xsl:variable>
		<xsl:variable name="name">
			<xsl:choose>
				<xsl:when test="exists(@name)">
					<xsl:choose>
						<xsl:when test="@name = ''">Empty named <xsl:value-of select="$property"/> with id <xsl:value-of select="$generatedId"/></xsl:when>
						<xsl:otherwise><xsl:value-of select="@name"/></xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="exists(@outputLabel)">
					<xsl:choose>
						<xsl:when test="@outputLabel = ''">Empty named <xsl:value-of select="$property"/> with id <xsl:value-of select="$generatedId"/></xsl:when>
						<xsl:otherwise><xsl:value-of select="@outputLabel"/></xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="concat($property,'_',$generatedId)"/></xsl:otherwise>
			</xsl:choose> 
		</xsl:variable>
		<xsl:value-of select="$name"/>
	</xsl:template>
	
	<xsl:template name="process">
		<xsl:param name="property" select="local-name()" />
		<xsl:param name="class" />
		<xsl:param name="namespace" select="'dmno'" />
		<xsl:param name="namespaceUri" select="'http://www.omg.org/spec/DMN/20151101/dmn#'" />		
		
		<xsl:variable name="camelcasedProperty">
			<xsl:choose>
				<xsl:when test="$class = ''">
					<xsl:call-template name="camelcase">
						<xsl:with-param name="text">
							<xsl:value-of select="$property" />
						</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$class" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:call-template name="process-property">
			<xsl:with-param name="property"><xsl:value-of select="$property" /></xsl:with-param>
			<xsl:with-param name="class"><xsl:value-of select="$camelcasedProperty" /></xsl:with-param>
			<xsl:with-param name="namespace"><xsl:value-of select="$namespace" /></xsl:with-param>
			<xsl:with-param name="namespaceUri"><xsl:value-of select="$namespaceUri" /></xsl:with-param>
		</xsl:call-template>		
	</xsl:template>
		
	
	<!-- Global variables -->
	<xsl:variable name="feel-prefix">http://www.omg.org/spec/FEEL/20140401/</xsl:variable>
	
	<!-- Main entry -->
	<xsl:template match="/root">
		<rdf:RDF>
			<xsl:apply-templates select="dmn:definitions"/>
		</rdf:RDF>
	</xsl:template>
	
	<xsl:template match="dmn:definitions">
		<dmno:Definitions rdf:about="{concat('urn:uuid:',@id)}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates/>
		</dmno:Definitions>
	</xsl:template>
	
	<!--
		This is the global template where we map all properties on a class with a capital letter. It uses the process template to do this.
		
		The property businessKnowledgeModel is officially not part of DMN, which instead uses the shorter property bkm.
		However, since in the official example of the Object Management Group and in the generated files from tools,
		the property businessKnowledgeModel is used, it is included in the Translator as well.
	-->
	<xsl:template match="dmn:artifact|						 
						 dmn:authorityRequirement|
						 dmn:binding|
						 dmn:businessContextElement|
						 dmn:context|
						 dmn:contextEntry|
						 dmn:decision|
						 dmn:decisionService|
						 dmn:extensionAttribute|
						 dmn:functionDefinition|
						 dmn:extensionElements|
						 dmn:import|
						 dmn:importedValues| 
						 dmn:informationRequirement|
						 dmn:inputData|
						 dmn:invocation|
						 dmn:itemDefinition|
						 dmn:knowledgeRequirement|
						 dmn:knowledgeSource|
						 dmn:list|
						 dmn:literalExpression|
						 dmn:organizationUnit|
						 dmn:performanceIndicator|
						 dmn:relation|
						 dmn:textAnnotation|
						 dmn:association|
						 dmn:businessKnowledgeModel">
		<xsl:call-template name="process" />
	</xsl:template>
	
	<!-- Properties with classes -->
	<xsl:template match="dmn:allowedInItemDefinition">
		<xsl:call-template name="process">
			<xsl:with-param name="class">ItemDefinition</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>	
	
	<xsl:template match="dmn:allowedValues">
		<xsl:call-template name="process">
			<xsl:with-param name="class">UnaryTests</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:bindingFormula">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Expression</xsl:with-param>	<!-- Related class is a parent class -->
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:bkm">
		<xsl:call-template name="process">
			<xsl:with-param name="class">BusinessKnowledgeModel</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:body">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Expression</xsl:with-param>	<!-- Related class is a parent class -->
		</xsl:call-template>		
	</xsl:template>
		
	<xsl:template match="dmn:calledFunction">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Expression</xsl:with-param>	<!-- Related class is a parent class -->
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:caller">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Invocation</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:collection">
		<xsl:call-template name="process">
			<xsl:with-param name="class">ElementCollection</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:column">
		<xsl:call-template name="process">
			<xsl:with-param name="class">InformationItem</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:containingDefinition">
		<xsl:call-template name="process">
			<xsl:with-param name="class">ItemDefinition</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:decisionLogic">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Expression</xsl:with-param>	<!-- Related class is a parent class -->
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:decisionMade">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Expression</xsl:with-param>	<!-- Related class is a parent class -->
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:decisionMaker">
		<xsl:call-template name="process">
			<xsl:with-param name="class">OrganisationalUnit</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:decisionOutput">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Decision</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:decisionOwned">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Decision</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:decisionOwner">
		<xsl:call-template name="process">
			<xsl:with-param name="class">OrganisationalUnit</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<!--
		The DecisionTable-template is quite complex.
		This is necessary because the rows (inputs and output) and columns (inputEntries and outputEntry)
		need to be counted in order to give them a proper id which can be used for matching them later.
	-->
	<xsl:template match="dmn:decisionTable">
		<xsl:variable name="id">
			<xsl:call-template name="process-id" />
		</xsl:variable>	
		<dmno:decisionTable>
			<rdf:Description rdf:about="{$id}">
				<xsl:call-template name="print-name">
					<xsl:with-param name="property">decisionTable</xsl:with-param>
				</xsl:call-template>
				<rdf:type rdf:resource="http://www.omg.org/spec/DMN/20151101/dmn#DecisionTable"/>
				<xsl:apply-templates select="@*"/>
				<xsl:apply-templates select="dmn:input">
					<xsl:with-param name="dtid"><xsl:value-of select="$id"/></xsl:with-param>
				</xsl:apply-templates>
				<xsl:apply-templates select="dmn:output">
					<xsl:with-param name="dtid"><xsl:value-of select="$id"/></xsl:with-param>
				</xsl:apply-templates>
				<xsl:for-each select="dmn:rule">
					<dmno:rule>
						<rdf:Description>
							<xsl:call-template name="print-id" />
							<xsl:call-template name="print-name">
								<xsl:with-param name="property">rule</xsl:with-param>
							</xsl:call-template>
							<rdf:type rdf:resource="http://www.omg.org/spec/DMN/20151101/dmn#DecisionRule"/>
							<xsl:apply-templates select="dmn:inputEntry">
								<xsl:with-param name="dtid"><xsl:value-of select="$id"/></xsl:with-param>
							</xsl:apply-templates>
							<xsl:apply-templates select="dmn:outputEntry">
								<xsl:with-param name="dtid"><xsl:value-of select="$id"/></xsl:with-param>
							</xsl:apply-templates>
						</rdf:Description>
					</dmno:rule>
				</xsl:for-each>
			</rdf:Description>
		</dmno:decisionTable>
	</xsl:template>
	
	<xsl:template match="dmn:defaultOutputEntry">
		<xsl:call-template name="process">
			<xsl:with-param name="class">LiteralExpression</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:drgElement">
		<xsl:call-template name="process">
			<xsl:with-param name="class">DRGElement</xsl:with-param>	<!-- Related class is a parent class -->
		</xsl:call-template>		
	</xsl:template>
	
	<!--
		This property can have two related classes: DMNElement and Expression.
		Both of those classes are parent classes.
		TODO: find a way to deal with that (how to determine which class it should be.
	-->
	<xsl:template match="dmn:element">
		<xsl:call-template name="process">
			<xsl:with-param name="class">DMNElement</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:elements">
		<xsl:call-template name="process">
			<xsl:with-param name="class">ExtensionElements</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:encapsulatedDecision">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Decision</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:encapsulatedDecisions">
		<xsl:call-template name="process">
			<xsl:with-param name="class">ElementCollection</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:encapsulatedLogic">
		<xsl:call-template name="process">
			<xsl:with-param name="class">FunctionDefinition</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:exporter">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Definitions</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:expressionInput">
		<xsl:call-template name="process">
			<xsl:with-param name="class">InputClause</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>	
	
	<xsl:template match="dmn:extensionElement">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Element</xsl:with-param>	<!-- Related class is a parent class -->
		</xsl:call-template>		
	</xsl:template>
		
	<xsl:template match="dmn:formalParameter">
		<xsl:call-template name="process">
			<xsl:with-param name="class">InformationItem</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
		
	<xsl:template match="dmn:impactedPerformanceIndicator">
		<xsl:call-template name="process">
			<xsl:with-param name="class">PerformanceIndicator</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<xsl:template match="dmn:impactingDecision">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Decision</xsl:with-param>			
		</xsl:call-template>		
	</xsl:template>
	
	<!-- Part of a decision table; it therefore follows a different pattern (see comment at the decisionTable property) -->
	<xsl:template match="dmn:input">
		<xsl:param name="dtid"/>
		<xsl:variable name="inputNumber"><xsl:number/></xsl:variable>
		<dmno:input>
			<!-- Here we generate our own ids, because we need to reference them later in the rules -->
			<dmno:InputClause rdf:about="{$dtid}_input_{$inputNumber}">
				<xsl:call-template name="print-name">
					<xsl:with-param name="property">input</xsl:with-param>
				</xsl:call-template>
				<xsl:apply-templates/>
			</dmno:InputClause>
		</dmno:input>
	</xsl:template>
	
	<xsl:template match="dmn:inputDecision">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Decision</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<!-- Part of a decision table; it therefore follows a different pattern (see comment at the decisionTable property) -->
	<xsl:template match="dmn:inputEntry">
		<xsl:param name="dtid"/>
		<xsl:variable name="inputEntryNumber"><xsl:number/></xsl:variable>
		<dmno:inputEntry>
			<dmno:UnaryTests>
				<xsl:call-template name="print-id" />
				<xsl:call-template name="print-name">
					<xsl:with-param name="property">inputEntry</xsl:with-param>
				</xsl:call-template>
				<dmno:relatedInput rdf:resource="{$dtid}_input_{$inputEntryNumber}"/> <!-- Not part of the DMN specification -->
				<xsl:apply-templates/>
			</dmno:UnaryTests>
		</dmno:inputEntry>
	</xsl:template>
	
	<xsl:template match="dmn:inputExpression">
		<xsl:call-template name="process">
			<xsl:with-param name="class">LiteralExpression</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:inputValues">
		<xsl:call-template name="process">
			<xsl:with-param name="class">UnaryTests</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
		
	<xsl:template match="dmn:itemComponents|dmn:itemComponent">
		<xsl:call-template name="process">
			<xsl:with-param name="class">ItemDefinition</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:output">
		<xsl:param name="dtid"/>
		<xsl:variable name="outputNumber"><xsl:number/></xsl:variable>
		<dmno:output>
			<!-- Here we generate our own ids, because we need to reference them later in the rules -->
			<dmno:OutputClause rdf:about="{$dtid}_output_{$outputNumber}">
				<xsl:choose>
					<xsl:when test="exists(@name)">
						<rdfs:label><xsl:value-of select="@name" /></rdfs:label>
					</xsl:when>
					<xsl:when test="exists(../@outputLabel)">
						<rdfs:label><xsl:value-of select="../@outputLabel" /></rdfs:label>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="print-name">
							<xsl:with-param name="property">output</xsl:with-param>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
				
				<xsl:apply-templates/>
			</dmno:OutputClause>
		</dmno:output>
	</xsl:template>			
	
	<xsl:template match="dmn:outputDecision">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Decision</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:outputDefinition">
		<xsl:call-template name="process">
			<xsl:with-param name="class">ItemDefinition</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<!-- Part of a decision table; it therefore follows a different pattern (see comment at the decisionTable property) -->
	<xsl:template match="dmn:outputEntry">
		<xsl:param name="dtid"/>
		<xsl:variable name="outputEntryNumber"><xsl:number/></xsl:variable>
		<dmno:outputEntry>			
			<dmno:LiteralExpression>				
				<xsl:call-template name="print-id" />
				<xsl:call-template name="print-name">
					<xsl:with-param name="property">outputEntry</xsl:with-param>
				</xsl:call-template>
				<dmno:relatedOutput rdf:resource="{$dtid}_output_{$outputEntryNumber}"/> <!-- Not part of the DMN specification -->
				<xsl:apply-templates/>
			</dmno:LiteralExpression>
		</dmno:outputEntry>
	</xsl:template>
	
	<xsl:template match="dmn:outputValues">
		<xsl:call-template name="process">
			<xsl:with-param name="class">UnaryTests</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<!--
		The property 'owner' should be a plain property according to the DMN spec. However, in practice it is a property
		with as related class 'OrganisationalUnit', as evidenced by the DMN-files generated from tools.
	-->
	<xsl:template match="dmn:owner">
		<xsl:call-template name="process">
			<xsl:with-param name="class">OrganisationalUnit</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
		
	<xsl:template match="dmn:parameter">
		<xsl:call-template name="process">
			<xsl:with-param name="class">InformationItem</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:requiredAuthority">
		<xsl:call-template name="process">
			<xsl:with-param name="class">KnowledgeSource</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:requiredDecision">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Decision</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:requiredInput">
		<xsl:call-template name="process">
			<xsl:with-param name="class">InputData</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:requiredKnowledge">
		<xsl:call-template name="process">
			<xsl:with-param name="class">BusinessKnowledgeModel</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:row">
		<xsl:call-template name="process">
			<xsl:with-param name="class">List</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:ruleInput">
		<xsl:call-template name="process">
			<xsl:with-param name="class">DecisionRule</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:ruleOutput">
		<xsl:call-template name="process">
			<xsl:with-param name="class">DecisionRule</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:sourceRef">
		<xsl:call-template name="process">
			<xsl:with-param name="class">DMNElement</xsl:with-param>	<!-- Related class is a parent class -->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:targetRef">
		<xsl:call-template name="process">
			<xsl:with-param name="class">DMNElement</xsl:with-param>	<!-- Related class is a parent class -->
		</xsl:call-template>
	</xsl:template>
	
	<!--
		The property 'type' should have as related class ItemDefinition. However, some tools deliver it as a plain property.
		To accommodate that, we first check if the property has any child elements. If so, the regular template is called.
		If not, the text is added as a label.
	-->
	<xsl:template match="dmn:type">
		<xsl:choose>
			<xsl:when test="*">
				<xsl:call-template name="process">
					<xsl:with-param name="class">ItemDefinition</xsl:with-param>			
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise><rdfs:label><xsl:value-of select="."/></rdfs:label></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!--
		This property can have two related classes: Element and Expression.
		Expression is a parent class.
		TODO: find a way to deal with that (how to determine which class it should be.
	-->
	<xsl:template match="dmn:value">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Element</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:valueExpression">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Expression</xsl:with-param>	<!-- Related class is a parent class -->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:valueRef">
		<xsl:call-template name="process">
			<xsl:with-param name="class">Element</xsl:with-param>	<!-- Related class is a parent class -->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="dmn:variable">
		<xsl:call-template name="process">
			<xsl:with-param name="class">InformationItem</xsl:with-param>			
		</xsl:call-template>
	</xsl:template>

	<!-- Plain properties, just map on the element itself -->
	<xsl:template match="dmn:aggregation|						 
						 dmn:allowedAnswers|
						 dmn:associationDirection|
						 dmn:description|
						 dmn:exporter|
						 dmn:exporterVersion|
						 dmn:expressionLanguage|
						 dmn:hitPolicy|
						 dmn:id|
						 dmn:importType|
						 dmn:importedElement|
						 dmn:isCollection|
						 dmn:label| 
						 dmn:locationURI|
						 dmn:name|
						 dmn:namespace|
						 dmn:outputLabel|
						 dmn:preferredOrientation|
						 dmn:question|
						 dmn:text|
						 dmn:typeLanguage|
						 dmn:typeRef|
						 dmn:uRI">
		<xsl:element name="dmno:{local-name(.)}"><xsl:value-of select="."/></xsl:element>
	</xsl:template>
	
	<!-- Attributes -->
	<xsl:template match="@*">
		<xsl:variable name="namespace">
			<xsl:call-template name="namespaceCheck">
				<xsl:with-param name="namespace"><xsl:value-of select="namespace-uri()"/></xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<!-- Name and id aren't processed here because they are processed by the print-id and print-name templates -->
			<xsl:when test="local-name()='name'"/>
			<xsl:when test="local-name()='id'"/>
			<xsl:otherwise>
				<xsl:element name="{local-name()}" namespace="{$namespace}"><xsl:value-of select="."/></xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Tools -->
	<xsl:template name="camelcase">
	  <xsl:param name="text"/>
	  <xsl:value-of select="concat(upper-case(substring($text,1,1)),substring($text,2))" />
	</xsl:template>
	
	<xsl:template name="namespaceCheck">
		<xsl:param name="namespace"/>
		<xsl:choose>
			<xsl:when test="$namespace=''">
				<xsl:value-of select="'http://www.omg.org/spec/DMN/20151101/dmn#'"/>
			</xsl:when>
			<xsl:when test="substring( $namespace, string-length( $namespace ), 1 )='/' or substring( $namespace, string-length( $namespace ), 1 )='#'">		
				<xsl:value-of select="$namespace"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($namespace,'#')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Unmatched templates -->
	<xsl:template match="*">
		<xsl:message terminate="yes">ERROR: Unmatched element: <xsl:value-of select="name()"/></xsl:message>
	</xsl:template>

</xsl:stylesheet>
