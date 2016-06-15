<!--

    NAME     TableExcelTranslator.xsl
    VERSION  1.8.0
    DATE     2016-06-15

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
	Table translator for excel files. The excel should contain:
	- Sheet 1 containing the URI-schema definitions:
		- Column A refering to the sheet name
		- Column B refering to the column name (the value of the first cell of a column of a sheet)
		- Column C refering to the class name
		- Column D refering to the URI-schema
		- Columns E and further refering to a condition. The first row of the column contains the name of the column, the other rows contain the condition values.
	- Sheet 2 containing the property definitions:
		- Column A refering to the sheet name
		- Column B refering to the column name (the value of the first cell of a column of a sheet)
		- Column C refering to the vocabulary used for the property
		- Column D refering to the name of the property
		- Column E containing the label of the property (for annotation only)
		- Column F containing the definition of the property (for annotation only)
	- Sheet 3 and further, containing the values:
		- Every row will create a <subject rdf:type class> triple if:
				- Column 1.A refers to the sheet name AND
				- Column 1.B refers to a column name on the sheet AND
				- Column 1.C refers to a class name AND
				- Column 1.D refers to a URI-schema AND
				- The conditions in Column 1.E and further hold (the value is the same as the value of the column to which the condition refers)
		- Every column will create a <subject property value> triple if:
				- Column 2.A refers to the sheet name AND
				- Column 2.B refers to the column name AND
				- Column 2.C refers to a vocabulary used for the property
				- Column 2.D refers to the name of the property
				- The URI-schema should be defined on sheet 1 like this:
					| sheet      | column   | class | uri schema                                      | vocabulary-condition |
					|____________|__________|_______|_________________________________________________|______________________|
					| Properties | property |       | http://www.w3.org/2000/01/rdf-schema#{property} | rdfs                 |
