<!--

    NAME     FBMTranslator.xsl
    VERSION  1.25.3-SNAPSHOT
    DATE     2021-11-07

    Copyright 2012-2021

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
	<xsl:key name="concept" match="concept" use="@name"/>

	<xsl:variable name="smprefix">http://cognitatie.com/def/sm#</xsl:variable>
	<xsl:variable name="dataprefix">urn:uuid:</xsl:variable>

	<!--
	Custom properties (alleen SM)
	-->

	<xsl:template match="property[@name='Soort rechtsobject']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}soortRechtsobject"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Soort rechtsobject']" mode="customproperty">
		<sm:soortRechtsobject rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Soort rechtsfeit']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}soortRechtsfeit"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Soort rechtsfeit']" mode="customproperty">
		<sm:soortRechtsfeit rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Termijn']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}termijn"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Termijn']" mode="customproperty">
		<sm:termijn rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Rechtssubject (uitvoerder, veroorzaker)']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}uitvoerendRechtsubject"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
		<rdf:Property rdf:about="{$smprefix}uitvoerendRechtsubjectID"><rdfs:label><xsl:value-of select="@name"/> ID</rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Rechtssubject (uitvoerder, veroorzaker)']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:uitvoerendRechtsubject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:uitvoerendRechtsubjectID><xsl:value-of select="@reference"/></sm:uitvoerendRechtsubjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Rechtkant houder (Rechtssubject)']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}rechthebbendeRechtssubject"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
		<rdf:Property rdf:about="{$smprefix}rechthebbendeRechtssubjectID"><rdfs:label><xsl:value-of select="@name"/> ID</rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Rechtkant houder (Rechtssubject)']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:rechthebbendeRechtssubject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:rechthebbendeRechtssubjectID><xsl:value-of select="@reference"/></sm:rechthebbendeRechtssubjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Plichtkant houder (Rechtssubject)']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}plichtdragendeRechtssubject"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
		<rdf:Property rdf:about="{$smprefix}plichtdragendeRechtssubjectID"><rdfs:label><xsl:value-of select="@name"/> ID</rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Plichtkant houder (Rechtssubject)']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:plichtdragendeRechtssubject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:plichtdragendeRechtssubjectID><xsl:value-of select="@reference"/></sm:plichtdragendeRechtssubjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Rechtkant expliciet in brontekst']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}rechtkantExplicietInBrontekst"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Rechtkant expliciet in brontekst']" mode="customproperty">
		<sm:rechtkantExplicietInBrontekst><xsl:value-of select="@value"/></sm:rechtkantExplicietInBrontekst>
	</xsl:template>

	<xsl:template match="property[@name='Plichtkant expliciet in brontekst']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}plichtkantExplicietInBrontekst"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Plichtkant expliciet in brontekst']" mode="customproperty">
		<sm:plichtkantExplicietInBrontekst><xsl:value-of select="@value"/></sm:plichtkantExplicietInBrontekst>
	</xsl:template>

	<xsl:template match="property[@name='Voorwerp (Rechtsobject)']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}rechtsobject"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
		<rdf:Property rdf:about="{$smprefix}rechtsobjectID"><rdfs:label><xsl:value-of select="@name"/> ID</rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Voorwerp (Rechtsobject)']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:rechtsobject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:rechtsobjectID><xsl:value-of select="@reference"/></sm:rechtsobjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Is specialisatie van rechtssubject']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}specialisatieVanRechtssubject"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
		<rdf:Property rdf:about="{$smprefix}specialisatieVanRechtssubjectID"><rdfs:label><xsl:value-of select="@name"/> ID</rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Is specialisatie van rechtssubject']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:specialisatieVanRechtssubject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:specialisatieVanRechtssubjectID><xsl:value-of select="@reference"/></sm:specialisatieVanRechtssubjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Bestaat uit ro (samenstelling)']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}bestaatUitRechtsobject"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
		<rdf:Property rdf:about="{$smprefix}bestaatUitRechtsobjectID"><rdfs:label><xsl:value-of select="@name"/> ID</rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Bestaat uit ro (samenstelling)']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:bestaatUitRechtsobject rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:bestaatUitRechtsobjectID><xsl:value-of select="@reference"/></sm:bestaatUitRechtsobjectID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Is eigenschap van (Rechtssubject)']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}eigenschapVanRechtssubject"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
		<rdf:Property rdf:about="{$smprefix}eigenschapVanRechtssubjectID"><rdfs:label><xsl:value-of select="@name"/> ID</rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Is eigenschap van (Rechtssubject)']" mode="customproperty">
		<!-- Rare is dat het hier niet gaat om een referentie, maar om een naam: dat zou toch niet moeten?? -->
		<xsl:variable name="refs" select="key('concept',@value)"/>
		<xsl:for-each select="$refs">
			<sm:eigenschapVanRechtssubject rdf:resource="{@url}"/>
		</xsl:for-each>
		<xsl:if test="not(exists($refs))">
			<sm:eigenschapVanRechtssubjectID><xsl:value-of select="@value"/></sm:eigenschapVanRechtssubjectID>
		</xsl:if>
	</xsl:template>

	<xsl:template match="property[@name='Is eigenschap van (Rechtsobject)']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}eigenschapVanRechtsobject"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
		<rdf:Property rdf:about="{$smprefix}eigenschapVanRechtsobjectID"><rdfs:label><xsl:value-of select="@name"/> ID</rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Is eigenschap van (Rechtsobject)']" mode="customproperty">
		<!-- Rare is dat het hier niet gaat om een referentie, maar om een naam: dat zou toch niet moeten?? -->
		<xsl:variable name="refs" select="key('concept',@value)"/>
		<xsl:for-each select="$refs">
			<sm:eigenschapVanRechtsobject rdf:resource="{@url}"/>
		</xsl:for-each>
		<xsl:if test="not(exists($refs))">
			<sm:eigenschapVanRechtsobjectID><xsl:value-of select="@value"/></sm:eigenschapVanRechtsobjectID>
		</xsl:if>
	</xsl:template>

	<xsl:template match="property[@name='Afgeleide variabele']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}afgeleideVariabele"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Afgeleide variabele']" mode="customproperty">
		<!-- Ik had hier eerder een referentie verwacht -->
		<sm:afgeleideVariabele><xsl:value-of select="@value"/></sm:afgeleideVariabele>
	</xsl:template>

	<xsl:template match="property[@name='Afgeleid feittype']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}afgeleidFeittype"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Afgeleid feittype']" mode="customproperty">
		<!-- Ik had hier eerder een referentie verwacht -->
		<sm:afgeleidFeittype><xsl:value-of select="@value"/></sm:afgeleidFeittype>
	</xsl:template>

	<xsl:template match="property[@name='Domein (bedrag, datum, etc.)']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}domeinsoort"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Domein (bedrag, datum, etc.)']" mode="customproperty">
		<sm:domeinsoort rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Domein']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}domein"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Domein']" mode="customproperty">
		<sm:domein rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Voorbeelden']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}voorbeelden"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Voorbeelden']" mode="customproperty">
		<sm:voorbeelden><xsl:value-of select="@value"/></sm:voorbeelden>
	</xsl:template>

	<xsl:template match="property[@name='Soort rechtsbetrekking']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}soortRechtsbetrekking"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Soort rechtsbetrekking']" mode="customproperty">
		<sm:soortRechtsbetrekking rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Soort aanspraak - verplichting']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}soortVerplichting"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Soort aanspraak - verplichting']" mode="customproperty">
		<sm:soortVerplichting rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Soort bevoegdheid - gehoudenheid']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}soortBevoegdheid"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Soort bevoegdheid - gehoudenheid']" mode="customproperty">
		<sm:soortBevoegdheid rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Soort tijdsaanduiding ']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}soortTijdsaanduiding"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Soort tijdsaanduiding ']" mode="customproperty">
		<sm:soortTijdsaanduiding rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Samengesteld of enkelvoudig ro']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}soortRechtsobject"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Samengesteld of enkelvoudig ro']" mode="customproperty">
		<sm:soortRechtsobject rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Samengesteld of enkelvoudig vrw']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}soortVoorwaarde"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Samengesteld of enkelvoudig vrw']" mode="customproperty">
		<sm:soortVoorwaarde rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Soort persoon ']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}soortPersoon"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Soort persoon ']" mode="customproperty">
		<sm:soortPersoon rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Interpretatie']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}interpretatie"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Interpretatie']" mode="customproperty">
		<sm:interpretatie><xsl:value-of select="@value"/></sm:interpretatie>
	</xsl:template>

	<xsl:template match="property[@name='Primaire naam is vanuit gezichtspunt van']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}primaireNaamIsVanuitGezichtpuntVan"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Primaire naam is vanuit gezichtspunt van']" mode="customproperty">
		<sm:primaireNaamIsVanuitGezichtpuntVan rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Inhoudelijke opmerking']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}inhoudelijkeOpmerking"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Inhoudelijke opmerking']" mode="customproperty">
		<sm:inhoudelijkeOpmerking><xsl:value-of select="@value"/></sm:inhoudelijkeOpmerking>
	</xsl:template>

	<xsl:template match="property[@name='Soort operator']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}soortOperator"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Soort operator']" mode="customproperty">
		<sm:soortOperator rdf:resource="{$smprefix}{replace(@value,' ','')}"/>
	</xsl:template>

	<xsl:template match="property[@name='Annotatie geldig van']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}annotatieGeldigVan"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Annotatie geldig van']" mode="customproperty">
		<sm:annotatieGeldigVan><xsl:value-of select="@value"/></sm:annotatieGeldigVan>
	</xsl:template>

	<!-- Dit is een beetje rare custom property, maar vooruit... -->
	<xsl:template match="property[@name='Meldingstype']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}meldingstype"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Meldingstype']" mode="customproperty">
		<sm:meldingstype><xsl:value-of select="@value"/></sm:meldingstype>
	</xsl:template>

	<xsl:template match="property[@name='Lijst met enkelvoudige voorwaarden']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}voorwaardeLijst"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Lijst met enkelvoudige voorwaarden']" mode="customproperty">
		<sm:voorwaardeLijst><xsl:value-of select="@value"/></sm:voorwaardeLijst>
	</xsl:template>

	<xsl:template match="property[@name='Additionele beperkingsregels (tijdelijk)']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}additioneleBeperkingsregel"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Additionele beperkingsregels (tijdelijk)']" mode="customproperty">
		<sm:additioneleBeperkingsregel><xsl:value-of select="@value"/></sm:additioneleBeperkingsregel>
	</xsl:template>

	<xsl:template match="property[@name='Concept heeft Synoniem']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}heeftSynoniem"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Concept heeft Synoniem']" mode="customproperty">
		<sm:heeftSynoniem><xsl:value-of select="@value"/></sm:heeftSynoniem>
	</xsl:template>

	<xsl:template match="property[@name='Rechtsgevolg: gewijz. rechtsbetrekkingen']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}rechtsgevolgWijziging"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
		<rdf:Property rdf:about="{$smprefix}rechtsgevolgWijzigingID"><rdfs:label><xsl:value-of select="@name"/> ID</rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Rechtsgevolg: gewijz. rechtsbetrekkingen']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:rechtsgevolgWijziging rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:rechtsgevolgWijzigingID><xsl:value-of select="@reference"/></sm:rechtsgevolgWijzigingID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Rechtsgevolg: nieuwe rechtsbetrekkingen']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}rechtsgevolgStart"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
		<rdf:Property rdf:about="{$smprefix}rechtsgevolgStartID"><rdfs:label><xsl:value-of select="@name"/> ID</rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Rechtsgevolg: nieuwe rechtsbetrekkingen']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:rechtsgevolgStart rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:rechtsgevolgStartID><xsl:value-of select="@reference"/></sm:rechtsgevolgStartID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="property[@name='Rechtsgevolg: beëind.rechtsbetrekkingen']" mode="custompropertydef">
		<rdf:Property rdf:about="{$smprefix}rechtsgevolgEinde"><rdfs:label><xsl:value-of select="@name"/></rdfs:label></rdf:Property>
		<rdf:Property rdf:about="{$smprefix}rechtsgevolgEindeID"><rdfs:label><xsl:value-of select="@name"/> ID</rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="property[@name='Rechtsgevolg: beëind.rechtsbetrekkingen']" mode="customproperty">
		<xsl:variable name="ref"><xsl:value-of select="key('item',@reference)/@url"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$ref!=''"><sm:rechtsgevolgEinde rdf:resource="{$ref}"/></xsl:when>
			<xsl:otherwise><sm:rechtsgevolgEindeID><xsl:value-of select="@reference"/></sm:rechtsgevolgEindeID></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Indien het een onbekende eigenschap is, dan wordt dit generieke mechanisme gebruikt -->
	<xsl:template match="property" mode="custompropertydef"/>
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
		<xsl:choose>
			<!-- Blijkbaar wordt 'Nodocumenttypeselected' opgevoerd als er geen documenttype is geselecteerd -->
			<xsl:when test=".='Nodocumenttypeselected'"/>
			<xsl:when test="../local-name()='concept'">
				<rdf:type rdf:resource="{$smprefix}{replace(.,' ','')}"/>
			</xsl:when>
			<xsl:otherwise>
				<sm:type rdf:resource="{$smprefix}{replace(.,' ','')}"/>
			</xsl:otherwise>
		</xsl:choose>
		<!-- type of concepts are (also) used as subtype of concept -->
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

	<xsl:template match="@*" mode="sm-attribute-def">
		<rdf:Property rdf:about="{$smprefix}{name()}"><rdfs:label><xsl:value-of select="name()"/></rdfs:label></rdf:Property>
	</xsl:template>
	<xsl:template match="@*" mode="sm-attribute">
		<xsl:element name="sm:{name()}"><xsl:value-of select="."/></xsl:element>
	</xsl:template>

	<xsl:template match="text" mode="sm-attribute">
		<sm:text><xsl:value-of select="."/></sm:text>
	</xsl:template>

	<xsl:template match="definition" mode="sm-attribute">
		<sm:definition><xsl:value-of select="."/></sm:definition>
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

	<xsl:template match="@uuid" mode="fbm-attribute">
		<!-- Bij constraints is dit per ongeluk uuid geworden, maar id is logischer in vergelijking met de andere klassen -->
		<fbm:id><xsl:value-of select="."/></fbm:id>
	</xsl:template>

	<xsl:template match="@*" mode="fbm-attribute">
		<xsl:element name="fbm:{name()}"><xsl:value-of select="."/></xsl:element>
	</xsl:template>

	<xsl:template match="communicationpattern" mode="fbm-attribute">
		<fbm:communicationPattern rdf:resource="{$dataprefix}{../../@id}-{@sequencenumber}"/>
	</xsl:template>

	<xsl:template match="nounform" mode="fbm-attribute">
		<fbm:nounform><xsl:value-of select="."/></fbm:nounform>
	</xsl:template>

	<xsl:template match="role" mode="fbm-attribute">
		<fbm:role rdf:resource="{$dataprefix}{@id}"/>
	</xsl:template>

	<xsl:template match="variable" mode="fbm-attribute">
		<xsl:variable name="parentid"><xsl:value-of select="../../@id|../../@uuid"/></xsl:variable>
		<!--Sometimes, there is no variable id (huh?), we need to create one -->
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="@id!=''"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="generate-id()"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!--Variable id can be the same as the role id if no difference is visible, used a postfix to distinguish -->
		<xsl:variable name="postfix"><xsl:if test="$parentid = $id">-v</xsl:if></xsl:variable>
		<fbm:variable rdf:resource="{$dataprefix}{$id}{$postfix}"/>
	</xsl:template>

	<xsl:template match="uniquenessconstraint" mode="fbm-attribute">
		<!-- More types of constraints are possible, so the logical term is 'constraint' -->
		<fbm:constraint rdf:resource="{$dataprefix}{@uuid}"/>
	</xsl:template>

	<xsl:template match="variable" mode="fbm-attribute-constraint">
		<!-- Variables from constraints need to be parsed differently: these are actually only references to variables... -->
		<xsl:for-each select="key('item',@reference)">
			<xsl:if test="local-name()='role'">
				<!-- Localname might be role, but that means that the role has the same ID as the variable, so ignore -->
			</xsl:if>
			<xsl:if test="local-name()='variable'">
				<!--Variable id can be the same as the role id if no difference is visible, used a postfix to distinguish -->
				<xsl:variable name="postfix"><xsl:if test="../../@id = @id">-v</xsl:if></xsl:variable>
				<fbm:variable rdf:resource="{$dataprefix}{@id}{$postfix}"/>
			</xsl:if>
			<xsl:if test="local-name()!='role' and local-name()!='variable'">
				<!-- Should not occur -->
				<fbm:variableSomething rdf:resource="{$dataprefix}{@id}"/>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="not(exists(key('item',@reference)))">
			<!-- Referencial integrity error: missing variable -->
			<fbm:variableID><xsl:value-of select="@reference"/></fbm:variableID>
		</xsl:if>
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
			<xsl:apply-templates select="definition" mode="sm-attribute"/>
		</sm:Concept>
	</xsl:template>

	<xsl:template match="textannotation" mode="parse">
		<sm:TextAnnotation rdf:about="{@url}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="sm-attribute"/>
			<xsl:apply-templates select="customproperties/property" mode="customproperty"/>
			<xsl:apply-templates select="text" mode="sm-attribute"/>
		</sm:TextAnnotation>
	</xsl:template>

	<!--
	FBM classes
	-->

	<xsl:template match="entitytype" mode="parse">
		<fbm:Entitytype rdf:about="{$dataprefix}{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
			<xsl:apply-templates select="nounform" mode="fbm-attribute"/>
			<xsl:apply-templates select="customproperties/property" mode="customproperty"/>
		</fbm:Entitytype>
	</xsl:template>

	<xsl:template match="valuetype" mode="parse">
		<fbm:Valuetype rdf:about="{$dataprefix}{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
			<xsl:apply-templates select="customproperties/property" mode="customproperty"/>
		</fbm:Valuetype>
	</xsl:template>

	<xsl:template match="facttype" mode="parse">
		<fbm:Facttype rdf:about="{$dataprefix}{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
			<xsl:apply-templates select="communicationpatterns/communicationpattern" mode="fbm-attribute"/>
			<xsl:apply-templates select="roles/role" mode="fbm-attribute"/>
			<xsl:apply-templates select="constraints/uniquenessconstraint" mode="fbm-attribute"/>
			<xsl:apply-templates select="customproperties/property" mode="customproperty"/>
		</fbm:Facttype>
		<xsl:apply-templates select="communicationpatterns/communicationpattern" mode="parse"/>
		<xsl:apply-templates select="roles/role" mode="parse"/>
		<xsl:apply-templates select="constraints/uniquenessconstraint" mode="parse"/>
	</xsl:template>

	<xsl:template match="communicationpattern" mode="parse">
		<!-- Soms lijkt er iets totaal fout te gaan met het communicatiepatroon, onderstaande hack lost dit op -->
		<xsl:variable name="patroon">
			<xsl:choose>
				<xsl:when test="contains(text,'FOUT')"><xsl:value-of select="substring-before(text,'FOUT')"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="text"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<fbm:CommunicationPattern rdf:about="{$dataprefix}{../../@id}-{@sequencenumber}">
			<rdfs:label><xsl:value-of select="@sequencenumber"/></rdfs:label>
			<fbm:text><xsl:value-of select="$patroon"/></fbm:text>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
			<xsl:apply-templates select="customproperties/property" mode="customproperty"/>
		</fbm:CommunicationPattern>
	</xsl:template>

	<xsl:template match="role" mode="parse">
		<fbm:Role rdf:about="{$dataprefix}{@id}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
			<xsl:apply-templates select="variables/variable" mode="fbm-attribute"/>
			<xsl:apply-templates select="customproperties/property" mode="customproperty"/>
		</fbm:Role>
		<xsl:apply-templates select="variables/variable" mode="parse"/>
	</xsl:template>

	<xsl:template match="variable" mode="parse">
		<xsl:variable name="parentid"><xsl:value-of select="../../@id|../../@uuid"/></xsl:variable>
		<!--Sometimes, there is no variable id (huh?), we need to create one -->
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="@id!=''"><xsl:value-of select="@id"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="generate-id()"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!--Variable id can be the same as the role id if no difference is visible, used a postfix to distinguish -->
		<xsl:variable name="postfix"><xsl:if test="$parentid = $id">-v</xsl:if></xsl:variable>
		<fbm:Variable rdf:about="{$dataprefix}{$id}{$postfix}">
			<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
			<xsl:apply-templates select="customproperties/property" mode="customproperty"/>
		</fbm:Variable>
	</xsl:template>

	<xsl:template match="uniquenessconstraint" mode="parse">
		<fbm:UniquenessConstraint rdf:about="{$dataprefix}{@uuid}">
			<rdfs:label>Uniqueness constraint</rdfs:label>
			<xsl:apply-templates select="@*" mode="fbm-attribute"/>
			<xsl:apply-templates select="variables/variable" mode="fbm-attribute-constraint"/>
			<xsl:apply-templates select="customproperties/property" mode="customproperty"/>
		</fbm:UniquenessConstraint>
	</xsl:template>

	<!--
	Models and structure
	-->

	<xsl:template match="knowledgedomain" mode="parse">
		<xsl:apply-templates select="semanticmodel|formallinguisticmodel" mode="parse"/>
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
			<xsl:for-each-group select="root/knowledgedomain/*/*/*/customproperties/property" group-by="@name">
				<xsl:apply-templates select="current-group()[1]" mode="custompropertydef"/>
			</xsl:for-each-group>
			<xsl:for-each-group select="root/knowledgedomain/*/*/*/@*" group-by="name()">
				<xsl:apply-templates select="current-group()[1]" mode="sm-attribute-def"/>
			</xsl:for-each-group>
			<xsl:apply-templates select="root/knowledgedomain" mode="parse"/>
		</rdf:RDF>
	</xsl:template>

</xsl:stylesheet>
