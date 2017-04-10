<!--

    NAME     DMNTranslator.xsl
    VERSION  1.16.0
    DATE     2017-02-08

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
	
	<!-- Classes -->
	<xsl:template match="dmn:businessKnowledgeModel">
		<dmno:BusinessKnowledgeModel rdf:about="{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="dmn:informationRequirement|dmn:knowledgeRequirement|dmn:authorityRequirement"/>
			<xsl:apply-templates select="dmn:description"/>
			<xsl:apply-templates select="dmn:variable"/>
			<xsl:apply-templates select="dmn:encapsulatedLogic"/>
		</dmno:BusinessKnowledgeModel>
	</xsl:template>
	
	<xsl:template match="dmn:decision">
		<dmno:Decision rdf:about="{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="dmn:informationRequirement|dmn:knowledgeRequirement|dmn:authorityRequirement"/>
			<xsl:apply-templates select="dmn:description"/>
			<xsl:apply-templates select="dmn:variable"/>
			<xsl:apply-templates select="dmn:decisionTable"/>
			<xsl:apply-templates select="dmn:invocation">
				<xsl:with-param name="parentid"><xsl:value-of select="@id"/></xsl:with-param>
			</xsl:apply-templates>
		</dmno:Decision>
	</xsl:template>
	
	<xsl:template match="dmn:definitions">
		<xsl:apply-templates select="dmn:decision|dmn:inputData|dmn:itemDefinition|dmn:knowledgeSource|dmn:businessKnowledgeModel|dmn:organizationUnit"/>
	</xsl:template>
	
	<xsl:template match="dmn:inputData">
		<dmno:InputData rdf:about="{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="dmn:informationRequirement|dmn:knowledgeRequirement|dmn:authorityRequirement"/>
			<xsl:apply-templates select="dmn:description"/>
			<xsl:apply-templates select="dmn:variable"/>
		</dmno:InputData>
	</xsl:template>
	
	<xsl:template match="dmn:itemDefinition">
		<dmno:ItemDefinition rdf:about="{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="dmn:allowedValues"/>
			<xsl:apply-templates select="dmn:itemComponent"/>
		</dmno:ItemDefinition>
	</xsl:template>

	<xsl:template match="dmn:knowledgeSource">
		<dmno:KnowledgeSource rdf:about="{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:if test="exists(@locationURI)"><dmno:locationURI rdf:resource="{@locationURI}"/></xsl:if>
			<xsl:apply-templates select="dmn:description"/>
			<xsl:apply-templates select="dmn:type"/>
			<xsl:apply-templates select="dmn:owner"/>
		</dmno:KnowledgeSource>
	</xsl:template>
	
	<!-- This class is not part of the DMN specification. It is needed, however, to properly model objects of the property "owner". -->
	<xsl:template match="dmn:organizationUnit">
		<dmno:OrganizationUnit rdf:about="{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="dmn:description"/>
		</dmno:OrganizationUnit>
	</xsl:template>
	
	<!-- Property/class hybrids -->
	
	<!--
		Unfortunately, we cannot be certain all elements have an id. In case it doesn't, we create an id ourselves, usually by either postfixing the id of its parent
		or by stripping its own name of whitespaces and postfixing the resulting string.
	-->	
	<xsl:template match="dmn:allowedValues">
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat(../@id,'_aV')"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:allowedValues>
			<dmno:UnaryTests rdf:about="{$id}">
				<xsl:apply-templates select="dmn:text"/>
			</dmno:UnaryTests>
		</dmno:allowedValues>
	</xsl:template>
	
	<xsl:template match="dmn:context">
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat(../../@id,'_eL_c')"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:context>
			<dmno:Context rdf:about="{$id}">
				<xsl:for-each select="dmn:contextEntry">
					<xsl:variable name="contextEntryNumber"><xsl:number/></xsl:variable>
					<dmno:contextEntry>
						<dmno:ContextEntry rdf:about="{$id}_cE_{$contextEntryNumber}">
							<xsl:apply-templates select="dmn:variable"/>
							<xsl:apply-templates select="dmn:literalExpression">
								<xsl:with-param name="parentid"><xsl:value-of select="concat($id,'_cE_',$contextEntryNumber)"/></xsl:with-param>
							</xsl:apply-templates>
							<xsl:apply-templates select="dmn:invocation">
								<xsl:with-param name="parentid"><xsl:value-of select="concat($id,'_cE_',$contextEntryNumber)"/></xsl:with-param>
							</xsl:apply-templates>
						</dmno:ContextEntry>
					</dmno:contextEntry>
				</xsl:for-each>
			</dmno:Context>
		</dmno:context>
	</xsl:template>
	
	<xsl:template match="dmn:decisionTable">
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat(translate(@outputLabel, ' ',''),'_dT')"/></xsl:otherwise>
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
							<xsl:apply-templates select="dmn:inputExpression"/>
						</dmno:InputClause>
					</dmno:input>
				</xsl:for-each>
				<dmno:output>
					<dmno:OutputClause rdf:about="{$id}_output">
						<xsl:apply-templates select="dmn:defaultOutputEntry"/>
					</dmno:OutputClause>
				</dmno:output>
				<xsl:for-each select="dmn:rule">
					<xsl:variable name="ruleNumber"><xsl:number/></xsl:variable>
					<dmno:rule>
						<dmno:DecisionRule rdf:about="{$id}_rule_{$ruleNumber}">
							<xsl:for-each select="dmn:inputEntry">
								<xsl:variable name="inputEntryNumber"><xsl:number/></xsl:variable>
								<dmno:inputEntry>
									<dmno:UnaryTests rdf:about="{$id}_rule_{$ruleNumber}_iE_{$inputEntryNumber}">
										<dmno:relatedInput rdf:resource="{$id}_input_{$inputEntryNumber}"/> <!-- Not part of the DMN specification -->
										<xsl:apply-templates select="dmn:text"/>
									</dmno:UnaryTests>
								</dmno:inputEntry>
							</xsl:for-each>
							<xsl:apply-templates select="dmn:outputEntry">
								<xsl:with-param name="dtid"><xsl:value-of select="$id"/></xsl:with-param>
								<xsl:with-param name="ruleNumber"><xsl:value-of select="$ruleNumber"/></xsl:with-param>
							</xsl:apply-templates>
							<xsl:apply-templates select="dmn:description"/>
						</dmno:DecisionRule>
					</dmno:rule>
				</xsl:for-each>
			</dmno:DecisionTable>
		</dmno:decisionTable>
	</xsl:template>
	
	<xsl:template match="dmn:defaultOutputEntry">
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat(../@id,'_dOE')"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:defaultOutputEntry>
			<dmno:LiteralExpression rdf:about="{$id}">
				<xsl:apply-templates select="dmn:text"/>
			</dmno:LiteralExpression>
		</dmno:defaultOutputEntry>
	</xsl:template>
	
	<xsl:template match="dmn:encapsulatedLogic">
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat(../@id,'_eL')"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:encapsulatedLogic>
			<dmno:FunctionDefinition rdf:about="{$id}">
				<xsl:apply-templates select="dmn:formalParameter"/>
				<xsl:apply-templates select="dmn:decisionTable"/>
				<xsl:apply-templates select="dmn:context"/>
			</dmno:FunctionDefinition>
		</dmno:encapsulatedLogic>
	</xsl:template>
	
	<xsl:template match="dmn:formalParameter">
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat(translate(@name, ' ',''),'_fP')"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:formalParameter>
			<dmno:InformationItem rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<dmno:typeRef rdf:resource="{$feel-prefix}{substring-after(@typeRef,':')}"/>
			</dmno:InformationItem>
		</dmno:formalParameter>
	</xsl:template>
	
	<xsl:template match="dmn:inputExpression">
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat(translate(../@label, ' ',''),'_iE')"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:inputExpression>
			<dmno:LiteralExpression rdf:about="{$id}">
				<dmno:typeRef rdf:resource="{$feel-prefix}{substring-after(@typeRef,':')}"/>
				<xsl:apply-templates select="dmn:text"/>
			</dmno:LiteralExpression>
		</dmno:inputExpression>
	</xsl:template>
	
	<xsl:template match="dmn:invocation">
		<xsl:param name="parentid"/>
		<dmno:invocation>
			<dmno:Invocation rdf:about="{$parentid}_invocation">
				<xsl:apply-templates select="dmn:literalExpression">
					<xsl:with-param name="parentid"><xsl:value-of select="concat($parentid,'_invocation')"/></xsl:with-param>
				</xsl:apply-templates>
				<xsl:for-each select="dmn:binding">
					<xsl:variable name="bindingNumber"><xsl:number/></xsl:variable>
					<dmno:binding>
						<dmno:Binding rdf:about="{$parentid}_invocation_binding_{$bindingNumber}">
							<xsl:apply-templates select="dmn:parameter"/>
							<xsl:apply-templates select="dmn:literalExpression">
								<xsl:with-param name="parentid"><xsl:value-of select="concat($parentid,'_invocation_binding_',$bindingNumber)"/></xsl:with-param>
							</xsl:apply-templates>
						</dmno:Binding>
					</dmno:binding>
				</xsl:for-each>
			</dmno:Invocation>
		</dmno:invocation>
	</xsl:template>
	
	<xsl:template match="dmn:itemComponent">
		<dmno:itemComponent>
			<dmno:ItemDefinition rdf:about="{@id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<dmno:typeRef rdf:resource="{$feel-prefix}{substring-after(dmn:typeRef,':')}"/>
				<xsl:apply-templates select="dmn:allowedValues"/>
				<xsl:apply-templates select="dmn:itemComponent"/>
			</dmno:ItemDefinition>
		</dmno:itemComponent>
	</xsl:template>
	
	<xsl:template match="dmn:literalExpression">
		<xsl:param name="parentid"/>
		<dmno:literalExpression>
			<dmno:LiteralExpression rdf:about="{$parentid}_lE">
				<xsl:apply-templates select="dmn:text"/>
			</dmno:LiteralExpression>
		</dmno:literalExpression>
	</xsl:template>
	
	<xsl:template match="dmn:outputEntry">
		<xsl:param name="dtid"/>
		<xsl:param name="ruleNumber"/>
		<dmno:outputEntry>
			<dmno:LiteralExpression rdf:about="{$dtid}_rule_{$ruleNumber}_oE">
				<dmno:relatedOutput rdf:resource="{$dtid}_output"/> <!-- Not part of the DMN specification -->
				<xsl:apply-templates select="dmn:text"/>
			</dmno:LiteralExpression>
		</dmno:outputEntry>
	</xsl:template>
	
	<xsl:template match="dmn:parameter">
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat(translate(@name, ' ',''),'_p')"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:parameter>
			<dmno:InformationItem rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			</dmno:InformationItem>
		</dmno:parameter>
	</xsl:template>
	
	<xsl:template match="dmn:variable">
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="exists(@id)"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="concat(translate(@name, ' ',''),'_v')"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dmno:variable>
			<dmno:InformationItem rdf:about="{$id}">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<dmno:typeRef rdf:resource="{$feel-prefix}{substring-after(@typeRef,':')}"/>
				<xsl:apply-templates select="dmn:description"/>
			</dmno:InformationItem>
		</dmno:variable>
	</xsl:template>

	<!-- Properties -->
	<xsl:template match="dmn:description">
		<dmno:description><xsl:value-of select="."/></dmno:description>
	</xsl:template>
	
	<xsl:template match="dmn:informationRequirement|dmn:knowledgeRequirement|dmn:authorityRequirement">
		<xsl:variable name="name"><xsl:value-of select="local-name()"/></xsl:variable>
		<xsl:for-each select="*">
			<xsl:element name="dmno:{$name}">
				<xsl:attribute name="rdf:resource">urn:uuid:<xsl:value-of select="@href"/></xsl:attribute>
			</xsl:element>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="dmn:namespace">
		<dmno:namespace><xsl:value-of select="."/></dmno:namespace>
	</xsl:template>
	
	<xsl:template match="dmn:owner">
		<dmno:owner rdf:resource="urn:uuid:{@href}"/>
	</xsl:template>
	
	<xsl:template match="dmn:text">
		<dmno:text><xsl:value-of select="."/></dmno:text>
	</xsl:template>

	<xsl:template match="dmn:type">
		<dmno:type><xsl:value-of select="."/></dmno:type>
	</xsl:template>

</xsl:stylesheet>
