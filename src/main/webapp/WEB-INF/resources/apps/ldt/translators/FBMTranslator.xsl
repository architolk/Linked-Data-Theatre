<!--

    NAME     FBMTranslator.xsl
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
	Translates XML export from iKnow to SM and FBM vocabulary (proprietry)

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:sm="http://cognitatie.com/def/sm#"
	xmlns:fbm="http://cognitatie.com/def/fbm#"
>

	<xsl:key name="item" match="*" use="@id"/>

	<xsl:variable name="smprefix">http://cognitatie.com/def/sm#</xsl:variable>
	<xsl:variable name="dataprefix">urn:uuid:</xsl:variable>

	<!--
	Custom properties (alleen SM)
	-->

	<xsl:template match="property[@name='Soort rechtsobject']" mode="customproperty">
		<sm:soortRechtsobject rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Soort rechtsfeit']" mode="customproperty">
		<sm:soortRechtsfeit rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Termijn']" mode="customproperty">
		<sm:termijn rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Rechtssubject (uitvoerder, veroorzaker)']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:uitvoerendRechtsubject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:uitvoerendRechtsubjectID><xsl:value-of select="@reference"/></sm:uitvoerendRechtsubjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Rechtkant houder (Rechtssubject)']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:rechthebbendeRechtssubject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:rechthebbendeRechtssubjectID><xsl:value-of select="@reference"/></sm:rechthebbendeRechtssubjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Plichtkant houder (Rechtssubject)']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:plichtdragendeRechtssubject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:plichtdragendeRechtssubjectID><xsl:value-of select="@reference"/></sm:plichtdragendeRechtssubjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Voorwerp (Rechtsobject)']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:rechtsobject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:rechtsobjectID><xsl:value-of select="@reference"/></sm:rechtsobjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Is specialisatie van rechtssubject']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:specialisatieVanRechtssubject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:specialisatieVanRechtssubjectID><xsl:value-of select="@reference"/></sm:specialisatieVanRechtssubjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Bestaat uit ro (samenstelling)']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:bestaatUitRechtsobject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:bestaatUitRechtsobjectID><xsl:value-of select="@reference"/></sm:bestaatUitRechtsobjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Is eigenschap van (Rechtssubject)']" mode="customproperty">
		<!--
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:eigenschapVanRechtssubject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:eigenschapVanRechtssubjectID><xsl:value-of select="@reference"/></sm:eigenschapVanRechtssubjectID></xsl:otherwise>
		</xsl:choose>
		-->
		<sm:eigenschapVanRechtssubject><xsl:value-of select="@value"/></sm:eigenschapVanRechtssubject>
	</xsl:template>

	<xsl:template match="property[@name='Is eigenschap van (Rechtsobject)']" mode="customproperty">
		<!--
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:eigenschapVanRechtsobject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:eigenschapVanRechtsobjectID><xsl:value-of select="@reference"/></sm:eigenschapVanRechtsobjectID></xsl:otherwise>
		</xsl:choose>
		-->
		<sm:eigenschapVanRechtsobject><xsl:value-of select="@value"/></sm:eigenschapVanRechtsobject>
	</xsl:template>

	<xsl:template match="property[@name='Afgeleide variabele']" mode="customproperty">
		<!-- Ik had hier eerder een referentie verwacht -->
		<sm:afgeleideVariabele><xsl:value-of select="@value"/></sm:afgeleideVariabele>
	</xsl:template>

	<xsl:template match="property[@name='Afgeleid feittype']" mode="customproperty">
		<!-- Ik had hier eerder een referentie verwacht -->
		<sm:afgeleidFeittype><xsl:value-of select="@value"/></sm:afgeleidFeittype>
	</xsl:template>

	<xsl:template match="property[@name='Domein (bedrag, datum, etc.)']" mode="customproperty">
		<sm:domeinsoort rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Domein']" mode="customproperty">
		<sm:domein rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Voorbeelden']" mode="customproperty">
		<sm:voorbeelden><xsl:value-of select="@value"/></sm:voorbeelden>
	</xsl:template>

	<xsl:template match="property[@name='Soort rechtsbetrekking']" mode="customproperty">
		<sm:soortRechtsbetrekking rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Soort aanspraak - verplichting']" mode="customproperty">
		<sm:soortVerplichting rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Soort tijdsaanduiding ']" mode="customproperty">
		<sm:soortTijdsaanduiding rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Samengesteld of enkelvoudig ro']" mode="customproperty">
		<sm:soortRechtsobject rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Samengesteld of enkelvoudig vrw']" mode="customproperty">
		<sm:soortVoorwaarde rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Soort persoon ']" mode="customproperty">
		<sm:soortPersoon rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Interpretatie']" mode="customproperty">
		<sm:interpretatie><xsl:value-of select="@value"/></sm:interpretatie>
	</xsl:template>

	<xsl:template match="property[@name='Primaire naam is vanuit gezichtspunt van']" mode="customproperty">
		<sm:soortPersoon rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Inhoudelijke opmerking']" mode="customproperty">
		<sm:inhoudelijkeOpmerking><xsl:value-of select="@value"/></sm:inhoudelijkeOpmerking>
	</xsl:template>

	<xsl:template match="property[@name='Soort operator']" mode="customproperty">
		<sm:soortOperator rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Annotatie geldig van']" mode="customproperty">
		<sm:annotatieGeldigVan><xsl:value-of select="@value"/></sm:annotatieGeldigVan>
	</xsl:template>

	<xsl:template match="property" mode="customproperty">
		<sm:property>
			<xsl:element name="sm:{@type}Property">
				<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
				<rdf:value><xsl:value-of select="@value"/><xsl:value-of select="@reference"/></rdf:value>
			</xsl:element>
		</sm:property>
	</xsl:template>

	<!--
	SM attributes
	-->

	<xsl:template match="@url" mode="sm-attribute">
		<!-- Don't process url, already taken care of -->
	</xsl:template>

	<xsl:template match="@type" mode="sm-attribute">
		<!-- Blijkbaar wordt 'Nodocumenttypeselected' opgevoerd als er geen documenttype is geselecteerd -->
		<xsl:if test=".!='Nodocumenttypeselected'">
			<sm:type rdf:resource="{$smprefix}{replace(.,' ','')}"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="@concept" mode="sm-attribute">
		<xsl:variable name="ref"><xsl:value-of select="key('item',.)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:concept rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:conceptID><xsl:value-of select="."/></sm:conceptID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@document" mode="sm-attribute">
		<xsl:variable name="ref"><xsl:value-of select="key('item',.)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:document rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:documentID><xsl:value-of select="."/></sm:documentID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@*" mode="sm-attribute">
		<xsl:element name="sm:{name()}"><xsl:value-of select="."/></xsl:element>
	</xsl:template>

	<!--
	FBM attributes
	-->

	<xsl:template match="@is_objectified_from_fact_type" mode="fbm-attribute">
		<xsl:variable name="ref"><xsl:value-of select="key('item',.)/@id"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><fbm:isObjectifiedFromFacttype rdf:resource="{$dataprefix}{$ref}"/></xsl:when>
			<xsl:otherwise><fbm:isObjectifiedFromFacttypeID><xsl:value-of select="."/></fbm:isObjectifiedFromFacttypeID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@is_played_by_objecttype" mode="fbm-attribute">
		<xsl:variable name="ref"><xsl:value-of select="key('item',.)/@id"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><fbm:isPlayedByObjecttype rdf:resource="{$dataprefix}{$ref}"/></xsl:when>
			<xsl:otherwise><fbm:isPlayedByObjecttypeID><xsl:value-of select="."/></fbm:isPlayedByObjecttypeID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@*" mode="fbm-attribute">
		<xsl:element name="fbm:{name()}"><xsl:value-of select="."/></xsl:element>
	</xsl:template>

	<xsl:template match="communicationpattern" mode="fbm-attribute">
		<fbm:communicationPattern rdf:resource="{$dataprefix}{../../@id}-{@sequencenumber}"/>
	</xsl:template>

	<xsl:template match="role" mode="fbm-attribute">
		<fbm:role rdf:resource="{$dataprefix}{@id}"/>
	</xsl:template>

	<xsl:template match="variable" mode="fbm-attribute">
		<fbm:variable rdf:resource="{$dataprefix}{@id}"/>
	</xsl:template>

	<!--
	SM classes
	-->

	<xsl:template match="document" mode="parse">
		<sm:Document rdf:about="{@url}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="sm-attribute"/>
		</sm:Document>
	</xsl:template>

	<xsl:template match="concept" mode="parse">
		<sm:Concept rdf:about="{@url}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="sm-attribute"/>
			<xsl:apply-templates select="customproperties/property" mode="customproperty"/>
		</sm:Concept>
	</xsl:template>

	<xsl:template match="textannotation" mode="parse">
		<sm:TextAnnotation rdf:about="{@url}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="sm-attribute"/>
			<xsl:apply-templates select="customproperties/property" mode="customproperty"/>
		</sm:TextAnnotation>
	</xsl:template>

	<!--
	FBM classes
	-->

	<xsl:template match="entitytype" mode="parse">
		<fbm:Entitytype rdf:about="{$dataprefix}{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
		</fbm:Entitytype>
	</xsl:template>

	<xsl:template match="valuetype" mode="parse">
		<fbm:Valuetype rdf:about="{$dataprefix}{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
		</fbm:Valuetype>
	</xsl:template>

	<xsl:template match="facttype" mode="parse">
		<fbm:Facttype rdf:about="{$dataprefix}{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
			<xsl:apply-templates select="communicationpatterns/communicationpattern" mode="fbm-attribute"/>
			<xsl:apply-templates select="roles/role" mode="fbm-attribute"/>
		</fbm:Facttype>
		<xsl:apply-templates select="communicationpatterns/communicationpattern" mode="parse"/>
		<xsl:apply-templates select="roles/role" mode="parse"/>
	</xsl:template>

	<xsl:template match="communicationpattern" mode="parse">
		<fbm:CommunicationPattern rdf:about="{$dataprefix}{../../@id}-{@sequencenumber}">
			<rdfs:label><xsl:value-of select="text"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
		</fbm:CommunicationPattern>
	</xsl:template>

	<xsl:template match="role" mode="parse">
		<fbm:Role rdf:about="{$dataprefix}{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
			<xsl:apply-templates select="variables/variable" mode="fbm-attribute"/>
		</fbm:Role>
		<xsl:apply-templates select="variables/variable" mode="parse"/>
	</xsl:template>

	<xsl:template match="variable" mode="parse">
		<fbm:Variable rdf:about="{$dataprefix}{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
		</fbm:Variable>
	</xsl:template>

	<!--
	Models and structure
	-->

	<xsl:template match="knowledgedomain" mode="parse">
		<xsl:apply-templates select="xsemanticmodel|formallinguisticmodel" mode="parse"/>
	</xsl:template>

	<xsl:template match="semanticmodel" mode="parse">
		<xsl:apply-templates select="documents/document" mode="parse"/>
		<xsl:apply-templates select="concepts/concept" mode="parse"/>
		<xsl:apply-templates select="textannotations/textannotation" mode="parse"/>
	</xsl:template>

	<xsl:template match="formallinguisticmodel" mode="parse">
		<xsl:apply-templates select="factbasedmodel" mode="parse"/>
	</xsl:template>

	<xsl:template match="factbasedmodel" mode="parse">
		<xsl:apply-templates select="entitytypes/entitytype" mode="parse"/>
		<xsl:apply-templates select="valuetypes/valuetype" mode="parse"/>
		<xsl:apply-templates select="facttypes/facttype" mode="parse"/>
	</xsl:template>

	<xsl:template match="/">
		<rdf:RDF>
			<xsl:apply-templates select="root/knowledgedomain" mode="parse"/>
		</rdf:RDF>
	</xsl:template>

</xsl:stylesheet>
