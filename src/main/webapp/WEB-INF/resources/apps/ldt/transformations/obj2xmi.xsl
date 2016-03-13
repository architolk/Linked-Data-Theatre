<!--

    NAME     obj2xmi.xsl
    VERSION  1.6.0
    DATE     2016-03-13

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
	Transforms obj XML to XMI (used in conjunction with sparql2obj). Deprecated, should be deleted
	
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sparql="http://www.w3.org/2005/sparql-results#" xmlns:error="http://apache.org/cocoon/sparql/1.0">

<xsl:key name="ontologie" match="/Objects/Object[Property[@predicate='http://www.w3.org/1999/02/22-rdf-syntax-ns#type']='http://www.w3.org/2002/07/owl#Ontology']" use="@about"/>
<xsl:key name="klasse" match="/Objects/Object[Property[@predicate='http://www.w3.org/1999/02/22-rdf-syntax-ns#type']='http://www.w3.org/2002/07/owl#Class']" use="@about"/>

<xsl:template name="shortname">
	<xsl:param name="name"/>

	<xsl:choose>
		<xsl:when test="substring-after($name,'#')=''">

			<xsl:variable name="shortname" select="substring-after($name,'/')"/>
			
			<xsl:choose>
				<xsl:when test="$shortname=''">
					<xsl:value-of select="$name"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="shortname"><xsl:with-param name="name" select="$shortname"/></xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="substring-after($name,'#')"/>
		</xsl:otherwise>
	</xsl:choose>
	
</xsl:template>