-->
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
>
	<xsl:key name="prefix" match="root/workbook/sheet[1]/row" use="column[@id='1']"/>
	<xsl:key name="properties" match="root/workbook/sheet[2]/row" use="column[@id='0']"/>

	<!-- Variable holding all column names (first row of every sheet) -->
	<xsl:variable name="column-names">
		<xsl:for-each select="root/workbook/sheet">
			<sheet name="{@name}">
				<xsl:for-each select="row[1]/column">
					<column name="{.}" id="{@id}"/>
				</xsl:for-each>
			</sheet>
		</xsl:for-each>
	</xsl:variable>
	
	<!-- Template to replace all values within {<column>} with the column value -->
	<xsl:template name="create-uri">
		<xsl:param name="sheet"/>
		<xsl:param name="columns"/>
		<xsl:param name="uri-schema"/>

		<xsl:for-each select="tokenize(replace($uri-schema,'\{[^\}]*\}','@$0@'),'@')">
			<xsl:choose>
				<xsl:when test="matches(.,'^\{[^\}]*\}$')">
					<xsl:variable name="name" select="substring(.,2,string-length(.)-2)"/>
					<xsl:value-of select="$columns[@id=$column-names/sheet[@name=$sheet]/column[@name=$name]/@id]"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="/">
		<rdf:RDF>
			<!-- Sheet name of class and property -->
			<xsl:variable name="class-sheet-name" select="root/workbook/sheet[1]/@name"/>
			<xsl:variable name="property-sheet-name" select="root/workbook/sheet[2]/@name"/>
			<!-- Column name of class and property -->
			<xsl:variable name="class-column-name" select="$column-names/sheet[1]/column[@id='2']/@name"/>
			<xsl:variable name="property-column-name" select="$column-names/sheet[2]/column[@id='3']/@name"/>
			<!-- Set property conditions -->
			<xsl:variable name="pconditions">
				<xsl:for-each select="key('prefix',$property-column-name)[column[@id='0']=$property-sheet-name]">
					<xsl:variable name="condition" select="column[@id='3']/following-sibling::column[1]"/>
					<xsl:choose>
						<xsl:when test="exists($condition)">
							<condition value="{column[@id='3']}" check="{$condition}" checkcolumn="{$column-names/sheet[@name=$property-sheet-name]/column[@name=substring-before($column-names/sheet[@name=$class-sheet-name]/column[@id=$condition/@id]/@name,'-')]/@id}"/>
						</xsl:when>
						<xsl:otherwise>
							<value value="{column[@id='3']}"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:variable>
			<!-- Only parse class-defined sheets and rows -->
			<xsl:for-each-group select="root/workbook/sheet[1]/row[position()!=1 and column[@id='2']!='']" group-by="column[@id='0']">
				<xsl:variable name="valuesheet" select="column[@id='0']"/>
				<!-- Replace create class uri from template -->
				<xsl:variable name="class-uri">
					<xsl:call-template name="create-uri">
						<xsl:with-param name="sheet" select="$class-sheet-name"/>
						<xsl:with-param name="columns" select="*"/>
						<xsl:with-param name="uri-schema" select="key('prefix',$class-column-name)[column[@id='0']=$class-sheet-name]/column[@id='3']"/>
					</xsl:call-template>
				</xsl:variable>
				<!-- Create properties -->
				<xsl:variable name="properties">
					<xsl:for-each select="key('properties',$valuesheet)">
						<xsl:variable name="pname" select="column[@id='3']"/>
						<!-- Create full uri from pname -->
						<!-- URI-schema depends on the condition -->
						<xsl:variable name="condition-value" select="column[@id=$pconditions/condition[1]/@checkcolumn]"/>
						<xsl:variable name="uri-schema">
							<xsl:choose>
								<xsl:when test="exists($pconditions/value)"><xsl:value-of select="$pconditions/value/@value[1]"/></xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$pconditions/condition[@check=$condition-value]/@value[1]"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<!-- Create puri, use qname without inverse property path ('^' prefix) -->
						<xsl:variable name="columns">
							<column id='3'><xsl:value-of select="replace($pname,'^\^','')"/></column>
						</xsl:variable>
						<xsl:variable name="puri">
							<xsl:call-template name="create-uri">
								<xsl:with-param name="sheet" select="$property-sheet-name"/>
								<xsl:with-param name="columns" select="$columns/*"/>
								<xsl:with-param name="uri-schema" select="$uri-schema"/>
							</xsl:call-template>
						</xsl:variable>
						<!-- Create property definition, use other definition for inverse properties -->
						<xsl:variable name="column" select="column[@id='1']"/>
						<xsl:choose>
							<xsl:when test="substring($pname,1,1)='^'">
								<inverseproperty column="{$column-names/sheet[@name=$valuesheet]/column[@name=$column]/@id}" uri="{$puri}"/>
							</xsl:when>
							<xsl:otherwise>
								<property column="{$column-names/sheet[@name=$valuesheet]/column[@name=$column]/@id}" uri="{$puri}"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<!-- Set conditions -->
				<xsl:variable name="conditions">
					<xsl:for-each select="/root/workbook/sheet[1]/row[column[@id='0']=$valuesheet]">
						<xsl:variable name="condition" select="column[@id='3']/following-sibling::column[1]"/>
						<xsl:variable name="cname" select="column[@id='1']"/>
						<xsl:variable name="column" select="$column-names/sheet[@name=$valuesheet]/column[@name=$cname]/@id"/>
						<xsl:choose>
							<xsl:when test="exists($condition)">
								<condition column="{$column}" class="{column[@id='2']}" value="{column[@id='3']}" check="{$condition}" checkcolumn="{$column-names/sheet[@name=$valuesheet]/column[@name=substring-before($column-names/sheet[@name=$class-sheet-name]/column[@id=$condition/@id]/@name,'-')]/@id}"/>
							</xsl:when>
							<xsl:otherwise>
								<value column="{$column}" class="{column[@id='2']}" value="{column[@id='3']}"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<!-- Parse all rows in value sheet -->
				<!-- <xsl:variable name="uri-schema" select="column[@id='3']"/> -->
				<xsl:for-each select="/root/workbook/sheet[@name=$valuesheet]/row[position()!=1]">
					<!-- URI-schema depends on the condition -->
					<xsl:variable name="condition-value" select="column[@id=$conditions/condition[@class!='']/@checkcolumn[1]]"/>
					<xsl:variable name="uri-schema">
						<xsl:choose>
							<xsl:when test="exists($conditions/value[@class!=''])"><xsl:value-of select="$conditions/value[@class!='']/@value[1]"/></xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$conditions/condition[@class!='' and @check=$condition-value]/@value[1]"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- Create URI -->
					<xsl:variable name="uri">
						<xsl:call-template name="create-uri">
							<xsl:with-param name="sheet" select="$valuesheet"/>
							<xsl:with-param name="columns" select="*"/>
							<xsl:with-param name="uri-schema" select="$uri-schema"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:variable name="columns" select="*"/>
					<xsl:if test="$uri!=''">
						<rdf:Description rdf:about="{$uri}">
							<rdf:type rdf:resource="{$class-uri}"/>
							<!-- Only proces regular properties -->
							<xsl:for-each select="$properties/property">
								<xsl:variable name="column" select="@column"/>
								<xsl:variable name="condition-value" select="$columns/column[@id=$conditions/condition[@column=$column and @class='']/@checkcolumn[1]]"/>
								<xsl:variable name="objecturi">
									<xsl:choose>
										<xsl:when test="exists($conditions/value[@column=$column and @class=''])">
											<xsl:call-template name="create-uri">
												<xsl:with-param name="sheet" select="$valuesheet"/>
												<xsl:with-param name="columns" select="$columns"/>
												<xsl:with-param name="uri-schema" select="$conditions/value[@column=$column and @class='']/@value[1]"/>
											</xsl:call-template>
										</xsl:when>
										<xsl:when test="exists($conditions/condition[@column=$column and @class='' and @check=$condition-value])">
											<xsl:call-template name="create-uri">
												<xsl:with-param name="sheet" select="$valuesheet"/>
												<xsl:with-param name="columns" select="$columns"/>
												<xsl:with-param name="uri-schema" select="$conditions/condition[@column=$column and @class='' and @check=$condition-value]/@value[1]"/>
											</xsl:call-template>
										</xsl:when>
										<xsl:otherwise />
									</xsl:choose>
								</xsl:variable>
								<xsl:if test="exists($columns[@id=$column])">
									<xsl:variable name="prefix" select="replace(@uri,'(/|#|\\)[0-9A-Za-z-._~()@]+$','$1')"/>
									<xsl:choose>
										<xsl:when test="$prefix=@uri">
											<xsl:element name="{@uri}">
												<xsl:choose>
													<xsl:when test="$objecturi!=''">
														<xsl:attribute name="rdf:resource" select="$objecturi"/>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="$columns[@id=$column]"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:element>
										</xsl:when>
										<xsl:otherwise>
											<xsl:element name="{substring-after(@uri,$prefix)}" namespace="{$prefix}">
												<xsl:choose>
													<xsl:when test="$objecturi!=''">
														<xsl:attribute name="rdf:resource" select="$objecturi"/>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="$columns[@id=$column]"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:element>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:if>
							</xsl:for-each>
						</rdf:Description>
						<!-- Proces inverse properties: subject and object are reversed -->
						<xsl:for-each select="$properties/inverseproperty">
							<xsl:variable name="column" select="@column"/>
							<xsl:if test="exists($columns[@id=$column])">
								<xsl:variable name="objecturi">
									<xsl:choose>
										<xsl:when test="exists($conditions/value[@column=$column and @class=''])">
											<xsl:call-template name="create-uri">
												<xsl:with-param name="sheet" select="$valuesheet"/>
												<xsl:with-param name="columns" select="$columns"/>
												<xsl:with-param name="uri-schema" select="$conditions/value[@column=$column and @class='']/@value[1]"/>
											</xsl:call-template>
										</xsl:when>
										<xsl:when test="exists($conditions/condition[@column=$column and @class=''])">
											<xsl:call-template name="create-uri">
												<xsl:with-param name="sheet" select="$valuesheet"/>
												<xsl:with-param name="columns" select="$columns"/>
												<xsl:with-param name="uri-schema" select="$conditions/condition[@column=$column and @class='']/@value[1]"/>
											</xsl:call-template>
										</xsl:when>
										<xsl:otherwise />
									</xsl:choose>
								</xsl:variable>
								<xsl:if test="$objecturi!=''">
									<rdf:Description rdf:about="{$objecturi}">
										<xsl:variable name="prefix" select="replace(@uri,'(/|#|\\)[0-9A-Za-z-._~()@]+$','$1')"/>
										<xsl:choose>
											<xsl:when test="$prefix=@uri">
												<xsl:element name="{@uri}">
													<xsl:attribute name="rdf:resource"><xsl:value-of select="$uri"/></xsl:attribute>
												</xsl:element>
											</xsl:when>
											<xsl:otherwise>
												<xsl:element name="{substring-after(@uri,$prefix)}" namespace="{$prefix}">
													<xsl:attribute name="rdf:resource"><xsl:value-of select="$uri"/></xsl:attribute>
												</xsl:element>
											</xsl:otherwise>
										</xsl:choose>
									</rdf:Description>
								</xsl:if>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:for-each>
			</xsl:for-each-group>
		</rdf:RDF>
	</xsl:template>
</xsl:stylesheet>
