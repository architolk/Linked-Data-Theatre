<!--

    NAME     DecisionTableAppearance.xsl
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
	DecisionTableAppearance, add-on of rdf2html.xsl
	
	A DecisionTableAppearance shows DMN DT triples as a table
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
>

<xsl:output method="xml" indent="yes"/>

<xsl:template match="rdf:RDF" mode="LogicAppearanceElements">
	<xsl:apply-templates select="*" mode="LogicAppearanceElements" />
</xsl:template>

<xsl:template match="rdf:Description[rdf:type/@rdf:resource='http://www.omg.org/spec/DMN/20151101/dmn#DecisionTable']" mode="LogicAppearanceElements">
	<div class="panel panel-primary logic-table">
			<div class="panel-heading">
				<h3 class="panel-title">Beslistabel: <xsl:value-of select="*[local-name() = 'outputLabel']/." /></h3>
			</div>
			<div class="panel-body">
				<table class="table table-striped table-bordered">
					<thead>
						<tr>
							<xsl:for-each select="*[local-name() = 'input']">
								<xsl:variable name="resource" select="@rdf:resource" />
								<xsl:variable name="inputResource" select="../../rdf:Description[@rdf:about=$resource]/*[local-name() = 'inputExpression']/@rdf:resource" />
								<xsl:variable name="label" select="../../rdf:Description[@rdf:about=$inputResource]/*[local-name() = 'text']/." />
								
								<th>
									<xsl:attribute name="class">
										<xsl:choose>
											<xsl:when test="position() = last()">input last</xsl:when>
											<xsl:otherwise>input</xsl:otherwise>
										</xsl:choose>
									</xsl:attribute>
									<xsl:value-of select="$label" />
								</th>
							</xsl:for-each>	
							<xsl:for-each select="*[local-name() = 'output']">
								<xsl:variable name="outputResource" select="@rdf:resource" />
								<xsl:variable name="outputLabel" select="../../rdf:Description[@rdf:about=$outputResource]/*[local-name() = 'label']/." />
								<th class="output"><xsl:value-of select="$outputLabel" /></th>
							</xsl:for-each>							
						</tr>
					</thead>
					<tbody>
						<xsl:for-each select="*[local-name() = 'rule']">
							<tr>
								<xsl:variable name="ruleResource" select="@rdf:resource" />
								
								<xsl:for-each select="../*[local-name() = 'input']">
									<xsl:variable name="inputResource" select="@rdf:resource" />
									<xsl:variable name="inputEntryResources" select="../../rdf:Description[@rdf:about=$ruleResource]/*[local-name() = 'inputEntry']/@rdf:resource" />
									<xsl:variable name="inputText" select="../../rdf:Description[@rdf:about=$inputEntryResources and ./*[local-name() = 'relatedInput' and ./@rdf:resource=$inputResource]]/*[local-name() = 'text']/." />
									
									<td>
										<xsl:attribute name="class">
											<xsl:choose>
												<xsl:when test="position() = last()">input last</xsl:when>
												<xsl:otherwise>input</xsl:otherwise>
											</xsl:choose>
										</xsl:attribute>
										<xsl:value-of select="$inputText" />
									</td>									
								
								</xsl:for-each>
								
								<xsl:for-each select="../*[local-name() = 'output']">
									<xsl:variable name="outputResource" select="@rdf:resource" />
									<xsl:variable name="outputEntryResources" select="../../rdf:Description[@rdf:about=$ruleResource]/*[local-name() = 'outputEntry']/@rdf:resource" />
									<xsl:variable name="outputText" select="../../rdf:Description[@rdf:about=$outputEntryResources and ./*[local-name() = 'relatedOutput' and ./@rdf:resource=$outputResource]]/*[local-name() = 'text']/." />
									
									<td class="output"><xsl:value-of select="$outputText" /></td>									
								
								</xsl:for-each>
																
							</tr>
						</xsl:for-each>
					</tbody>
				</table>
			</div>
		</div>
</xsl:template>

</xsl:stylesheet>
