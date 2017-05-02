<!--

    NAME     DMNTranslator.xsl
    VERSION  1.17.0-SNAPSHOT
    DATE     2017-05-02

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
	Translates XML/DMN to a conforming RDF representation
	
-->
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:dmn="http://www.omg.org/spec/DMN/20151101/dmn.xsd"
	xmlns:dmno="http://www.omg.org/spec/DMN/20151101/dmn#"
>

	<!-- Global variables -->
	<xsl:variable name="feel-prefix">http://www.omg.org/spec/FEEL/20140401/</xsl:variable>
	
	<!-- Main entry -->
	<xsl:template match="/root">
		<rdf:RDF>
			<xsl:apply-templates select="dmn:definitions"/>
		</rdf:RDF>
	</xsl:template>
	
	<xsl:template match="dmn:definitions">
		<dmno:Definitions rdf:about="{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates/>
		</dmno:Definitions>
	</xsl:template>
	
	<!--
		Unfortunately, we cannot be certain all elements have an id. In case it doesn't, we create an id ourselves, based on the predicate
		and the position in which the item appears in the source file.
	-->	
	<xsl:template match="dmn:allowedValues">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('allowedValues_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:allowedValues>
			<dmno:UnaryTests rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:UnaryTests>
		</dmno:allowedValues>
	</xsl:template>
	
	<xsl:template match="dmn:authorityRequirement">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('authorityRequirement_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:authorityRequirement>
			<dmno:AuthorityRequirement rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:AuthorityRequirement>
		</dmno:authorityRequirement>
	</xsl:template>
	
	<xsl:template match="dmn:binding">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('binding_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:binding>
			<dmno:Binding rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:Binding>
		</dmno:binding>
	</xsl:template>
	
	<xsl:template match="dmn:businessKnowledgeModel">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('businessKnowledgeModel_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:businessKnowledgeModel>
			<dmno:BusinessKnowledgeModel rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<xsl:apply-templates/>
			</dmno:BusinessKnowledgeModel>
		</dmno:businessKnowledgeModel>
	</xsl:template>
	
	<xsl:template match="dmn:context">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('context_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:context>
			<dmno:Context rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:Context>
		</dmno:context>
	</xsl:template>
	
	<xsl:template match="dmn:contextEntry">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('contextEntry_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:contextEntry>
			<dmno:ContextEntry rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:ContextEntry>
		</dmno:contextEntry>
	</xsl:template>
	
	<xsl:template match="dmn:decision">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('decision_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:decision>
			<dmno:Decision rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<xsl:apply-templates/>
			</dmno:Decision>
		</dmno:decision>
	</xsl:template>
	
	<xsl:template match="dmn:defaultOutputEntry">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('defaultOutputEntry_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:defaultOutputEntry>
			<dmno:LiteralExpression rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:LiteralExpression>
		</dmno:defaultOutputEntry>
	</xsl:template>
	
	<xsl:template match="dmn:encapsulatedLogic">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('encapsulatedLogic_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:encapsulatedLogic>
			<dmno:FunctionDefinition rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:FunctionDefinition>
		</dmno:encapsulatedLogic>
	</xsl:template>
	
	<xsl:template match="dmn:formalParameter">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('formalParameter_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:formalParameter>
			<dmno:InformationItem rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<dmno:typeRef rdf:resource="{$feel-prefix}{substring-after(@typeRef,':')}"/>
			</dmno:InformationItem>
		</dmno:formalParameter>
	</xsl:template>
	
	<xsl:template match="dmn:informationItem">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('informationItem_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:informationItem>
			<dmno:InformationItem rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<xsl:apply-templates/>
			</dmno:InformationItem>
		</dmno:informationItem>
	</xsl:template>
	
	<xsl:template match="dmn:inputData">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('inputData_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:inputData>
			<dmno:InputData rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<xsl:apply-templates/>
			</dmno:InputData>
		</dmno:inputData>
	</xsl:template>
	
	<xsl:template match="dmn:inputExpression">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('inputExpression_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:inputExpression>
			<dmno:LiteralExpression rdf:about="{$id}">
				<dmno:typeRef rdf:resource="{$feel-prefix}{substring-after(@typeRef,':')}"/>
				<xsl:apply-templates/>
			</dmno:LiteralExpression>
		</dmno:inputExpression>
	</xsl:template>
	
	<xsl:template match="dmn:informationRequirement">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('informationRequirement_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:informationRequirement>
			<dmno:InformationRequirement rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:InformationRequirement>
		</dmno:informationRequirement>
	</xsl:template>
	
	<xsl:template match="dmn:invocation">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('invocation_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:invocation>
			<dmno:Invocation rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:Invocation>
		</dmno:invocation>
	</xsl:template>
	
	<xsl:template match="dmn:itemComponent">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('itemComponent_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:itemComponent>
			<dmno:ItemDefinition rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<dmno:typeRef rdf:resource="{$feel-prefix}{substring-after(dmn:typeRef,':')}"/>
				<xsl:apply-templates/>
			</dmno:ItemDefinition>
		</dmno:itemComponent>
	</xsl:template>
	
	<xsl:template match="dmn:itemDefinition">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('itemDefinition_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:itemDefinition>
			<dmno:ItemDefinition rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<xsl:apply-templates/>
			</dmno:ItemDefinition>
		</dmno:itemDefinition>
	</xsl:template>
	
	<xsl:template match="dmn:knowledgeRequirement">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('knowledgeRequirement_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:knowledgeRequirement>
			<dmno:KnowledgeRequirement rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:KnowledgeRequirement>
		</dmno:knowledgeRequirement>
	</xsl:template>
	
	<xsl:template match="dmn:knowledgeSource">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('knowledgeSource_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:knowledgeSource>
			<dmno:KnowledgeSource rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<xsl:if test="exists(@locationURI)"><dmno:locationURI rdf:resource="{@locationURI}"/></xsl:if>
				<xsl:apply-templates/>
			</dmno:KnowledgeSource>
		</dmno:knowledgeSource>
	</xsl:template>
	
	<xsl:template match="dmn:literalExpression">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('literalExpression_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:literalExpression>
			<dmno:LiteralExpression rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:LiteralExpression>
		</dmno:literalExpression>
	</xsl:template>
	
	<xsl:template match="dmn:output">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('output_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:output>
			<dmno:OutputClause rdf:about="{$id}">
				<xsl:apply-templates/>
			</dmno:OutputClause>
		</dmno:output>
	</xsl:template>			
	
	<xsl:template match="dmn:parameter">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('parameter_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:parameter>
			<dmno:InformationItem rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<xsl:apply-templates/>
			</dmno:InformationItem>
		</dmno:parameter>
	</xsl:template>
	
	<xsl:template match="dmn:variable">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('variable_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:variable>
			<dmno:InformationItem rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<dmno:typeRef rdf:resource="{$feel-prefix}{substring-after(@typeRef,':')}"/>
				<xsl:apply-templates/>
			</dmno:InformationItem>
		</dmno:variable>
	</xsl:template>

	<!-- Properties -->
	<xsl:template match="dmn:description">
		<dmno:description><xsl:value-of select="."/></dmno:description>
	</xsl:template>
	
	<xsl:template match="dmn:namespace">
		<dmno:namespace><xsl:value-of select="."/></dmno:namespace>
	</xsl:template>
	
	<xsl:template match="dmn:requiredAuthority">
		<dmno:requiredAuthority rdf:resource="{substring(@href,2)}"/>
	</xsl:template>
	
	<xsl:template match="dmn:requiredDecision">
		<dmno:requiredDecision rdf:resource="{substring(@href,2)}"/>
	</xsl:template>
	
	<xsl:template match="dmn:requiredInput">
		<dmno:requiredInput rdf:resource="{substring(@href,2)}"/>
	</xsl:template>
	
	<xsl:template match="dmn:requiredKnowledge">
		<dmno:requiredKnowledge rdf:resource="{substring(@href,2)}"/>
	</xsl:template>
	
	<xsl:template match="dmn:text">
		<dmno:text><xsl:value-of select="."/></dmno:text>
	</xsl:template>

	<xsl:template match="dmn:type">
		<dmno:type><xsl:value-of select="."/></dmno:type>
	</xsl:template>
	
	<!--
		The DecisionTable-template is quite complex.
		This is necessary because the rows (inputs and output) and columns (inputEntries and outputEntry)
		need to be counted in order to give them a proper id which can be used for matching them later.
	-->
	<xsl:template match="dmn:decisionTable">
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat('decisionTable_',$number)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>	
		<dmno:decisionTable>
			<dmno:DecisionTable rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@outputLabel"/></rdfs:label>
				<dmno:hitPolicy><xsl:value-of select="@hitPolicy"/></dmno:hitPolicy>
				<xsl:if test="exists(@preferredOrientation)">
					<dmno:preferredOrientation><xsl:value-of select="@preferredOrientation"/></dmno:preferredOrientation>
				</xsl:if>
				<xsl:for-each select="dmn:input">
					<xsl:variable name="inputNumber"><xsl:number/></xsl:variable>
					<dmno:input>
						<dmno:InputClause rdf:about="{$id}_input_{$inputNumber}">
							<rdfs:label><xsl:value-of select="@label"/></rdfs:label>
							<xsl:apply-templates/>
						</dmno:InputClause>
					</dmno:input>
				</xsl:for-each>
				<xsl:apply-templates select="dmn:output"/>
				<xsl:for-each select="dmn:rule">
					<xsl:variable name="ruleNumber"><xsl:number/></xsl:variable>
					<dmno:rule>
						<dmno:DecisionRule rdf:about="{$id}_rule_{$ruleNumber}">
							<xsl:for-each select="dmn:inputEntry">
								<xsl:variable name="inputEntryNumber"><xsl:number/></xsl:variable>
								<dmno:inputEntry>
									<dmno:UnaryTests rdf:about="{$id}_rule_{$ruleNumber}_iE_{$inputEntryNumber}">
										<dmno:relatedInput rdf:resource="{$id}_input_{$inputEntryNumber}"/> <!-- Not part of the DMN specification -->
										<xsl:apply-templates/>
									</dmno:UnaryTests>
								</dmno:inputEntry>
							</xsl:for-each>
							<xsl:apply-templates select="dmn:outputEntry">
								<xsl:with-param name="dtid"><xsl:value-of select="$id"/></xsl:with-param>
								<xsl:with-param name="ruleNumber"><xsl:value-of select="$ruleNumber"/></xsl:with-param>
							</xsl:apply-templates>
						</dmno:DecisionRule>
					</dmno:rule>
				</xsl:for-each>
			</dmno:DecisionTable>
		</dmno:decisionTable>
	</xsl:template>
	
	<xsl:template match="dmn:outputEntry">
		<xsl:param name="dtid"/>
		<xsl:param name="ruleNumber"/>
		<dmno:outputEntry>
			<dmno:LiteralExpression rdf:about="{$dtid}_rule_{$ruleNumber}_oE">
				<dmno:relatedOutput rdf:resource="{$dtid}_output"/> <!-- Not part of the DMN specification -->
				<xsl:apply-templates/>
			</dmno:LiteralExpression>
		</dmno:outputEntry>
	</xsl:template>

</xsl:stylesheet>