<xsl:template match="/">
<xsl:for-each select="Objects">

	<!-- Hulpjes -->
	<xsl:variable name="rdf-type">http://www.w3.org/1999/02/22-rdf-syntax-ns#type</xsl:variable>
	<xsl:variable name="owl-ontology">http://www.w3.org/2002/07/owl#Ontology</xsl:variable>
	<xsl:variable name="rdfs-isDefinedBy">http://www.w3.org/2000/01/rdf-schema#isDefinedBy</xsl:variable>
	<xsl:variable name="owl-class">http://www.w3.org/2002/07/owl#Class</xsl:variable>
	<xsl:variable name="owl-datatypeProperty">http://www.w3.org/2002/07/owl#DatatypeProperty</xsl:variable>
	<xsl:variable name="owl-objectProperty">http://www.w3.org/2002/07/owl#ObjectProperty</xsl:variable>
	<xsl:variable name="rdfs-domain">http://www.w3.org/2000/01/rdf-schema#domain</xsl:variable>
	<xsl:variable name="rdfs-range">http://www.w3.org/2000/01/rdf-schema#range</xsl:variable>
	<xsl:variable name="rdfs-subClassOf">http://www.w3.org/2000/01/rdf-schema#subClassOf</xsl:variable>
	
	<XMI xmi.version = "1.1" xmlns:UML="href://org.omg/UML/1.3" timestamp = "Fri Jul 20 9:16:21 2012">
	
	<XMI.header>
		<XMI.documentation>
			<XMI.owner></XMI.owner>
			<XMI.contact></XMI.contact>
			<XMI.exporter>Semantic window XMI exporter</XMI.exporter>
			<XMI.exporterVersion>0.1</XMI.exporterVersion>
			<XMI.notice></XMI.notice>
		</XMI.documentation>
		<XMI.metamodel xmi.name = "UML" xmi.version = "1.3"/>
	</XMI.header>
	
	<XMI.content>
		<UML:Model xmi.id="SW-Export">
			<UML:Namespace.ownedElement>
				<!-- Overige gevonden ontologieen -->
				<xsl:for-each-group select="Object" group-by="Property[@predicate=$rdfs-isDefinedBy]">
					<xsl:variable name="modeluri" select="Property[@predicate=$rdfs-isDefinedBy]"/>
					<xsl:variable name="modelname" select="$modeluri"/>
					<xsl:variable name="modelid">UMLModelA.<xsl:value-of select="position()"/></xsl:variable>
					<UML:Model xmi.id="{$modelid}" name="{@name}" visibility="public" isSpecification="false" namespace="SW-Export" isRoot="false" isLeaf="false" isAbstract="false">
						<UML:Namespace.ownedElement>
							<!-- Default 1 Class voor de ontology -->
							<UML:Class xmi.id="{@about}" name="{$modelname}" visibility="public" isSpecification="false" namespace="{$modelid}" isRoot="false" isLeaf="false" isAbstract="false" isActive="false"/>
							
							<!-- En dan nu alle overige klassen in deze ontology -->
							<xsl:for-each select="current-group()[Property[@predicate=$rdfs-isDefinedBy]=$modeluri and Property[@predicate=$rdf-type]=$owl-class]">
								<xsl:variable name="classuri" select="@about"/>
								<xsl:variable name="classname">
									<xsl:value-of select="@label"/>
									<xsl:if test="@label=''"><xsl:value-of select="@name"/></xsl:if>
								</xsl:variable>
								<UML:Class xmi.id="{@about}" name="{$classname}" visibility="public" isSpecification="false" namespace="{$modelid}" isRoot="false" isLeaf="false" isAbstract="false" isActive="false">
									<UML:Classifier.feature>
										<!-- Attributes (=DatetypeProperties)-->
										<xsl:for-each select="../Object[Property[@predicate=$rdfs-domain]=$classuri and Property[@predicate=$rdf-type]=$owl-datatypeProperty]">
											<xsl:variable name="attributename">
												<xsl:value-of select="@label"/>
												<xsl:if test="@label=''"><xsl:value-of select="@name"/></xsl:if>
											</xsl:variable>
											<UML:Attribute xmi.id="{@about}" name="{$attributename}" visibility="public" isSpecification="false" ownerScope="instance" changeability="changeable" targetScope="instance" type="X.135" owner="{$classuri}"/>
										</xsl:for-each>
									</UML:Classifier.feature>
								</UML:Class>
								<!-- subClasses -->
								<xsl:for-each select="Property[@predicate=$rdfs-subClassOf]">
									<UML:Generalization xmi.id="{../@about}.{position()}" name="subClassOf" visibility="public" isSpecification="false" namespace="{$modelid}" discriminator="" child="{../@about}" parent="{.}"/>
								</xsl:for-each>
							</xsl:for-each>
							
							<!-- En voor alle associaties in deze ontology -->
							<xsl:for-each select="current-group()[Property[@predicate=$rdfs-isDefinedBy]=$modeluri and Property[@predicate=$rdf-type]=$owl-objectProperty]">
								<xsl:variable name="associationname">
									<xsl:value-of select="@label"/>
									<xsl:if test="@label=''"><xsl:value-of select="@name"/></xsl:if>
								</xsl:variable>
								<UML:Association xmi.id="{@about}" name="{$associationname}" visibility="public" isSpecification="false" namespace="{$modelid}">
									<UML:Association.connection>
										<UML:AssociationEnd xmi.id="{@about}D" name="" visibility="public" isSpecification="false" isNavigable="false" ordering="unordered" aggregation="none" targetScope="instance" changeability="changeable" association="{@about}" type="{Property[@predicate=$rdfs-domain]}"/>
										<UML:AssociationEnd xmi.id="{@about}R" name="" visibility="public" isSpecification="false" isNavigable="true" ordering="unordered" aggregation="none" targetScope="instance" changeability="changeable" association="{@about}" type="{Property[@predicate=$rdfs-range]}"/>
									</UML:Association.connection>
								</UML:Association>
							</xsl:for-each>
							
						</UML:Namespace.ownedElement>
					</UML:Model>
				</xsl:for-each-group>
				<!-- Gedefinieerde ontologieen -->
				<xsl:for-each select="Object[Property[@predicate=$rdf-type]=$owl-ontology]">
					<xsl:variable name="modeluri" select="@about"/>
					<xsl:variable name="modelname">
						<xsl:value-of select="@label"/>
						<xsl:if test="@label=''"><xsl:value-of select="@name"/></xsl:if>
					</xsl:variable>
					<xsl:variable name="modelid">UMLModel.<xsl:value-of select="position()"/></xsl:variable>
					<UML:Model xmi.id="{$modelid}" name="{@name}" visibility="public" isSpecification="false" namespace="SW-Export" isRoot="false" isLeaf="false" isAbstract="false">
						<UML:Namespace.ownedElement>
							<!-- Default 1 Class voor de ontology -->
							<UML:Class xmi.id="{@about}" name="{$modelname}" visibility="public" isSpecification="false" namespace="{$modelid}" isRoot="false" isLeaf="false" isAbstract="false" isActive="false"/>
							
							<!-- En dan nu alle overige klassen in deze ontology -->
							<xsl:for-each select="../Object[Property[@predicate=$rdfs-isDefinedBy]=$modeluri and Property[@predicate=$rdf-type]=$owl-class]">
								<xsl:variable name="classuri" select="@about"/>
								<xsl:variable name="classname">
									<xsl:value-of select="@label"/>
									<xsl:if test="@label=''"><xsl:value-of select="@name"/></xsl:if>
								</xsl:variable>
								<UML:Class xmi.id="{@about}" name="{$classname}" visibility="public" isSpecification="false" namespace="{$modelid}" isRoot="false" isLeaf="false" isAbstract="false" isActive="false">
									<UML:Classifier.feature>
										<!-- Attributes (=DatetypeProperties)-->
										<xsl:for-each select="../Object[Property[@predicate=$rdfs-domain]=$classuri and Property[@predicate=$rdf-type]=$owl-datatypeProperty]">
											<xsl:variable name="attributename">
												<xsl:value-of select="@label"/>
												<xsl:if test="@label=''"><xsl:value-of select="@name"/></xsl:if>
											</xsl:variable>
											<UML:Attribute xmi.id="{@about}" name="{$attributename}" visibility="public" isSpecification="false" ownerScope="instance" changeability="changeable" targetScope="instance" type="X.135" owner="{$classuri}"/>
										</xsl:for-each>
									</UML:Classifier.feature>
								</UML:Class>
								<!-- subClasses -->
								<xsl:for-each select="Property[@predicate=$rdfs-subClassOf]">
									<UML:Generalization xmi.id="{../@about}.{position()}" name="subClassOf" visibility="public" isSpecification="false" namespace="{$modelid}" discriminator="" child="{../@about}" parent="{.}"/>
								</xsl:for-each>
							</xsl:for-each>
							
							<!-- En voor alle associaties in deze ontology -->
							<xsl:for-each select="../Object[Property[@predicate=$rdfs-isDefinedBy]=$modeluri and Property[@predicate=$rdf-type]=$owl-objectProperty]">
								<xsl:variable name="associationname">
									<xsl:value-of select="@label"/>
									<xsl:if test="@label=''"><xsl:value-of select="@name"/></xsl:if>
								</xsl:variable>
								<UML:Association xmi.id="{@about}" name="{$associationname}" visibility="public" isSpecification="false" namespace="{$modelid}">
									<UML:Association.connection>
										<UML:AssociationEnd xmi.id="{@about}D" name="" visibility="public" isSpecification="false" isNavigable="false" ordering="unordered" aggregation="none" targetScope="instance" changeability="changeable" association="{@about}" type="{Property[@predicate=$rdfs-domain]}"/>
										<UML:AssociationEnd xmi.id="{@about}R" name="" visibility="public" isSpecification="false" isNavigable="true" ordering="unordered" aggregation="none" targetScope="instance" changeability="changeable" association="{@about}" type="{Property[@predicate=$rdfs-range]}"/>
									</UML:Association.connection>
								</UML:Association>
							</xsl:for-each>
							
						</UML:Namespace.ownedElement>
					</UML:Model>
				</xsl:for-each>
				<UML:Model xmi.id="UMLModel.0" name="Lost-and-found" visibility="public" isSpecification="false" namespace="SW-Export" isRoot="false" isLeaf="false" isAbstract="false">
					<UML:Namespace.ownedElement>
						<!-- Klassen die niet in een ontologie zitten -->
						<xsl:for-each select="Object[Property[@predicate=$rdf-type]=$owl-class]">
							<!-- Alleen als ze niet in een ontologie zitten -->
							<xsl:if test="not(exists(key('ontologie',Property[@predicate=$rdfs-isDefinedBy])))">
								<xsl:variable name="classname">
									<xsl:value-of select="@label"/>
									<xsl:if test="@label=''"><xsl:value-of select="@name"/></xsl:if>
								</xsl:variable>
								<UML:Class xmi.id="{@about}" name="{$classname}" visibility="public" isSpecification="false" namespace="UMLModel.0" isRoot="false" isLeaf="false" isAbstract="false" isActive="false"/>
							</xsl:if>
						</xsl:for-each>
						<!-- Klassen waarna wordt verwezen, maar die nergens benoemd zijn -->
						<xsl:for-each select="Object[Property[@predicate=$rdf-type]=$owl-objectProperty]">
							<!-- Alleen als ze niet als klasse bestaan -->
							<xsl:variable name="classuri" select="Property[@predicate=$rdfs-range]"/>
							<xsl:variable name="classname"><xsl:call-template name="shortname"><xsl:with-param name="name" select="$classuri"/></xsl:call-template></xsl:variable>
							<xsl:if test="$classuri!='' and not(exists(key('klasse',$classuri)))">
								<UML:Class xmi.id="{$classuri}" name="{$classname}" visibility="public" isSpecification="false" namespace="UMLModel.0" isRoot="false" isLeaf="false" isAbstract="false" isActive="false"/>
							</xsl:if>
						</xsl:for-each>
						<xsl:for-each-group select="Object/Property[@predicate=$rdfs-subClassOf]" group-by=".">
							<!-- Alleen als ze niet als klasse bestaan -->
							<xsl:variable name="classuri" select="."/>
							<xsl:variable name="classname"><xsl:call-template name="shortname"><xsl:with-param name="name" select="$classuri"/></xsl:call-template></xsl:variable>
							<xsl:if test="$classuri!='' and not(exists(key('klasse',$classuri)))">
								<UML:Class xmi.id="{$classuri}" name="{$classname}" visibility="public" isSpecification="false" namespace="UMLModel.0" isRoot="false" isLeaf="false" isAbstract="false" isActive="false"/>
							</xsl:if>
						</xsl:for-each-group>
					</UML:Namespace.ownedElement>
				</UML:Model>
			</UML:Namespace.ownedElement>
		</UML:Model>
	</XMI.content>

	</XMI>
</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
	
