<!--

    NAME     rdf2html.xsl
    VERSION  1.6.2
    DATE     2016-03-16

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
	Transformation of RDF document to html format. Depends upon rdf2rdfa.xsl
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
>

<xsl:output method="xml" indent="yes"/>

<xsl:key name="rdf" match="results/rdf:RDF" use="@elmo:query"/>
<xsl:key name="resource" match="results/rdf:RDF/rdf:Description" use="@rdf:about"/>
<xsl:key name="nav-bnode" match="results/rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#NavbarSearchAppearance']/rdf:Description" use="@rdf:nodeID"/>

<xsl:variable name="serverdomain"><xsl:value-of select="substring-before(substring-after(/results/context/url,'http://'),'/')"/></xsl:variable>
<xsl:variable name="docroot"><xsl:value-of select="/results/context/@docroot"/></xsl:variable>
<xsl:variable name="subdomain"><xsl:value-of select="/results/context/subdomain"/></xsl:variable>
<xsl:variable name="subject"><xsl:value-of select="/results/context/subject"/></xsl:variable>

<xsl:template match="*" mode="predicate">
	<xsl:variable name="predicate"><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></xsl:variable>
	<a href="{$predicate}">
		<xsl:choose>
			<xsl:when test="@elmo:label"><xsl:value-of select="@elmo:label"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="local-name()"/></xsl:otherwise>
		</xsl:choose>
	</a>
</xsl:template>

<xsl:template name="normalize-language">
	<xsl:param name="text"/>

	<xsl:variable name="language"><xsl:value-of select="/results/context/language"/></xsl:variable>
	<xsl:choose>
		<xsl:when test="$text[@xml:lang=$language]!=''"><xsl:value-of select="$text[@xml:lang=$language]"/></xsl:when> <!-- First choice: language of browser -->
		<xsl:when test="$text[not(exists(@xml:lang))]!=''"><xsl:value-of select="$text[not(exists(@xml:lang))]"/></xsl:when> <!-- Second choice: no language -->
		<xsl:when test="$text[@xml:lang='nl']!=''"><xsl:value-of select="$text[@xml:lang='nl']"/></xsl:when> <!-- Third choice: dutch -->
		<xsl:when test="$text[@xml:lang='en']!=''"><xsl:value-of select="$text[@xml:lang='en']"/></xsl:when> <!-- Fourth choice: english -->
		<xsl:otherwise><xsl:value-of select="$text[1]"/></xsl:otherwise> <!-- If all fails, the first label -->
	</xsl:choose>
</xsl:template>

<!-- TODO: $var is nu geoptimaliseerd, maar werkt dit wel? (het zou een default moeten zijn? -->
<xsl:template name="resource-uri">
	<xsl:param name="uri"/>
	<xsl:param name="var"><none/></xsl:param>
	<xsl:param name="params"/>
	
	<xsl:variable name="urlpart"><xsl:value-of select="substring-after($uri,'http://')"/></xsl:variable>
	<xsl:variable name="domain"><xsl:value-of select="substring-before($urlpart,'/')"/></xsl:variable>
	<xsl:choose>
		<xsl:when test="$var/@elmo:link!=''">
			<xsl:value-of select="$docroot"/>
			<xsl:value-of select="$var/@elmo:link"/>
			<xsl:choose>
				<xsl:when test="matches($var/@elmo:link,'\?')">&amp;</xsl:when>
				<xsl:otherwise>?</xsl:otherwise>
			</xsl:choose>
			<xsl:text>subject=</xsl:text>
			<xsl:value-of select="encode-for-uri($uri)"/>
			<xsl:value-of select="$params"/>
		</xsl:when> <!-- Link fragment, so locally derefenceable -->
		<xsl:when test="$urlpart=''"><xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource?subject=<xsl:value-of select="encode-for-uri($uri)"/></xsl:when> <!-- Make non-dereferenceable uri's locally dereferenceable -->
		<xsl:when test="$var/@elmo:appearance='http://bp4mc2.org/elmo/def#GlobalLink'"><xsl:value-of select="$uri"/></xsl:when> <!-- Global link, so plain uri -->
		<xsl:when test="$domain!=$serverdomain"><xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource?subject=<xsl:value-of select="encode-for-uri($uri)"/></xsl:when> <!-- External uri's are treated as non-dereferenceable -->
		<xsl:when test="matches($uri,'#')"><xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource?subject=<xsl:value-of select="encode-for-uri($uri)"/></xsl:when> <!-- Hash uri's are treated as non-dereferenceable (to avoid losing the part after the hash) -->
		<xsl:otherwise><xsl:value-of select="$uri"/></xsl:otherwise> <!--Plain URI -->
	</xsl:choose>
</xsl:template>

<xsl:template name="cross-site-marker">
	<xsl:param name="url"/>
	
	<xsl:variable name="urlpart"><xsl:value-of select="substring-after($url,'http://')"/></xsl:variable>
	<xsl:variable name="domain"><xsl:value-of select="substring-before($urlpart,'/')"/></xsl:variable>

	<xsl:if test="$urlpart!='' and $domain!=$serverdomain">
		<span class="glyphicon glyphicon-share-alt" aria-hidden="true"/>
	</xsl:if>
</xsl:template>

<xsl:template match="*" mode="glossary">
	<xsl:param name="glossary"/>
	<xsl:param name="uri"/>
	<xsl:param name="stylesheet"/>
	<xsl:param name="appearance"/>
	<xsl:variable name="termlist" select="key('rdf',$glossary)"/>
	<!-- Tokenizer consists of all the words that can be chosen, conform the syntax of the replace function -->
	<xsl:variable name="tokenizer">
		<xsl:for-each select="$termlist/rdf:Description"><xsl:sort select="string-length(elmo:name[1])" order="descending"/>
			<xsl:if test="not($appearance='http://bp4mc2.org/elmo/def#FilteredGlossaryAppearance') or exists(*[@rdf:resource=$uri])">
				<xsl:text>|</xsl:text>
				<xsl:text>( </xsl:text><xsl:value-of select="elmo:name[1]"/><xsl:text> )</xsl:text>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$tokenizer!=''">
			<!-- De tekst worden nu van elkaar gescheiden obv de relevantie woorden. Om de scheiding op leestekens te houden, moet elk -->
			<!-- woord beginnen en eindigen met een spatie, daarom ook extra spaties toevoegen bij leestekens "," en "." -->
			<xsl:for-each select="tokenize(replace(replace(concat(' ',.,' '),'(,|\.)',' $0'),substring($tokenizer,2,9999),'@@$0@@','i'),'@@')">
				<xsl:variable name="term" select="substring(.,2,string-length(.)-2)"/>
				<xsl:variable name="termlink" select="$termlist/rdf:Description[upper-case(elmo:name[1])=upper-case($term)]"/>
				<xsl:choose>
					<xsl:when test="exists($termlink)">
						<xsl:variable name="href">
							<xsl:call-template name="resource-uri">
								<xsl:with-param name="uri" select="$termlink[1]/@rdf:about"/>
								<xsl:with-param name="var" select="$termlink[1]"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:text> </xsl:text>
						<a href="{$href}" style="{$stylesheet}"><xsl:value-of select="$term"/></a><xsl:text> </xsl:text>
					</xsl:when>
					<xsl:otherwise><xsl:value-of select="replace(replace(.,' \.','.'),' ,',',')"/></xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="."/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="object">
	<xsl:choose>
		<!-- Image -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ImageAppearance'">
			<img src="{@rdf:resource}"/>
		</xsl:when>
		<!-- Reference to another resource, without a label -->
		<xsl:when test="exists(@rdf:resource)">
			<xsl:variable name="resource-uri">
				<xsl:call-template name="resource-uri">
					<xsl:with-param name="uri" select="@rdf:resource"/>
					<xsl:with-param name="var" select="."/>
				</xsl:call-template>
			</xsl:variable>
			<a href="{$resource-uri}">
				<xsl:choose>
					<xsl:when test="@rdfs:label!=''"><xsl:value-of select="@rdfs:label"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="@rdf:resource"/></xsl:otherwise>
				</xsl:choose>
			</a>
		</xsl:when>
		<!-- Reference to another resource, with a label -->
		<xsl:when test="exists(rdf:Description/@rdf:about)">
			<xsl:variable name="resource-uri">
				<xsl:call-template name="resource-uri">
					<xsl:with-param name="uri" select="rdf:Description/@rdf:about"/>
					<xsl:with-param name="var" select="."/> <!-- Was rdf:Description, maar dit lijkt beter -->
				</xsl:call-template>
			</xsl:variable>
			<a href="{$resource-uri}">
				<xsl:choose>
					<xsl:when test="rdf:Description/rdfs:label!=''"><xsl:value-of select="rdf:Description/rdfs:label"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="rdf:Description/@rdf:about"/></xsl:otherwise>
				</xsl:choose>
				<xsl:call-template name="cross-site-marker">
					<xsl:with-param name="url" select="$resource-uri"/>
				</xsl:call-template>
			</a>
		</xsl:when>
		<!-- Blank node -->
		<xsl:when test="exists(rdf:Description/@rdf:nodeID)">
			<table>
				<xsl:for-each-group select="rdf:Description/*" group-by="name()">
					<tr>
						<td><xsl:apply-templates select="." mode="predicate"/></td>
						<td>
							<xsl:for-each select="current-group()">
								<xsl:if test="position()!=1">; </xsl:if>
								<xsl:apply-templates select="." mode="object"/>
							</xsl:for-each>
						</td>
					</tr>
				</xsl:for-each-group>
			</table>
		</xsl:when>
		<!-- Lonely blank node -->
		<xsl:when test="exists(@rdf:nodeID)">
			<xsl:value-of select="@rdf:nodeID"/>
		</xsl:when>
		<!-- Literal with glossary -->
		<xsl:when test="exists(@html:glossary)">
			<xsl:apply-templates select="." mode="glossary">
				<xsl:with-param name="glossary" select="@html:glossary"/>
				<xsl:with-param name="uri" select="@rdf:resource"/>
				<xsl:with-param name="stylesheet"/>
				<xsl:with-param name="appearance" select="@elmo:appearance"/>
			</xsl:apply-templates>
		</xsl:when>
		<!-- HTML -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#HtmlAppearance'">
			<xsl:variable name="html">&lt;div&gt;<xsl:value-of select="."/>&lt;/div&gt;</xsl:variable>
			<xsl:copy-of select="saxon:parse($html)" xmlns:saxon="http://saxon.sf.net/"/>
		</xsl:when>
		<xsl:otherwise>
			<!-- If new lines are included, include them in resulting html -->
			<xsl:for-each select="tokenize(replace(.,'\n+$',''),'\n')">
				<xsl:if test="position()!=1"><br/></xsl:if>
				<xsl:value-of select="."/>
			</xsl:for-each>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="rdf:RDF" mode="present">
	<xsl:choose>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance'"/> <!-- Hidden, dus niet tonen -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#HeaderAppearance'"/> <!-- Al gedaan -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#NavbarAppearance'"/> <!-- Al gedaan -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#NavbarSearchAppearance'"/> <!-- Al gedaan -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#TreeAppearance'"/> <!-- Al gedaan -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#LoginAppearance'">
			<xsl:apply-templates select="." mode="LoginAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#CarouselAppearance'">
			<xsl:apply-templates select="." mode="CarouselAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ShortTableAppearance'">
			<xsl:apply-templates select="." mode="TableAppearance"><xsl:with-param name="paging">false</xsl:with-param></xsl:apply-templates>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#TableAppearance' or @elmo:appearance='http://bp4mc2.org/elmo/def#TextSearchAppearance'">
			<xsl:apply-templates select="." mode="TableAppearance"><xsl:with-param name="paging">true</xsl:with-param></xsl:apply-templates>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#IndexAppearance'">
			<xsl:apply-templates select="." mode="IndexAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#HtmlAppearance'">
			<xsl:apply-templates select="." mode="HtmlAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#GraphAppearance'">
			<xsl:apply-templates select="." mode="GraphAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#TextAppearance'">
			<xsl:apply-templates select="." mode="TextAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#FormAppearance'">
			<xsl:apply-templates select="." mode="FormAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#GeoAppearance' or @elmo:appearance='http://bp4mc2.org/elmo/def#GeoSelectAppearance'">
			<xsl:apply-templates select="." mode="GeoAppearance"><xsl:with-param name="backmap">brt</xsl:with-param><xsl:with-param name="appearance" select="substring-after(@elmo:appearance,'http://bp4mc2.org/elmo/def#')"/></xsl:apply-templates>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ImageAppearance'">
			<xsl:apply-templates select="." mode="GeoAppearance"><xsl:with-param name="backmap">image</xsl:with-param><xsl:with-param name="appearance">ImageAppearance</xsl:with-param></xsl:apply-templates>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ChartAppearance'">
			<xsl:apply-templates select="." mode="ChartAppearance"/>
		</xsl:when>
		<xsl:otherwise>
			<!-- No, or an unknown appearance, use the data to select a suitable appearance -->
			<xsl:apply-templates select="." mode="ContentAppearance"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="/">
	<xsl:for-each select="results">
		<html lang="{context/language}">
			<xsl:apply-templates select="." mode="html-head"/>
			<body>
				<div id="page">
					<!-- Meerdere queries zijn mogelijk -->
					<!-- Eerst de headerstuf -->
					<!-- Meer dan 1 navbar leid tot niet-gedefinieerd gedrag -->
					<xsl:apply-templates select="rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#HeaderAppearance']" mode="HeaderAppearance"/>
					<xsl:apply-templates select="rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#NavbarAppearance']" mode="NavbarAppearance"/>
					<xsl:apply-templates select="rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#NavbarSearchAppearance']" mode="NavbarSearchAppearance"/>
					<!-- Dan de echte inhoud -->
					<div class="content">
						<div class="container">
							<xsl:choose>
								<xsl:when test="exists(rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#TreeAppearance'])">
									<div class="row">
										<div class="col-md-4">
											<xsl:apply-templates select="rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#TreeAppearance']" mode="TreeAppearance"/>
										</div>
										<div class="col-md-8">
											<xsl:apply-templates select="rdf:RDF" mode="present"/>
										</div>
									</div>
								</xsl:when>
								<xsl:otherwise>
									<xsl:apply-templates select="rdf:RDF" mode="present"/>
								</xsl:otherwise>
							</xsl:choose>
						</div>
					</div>
				</div>
			</body>
		</html>
	</xsl:for-each>
</xsl:template>

<xsl:template match="results" mode="html-head">
	<head>
		<meta charset="utf-8"/>
		<meta http-equiv="X-UA-Compatible" content="IE=edge" />
		<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
		<title>Linked Data Theater</title>

		<link rel="stylesheet" type="text/css" href="{$docroot}/css/bootstrap.min.css"/>
		<link rel="stylesheet" type="text/css" href="{$docroot}/css/dataTables.bootstrap.min.css"/>
		<link rel="stylesheet" type="text/css" href="{$docroot}/css/typeaheadjs.css"/>
		<link rel="stylesheet" type="text/css" href="{$docroot}/css/bootstrap-datepicker3.min.css"/>
		<link rel="stylesheet" type="text/css" href="{$docroot}/css/ldt-theme.css"/>

		<!-- Rijkshuisstijl -->
		<!-- <link rel="stylesheet" type="text/css" href="{$docroot}/rhs/theme.css"/> -->
		<xsl:for-each select="context/stylesheet">
			<link rel="stylesheet" type="text/css" href="{$docroot}{@href}"/>
		</xsl:for-each>
		
		<!-- TODO: Make this generic (appearances with specific stylesheets) -->
		<xsl:if test="exists(rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#LoginAppearance'])">
			<link rel="stylesheet" type="text/css" href="{$docroot}/css/signin.css"/>
		</xsl:if>
		
		<script type="text/javascript" language="javascript" src="{$docroot}/js/jquery-1.11.3.min.js"></script>
		<script type="text/javascript" language="javascript" src="{$docroot}/js/jquery.dataTables.min.js"></script>
		<script type="text/javascript" language="javascript" src="{$docroot}/js/dataTables.bootstrap.min.js"></script>
		<script type="text/javascript" language="javascript" src="{$docroot}/js/bootstrap.min.js"></script>
		<script type="text/javascript" language="javascript" src="{$docroot}/js/typeahead.bundle.min.js"></script>
		<script type="text/javascript" language="javascript" src="{$docroot}/js/bootstrap-datepicker.min.js"></script>
		<script type="text/javascript" language="javascript" src="{$docroot}/js/locales/bootstrap-datepicker.nl.min.js"></script>
		<script type="text/javascript" language="javascript" src="{$docroot}/js/d3.v3.min.js"></script>

		<xsl:apply-templates select="context" mode="datatable-languageset"/>
		
	</head>
</xsl:template>

<xsl:template match="rdf:Description" mode="PropertyTable">
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title">
				<a href="{@rdf:about}">
					<xsl:choose>
						<xsl:when test="exists(rdfs:label)"><xsl:value-of select="rdfs:label"/></xsl:when>
						<xsl:otherwise><xsl:value-of select="@rdf:about"/></xsl:otherwise>
					</xsl:choose>
				</a>
			</h3>
		</div>
		<div class="panel-body">
			<table class="table table-striped table-bordered">
				<tbody>
				<xsl:for-each-group select="*" group-by="name()"><xsl:sort select="@elmo:index"/>
					<xsl:if test="not(@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance')">
						<tr>
							<td><xsl:apply-templates select="." mode="predicate"/></td>
							<td>
								<xsl:choose>
									<xsl:when test="count(current-group())=1">
										<xsl:apply-templates select="." mode="object"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:for-each select="current-group()">
											<!-- <xsl:if test="position()!=1">;<br/></xsl:if>-->
											<p><xsl:apply-templates select="." mode="object"/></p>
										</xsl:for-each>
									</xsl:otherwise>
								</xsl:choose>
							</td>
						</tr>
					</xsl:if>
				</xsl:for-each-group>
				</tbody>
			</table>
		</div>
	</div>
</xsl:template>

<xsl:template match="context" mode="datatable-languageset">
	<script type="text/javascript" language="javascript" charset="utf-8">
		<xsl:text>var elmo_language = </xsl:text>
		<xsl:choose>
			<xsl:when test="language='nl'">{language:{info:"_START_ tot _END_ van _TOTAL_ resultaten",search:"Zoeken:",lengthMenu:"Toon _MENU_ rijen",zeroRecords:"Niets gevonden",infoEmpty: "Geen resultaten",paginate:{first:"Eerste",previous:"Vorige",next:"Volgende",last:"Laatste"}},paging:true,searching:true,info:true}</xsl:when>
			<xsl:otherwise>{};</xsl:otherwise>
		</xsl:choose>
		
	</script>
</xsl:template>

<xsl:template match="res:binding" mode="tableobject">
	<xsl:variable name="varname" select="res:variable"/>
	<xsl:variable name="vars" select="../../res:resultVariable"/>
	<xsl:variable name="parname" select="res:variable"/>
	<xsl:choose>
		<xsl:when test="exists($vars[.=$parname]/@elmo:template)">
			<xsl:variable name="uri" select="res:value/@rdf:resource"/>
			<xsl:variable name="templatestring" select="tokenize(substring($vars[.=$parname]/@elmo:template,2,string-length($vars[.=$parname]/@elmo:template)-2),'&quot;; &quot;')"/>
			<xsl:variable name="template">
				<xsl:for-each select="$templatestring">
					<item pos="{position()}" name="{substring-before(substring-after(.,'&lt;'),'>')}" first="{substring-before(.,'&lt;')}" next="{substring-after(.,'>')}"/>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="context">
				<xsl:for-each-group select="key('rdf',$vars[.=$parname]/@html:glossary)/rdf:Description/*[@rdf:resource=$uri]" group-by="local-name()">
					<xsl:variable name="name" select="local-name()"/>
					<xsl:for-each select="current-group()">
						<item prio="{$template/item[@name=$name]/@pos}" pos="{position()}" first="{$template/item[@name=$name]/@first}" next="{$template/item[@name=$name]/@next}" uri="{../@rdf:about}" rel="{$name}"><xsl:value-of select="../elmo:name"/></item>
					</xsl:for-each>
				</xsl:for-each-group>
			</xsl:variable>
			<xsl:value-of select="$template/item[1]/@first"/>
			<a href="{$uri}" style="{$vars[.=$parname]/@html:stylesheet}"><xsl:value-of select="$context/item[@uri=$uri]"/></a>
			
			<xsl:for-each select="$context/item[@uri!=$uri and @prio!='']"><xsl:sort select="@prio"/>
				<xsl:text> </xsl:text>
				<xsl:choose>
					<xsl:when test="position()=1"><xsl:value-of select="@first"/></xsl:when>
					<xsl:when test="@pos!=1"><xsl:value-of select="replace(@next,'\([^\)]*\)','')"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="replace(@next,'\(|\)','')"/></xsl:otherwise>
				</xsl:choose>
				<xsl:text> </xsl:text><a href="{@uri}" style="{$vars[.=$parname]/@html:stylesheet}"><xsl:value-of select="."/></a>
			</xsl:for-each>
		</xsl:when>
		<xsl:when test="exists(res:value/@rdf:resource)">
			<xsl:variable name="parameters">
				<xsl:for-each select="../res:binding">
					<xsl:variable name="pname" select="res:variable"/>
					<xsl:choose>
						<xsl:when test="substring-after($vars[.=$pname]/@elmo:name,'@')!=''">
							<xsl:text>&amp;</xsl:text>
							<xsl:value-of select="substring-after($vars[.=$pname]/@elmo:name,'@')"/>
							<xsl:text>=</xsl:text>
							<xsl:choose>
								<xsl:when test="res:value/@rdf:resource!=''">%3C<xsl:value-of select="encode-for-uri(res:value/@rdf:resource)"/>%3E</xsl:when>
								<xsl:otherwise>%22<xsl:value-of select="encode-for-uri(res:value)"/>%22</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:when test="$vars[.=$pname]/@elmo:name!=''">&amp;<xsl:value-of select="$vars[.=$pname]/@elmo:name"/>=<xsl:value-of select="encode-for-uri(res:value/@rdf:resource)"/><xsl:value-of select="encode-for-uri(res:value)"/></xsl:when>
						<xsl:otherwise/>
					</xsl:choose>
				</xsl:for-each>
			</xsl:variable>
			
			<xsl:variable name="resource-uri">
				<xsl:call-template name="resource-uri">
					<xsl:with-param name="uri" select="res:value/@rdf:resource"/>
					<xsl:with-param name="var" select="../../res:resultVariable[.=$varname]"/>
					<xsl:with-param name="params" select="$parameters"/>
				</xsl:call-template>
			</xsl:variable>
			<!-- _label is used for the label of a resource -->
			<xsl:variable name="labelvar"><xsl:value-of select="$varname"/>_label</xsl:variable>
			<xsl:variable name="qlabel"><xsl:value-of select="../res:binding[res:variable=$labelvar]/res:value"/></xsl:variable>
			<xsl:variable name="plabel"><xsl:value-of select="substring-after(res:value/@rdf:resource,'#')"/></xsl:variable>
			<xsl:variable name="label">
				<xsl:value-of select="$qlabel"/>
				<xsl:if test="$qlabel=''">
					<xsl:value-of select="$plabel"/>
					<xsl:if test="$plabel=''"><xsl:value-of select="res:value/@rdf:resource"/></xsl:if>
				</xsl:if>
			</xsl:variable>
			<!-- _count is used for a count of a resource -->
			<xsl:variable name="countvar"><xsl:value-of select="res:variable"/>_count</xsl:variable>
			<xsl:variable name="count"><xsl:value-of select="../res:binding[res:variable=$countvar]/res:value"/></xsl:variable>
			<xsl:variable name="detailsvar"><xsl:value-of select="res:variable"/>_details</xsl:variable>
			<xsl:variable name="details"><xsl:value-of select="../res:binding[res:variable=$detailsvar]/res:value"/></xsl:variable>
			<a href="{$resource-uri}">
				<xsl:value-of select="$label"/>
				<xsl:if test="$count!=''">
					<xsl:text> </xsl:text><span class="badge"><xsl:value-of select="$count"/></span>
				</xsl:if>
			</a>
			<xsl:if test="$details!=''">
				<br /><xsl:value-of select="$details"/>
			</xsl:if>
		</xsl:when>
		<xsl:when test="$vars[.=$parname]/@elmo:appearance='http://bp4mc2.org/elmo/def#HtmlAppearance'">
			<xsl:variable name="html">&lt;div&gt;<xsl:value-of select="res:value"/>&lt;/div&gt;</xsl:variable>
			<xsl:copy-of select="saxon:parse($html)" xmlns:saxon="http://saxon.sf.net/"/>
		</xsl:when>
		<xsl:when test="exists($vars[.=$parname]/@html:glossary)">
			<xsl:variable name="subjectvar" select="$vars[@elmo:name='subject']"/>
			<xsl:apply-templates select="res:value" mode="glossary">
				<xsl:with-param name="glossary" select="$vars[.=$parname]/@html:glossary"/>
				<xsl:with-param name="uri" select="../res:binding[res:variable=$subjectvar]/res:value/@rdf:resource"/>
				<xsl:with-param name="stylesheet" select="$vars[.=$parname]/@html:stylesheet"/>
				<xsl:with-param name="appearance" select="$vars[.=$parname]/@elmo:appearance"/>
			</xsl:apply-templates>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="res:value"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="rdf:RDF" mode="IndexAppearance">
	<!-- IndexAppearance with dynamic data -->
	<xsl:for-each select="rdf:Description/res:solution[1]">
		<style>
			.nav-tabs li a {
				padding-left: 10px;
				padding-right: 10px;
				padding-top: 5px;
				padding-bottom: 5px;
				margin-top: 0px;
			}
		</style>
		<div class="row">
			<ul class="nav nav-tabs">
				<xsl:for-each select="res:binding">
					<li>
						<xsl:if test="res:value/@rdf:resource=$subject"><xsl:attribute name="class">active</xsl:attribute></xsl:if>
						<xsl:variable name="resource-uri"><xsl:call-template name="resource-uri"><xsl:with-param name="uri" select="res:value/@rdf:resource"/></xsl:call-template></xsl:variable>
						<a href="{$resource-uri}"><xsl:value-of select="res:variable"/></a>
					</li>
				</xsl:for-each>
			
				<xsl:variable name="value" select="tokenize(rdf:value,'\|')"/>
				<xsl:variable name="link" select="html:link"/>
				<xsl:variable name="para" select="elmo:name"/>
				<xsl:variable name="current" select="/results/context/parameters/parameter[name=$para]/value"/>
				<xsl:for-each select="tokenize(rdfs:label,'\|')">
					<xsl:variable name="pos" select="position()"/>
					<li>
						<xsl:if test="$value[$pos]=$current"><xsl:attribute name="class">active</xsl:attribute></xsl:if>
						<a href="{$link}?{$para}={$value[$pos]}"><xsl:value-of select="."/></a>
					</li>
				</xsl:for-each>
			</ul>
		</div>
	</xsl:for-each>
	<!-- IndexAppearance with static data -->
	<xsl:for-each select="rdf:Description[exists(rdfs:label)][1]">
		<style>
			.nav-tabs li a {
				padding-left: 10px;
				padding-right: 10px;
				padding-top: 5px;
				padding-bottom: 5px;
				margin-top: 0px;
			}
		</style>
		<div class="row">
			<ul class="nav nav-tabs">
				<xsl:variable name="value" select="tokenize(rdf:value,'\|')"/>
				<xsl:variable name="link" select="html:link"/>
				<xsl:variable name="para" select="elmo:name"/>
				<xsl:variable name="current" select="/results/context/parameters/parameter[name=$para]/value"/>
				<xsl:for-each select="tokenize(rdfs:label,'\|')">
					<xsl:variable name="pos" select="position()"/>
					<li>
						<xsl:if test="$value[$pos]=$current"><xsl:attribute name="class">active</xsl:attribute></xsl:if>
						<a href="{$link}?{$para}={$value[$pos]}"><xsl:value-of select="."/></a>
					</li>
				</xsl:for-each>
			</ul>
		</div>
	</xsl:for-each>
</xsl:template>

<xsl:template match="rdf:RDF" mode="TableAppearance">
	<xsl:param name="paging"/>
	<!-- Link for other formats -->
	<!-- Original, changed
	<xsl:variable name="original-link">
		<xsl:value-of select="$docroot"/>
		<xsl:text>/resource?subject=</xsl:text><xsl:value-of select="encode-for-uri(../context/subject)"/>
		<xsl:text>&amp;representation=</xsl:text><xsl:value-of select="encode-for-uri(@elmo:query)"/>
		<xsl:text>&amp;format=</xsl:text>
	</xsl:variable>
	-->
	<xsl:variable name="original-link">
		<xsl:value-of select="../context/url"/>
		<xsl:text>?</xsl:text>
		<xsl:for-each select="../context/parameters/parameter"> <!-- This doesn't work if the subject is given as a parameter! -->
			<xsl:value-of select="name"/>=<xsl:value-of select="encode-for-uri(value)"/>
			<xsl:text>&amp;</xsl:text>
		</xsl:for-each>
		<xsl:text>representation=</xsl:text><xsl:value-of select="encode-for-uri(@elmo:query)"/>
		<xsl:text>&amp;format=</xsl:text>
	</xsl:variable>
	<!-- A select query will have @rdf:nodeID elements, with id 'rset' -->
	<xsl:for-each select="rdf:Description[@rdf:nodeID='rset']">
		<xsl:if test="$paging='true' or exists(res:solution)">
			<div class="row">
				<script type="text/javascript" charset="utf-8">
					$(document).ready(function() {
						elmo_language.paging = <xsl:value-of select="$paging"/>;
						elmo_language.searching = <xsl:value-of select="$paging"/>;
						elmo_language.info = <xsl:value-of select="$paging"/>;
						$('#datatable<xsl:value-of select="generate-id()"/>').dataTable(elmo_language);
					} );
				</script>
				<table id="datatable{generate-id()}" class="table table-striped table-bordered">
					<thead>
						<tr>
							<xsl:for-each select="res:resultVariable[not(matches(.,'[^_]*_(label|details|count|uri)'))]">
								<th>
									<xsl:choose>
										<xsl:when test="exists(@elmo:label)"><xsl:value-of select="@elmo:label"/></xsl:when>
										<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
									</xsl:choose>
								</th>
							</xsl:for-each>
						</tr>
					</thead>
					<tbody>
						<xsl:choose>
							<xsl:when test="exists(res:resultVariable[@elmo:name='SUBJECT'])">
								<xsl:variable name="key" select="res:resultVariable[@elmo:name='SUBJECT'][1]"/>
								<xsl:for-each-group select="res:solution" group-by="res:binding[res:variable=$key]/res:value/@rdf:resource">
									<tr>
										<xsl:variable name="group" select="current-group()"/>
										<xsl:for-each select="../res:resultVariable[not(matches(.,'[^_]*_(label|details|count|uri)'))]">
											<xsl:variable name="var" select="."/>
											<td>
												<!-- Remove duplicates, so still a for-each-group -->
												<xsl:for-each-group select="$group/res:binding[res:variable=$var]" group-by="concat(res:value,res:value/@rdf:resource)">
													<xsl:if test="position()!=1">, </xsl:if>
													<xsl:apply-templates select="." mode="tableobject"/>
												</xsl:for-each-group>
											</td>
										</xsl:for-each>
									</tr>
								</xsl:for-each-group>
							</xsl:when>
							<xsl:otherwise>
								<xsl:for-each select="res:solution">
									<tr>
										<xsl:variable name="binding" select="res:binding"/>
										<xsl:for-each select="../res:resultVariable[not(matches(.,'[^_]*_(label|details|count|uri)'))]">
											<xsl:variable name="var" select="."/>
											<td><xsl:apply-templates select="$binding[res:variable=$var]" mode="tableobject"/></td>
										</xsl:for-each>
									</tr>
								</xsl:for-each>
							</xsl:otherwise>
						</xsl:choose>
					</tbody>
				</table>
				<a href="{$original-link}xlsx">Excel</a>
			</div>
		</xsl:if>
	</xsl:for-each>
</xsl:template>

<xsl:template match="rdf:RDF" mode="ContentAppearance">
	<!-- A construct query will have @rdf:about elements -->
	<xsl:if test="exists(rdf:Description/@rdf:about)">
		<xsl:for-each select="rdf:Description">
			<div class="row">
				<xsl:apply-templates select="." mode="PropertyTable"/>
			</div>
		</xsl:for-each>
	</xsl:if>
</xsl:template>

<xsl:template match="rdf:RDF" mode="HtmlAppearance">
	<div class="row">
		<div class="panel panel-primary">
			<div class="panel-heading">
				<h3 class="panel-title">
					<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description/rdfs:label"/></xsl:call-template></xsl:variable>
					<xsl:value-of select="$label"/>
				</h3>
			</div>
			<div class="panel-body htmlapp">
				<!-- HTML as part of a construct query -->
				<xsl:if test="exists(rdf:Description/elmo:html)">
					<xsl:variable name="html">&lt;div><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description/elmo:html"/></xsl:call-template>&lt;/div></xsl:variable>
					<xsl:copy-of select="saxon:parse($html)" xmlns:saxon="http://saxon.sf.net/"/>
				</xsl:if>
				<!-- HTML as part of a select query -->
				<xsl:if test="rdf:Description/res:resultVariable='html'">
					<xsl:variable name="html">
						<xsl:text>&lt;div></xsl:text>
						<xsl:for-each select="rdf:Description/res:solution">
							<xsl:value-of select="res:binding[res:variable='html']/res:value"/>
						</xsl:for-each>
						<xsl:text>&lt;/div></xsl:text>
					</xsl:variable>
					<xsl:copy-of select="saxon:parse($html)" xmlns:saxon="http://saxon.sf.net/"/>
				</xsl:if>
			</div>
		</div>
	</div>
</xsl:template>

<xsl:template match="rdf:RDF" mode="HeaderAppearance">
	<div class="container hidden-xs">
		<div class="row text-center">
			<xsl:for-each select="rdf:Description/elmo:html">
				<xsl:copy-of select="saxon:parse(.)" xmlns:saxon="http://saxon.sf.net/"/>
			</xsl:for-each>
		</div>
	</div>
</xsl:template>

<xsl:template match="rdf:RDF" mode="CarouselAppearance">
	<xsl:choose>
		<xsl:when test="exists(rdf:Description/@rdf:about)">
			<xsl:variable name="carousel-id" select="generate-id()"/>
			<div class="carousel slide" id="carousel{$carousel-id}" data-ride="carousel">
				<ol class="carousel-indicators">
					<xsl:for-each select="rdf:Description">
						<li data-target="#carousel{$carousel-id}" data-slide-to="{position()-1}">
							<xsl:if test="position()=1"><xsl:attribute name="class">active</xsl:attribute></xsl:if>
						</li>
					</xsl:for-each>
				</ol>
				<div class="carousel-inner" role="listbox">
					<xsl:for-each select="rdf:Description">
						<xsl:variable name="class">item<xsl:if test="position()=1"> active</xsl:if></xsl:variable>
						<div class="{$class}">
							<xsl:apply-templates select="." mode="PropertyTable"/>
						</div>
					</xsl:for-each>
				</div>
				<a class="left carousel-control" href="#carousel{$carousel-id}" role="button" data-slide="prev">
					<span class="glyphicon glyphicon-chevron-left" aria-hidden="true"></span>
					<span class="sr-only">Previous</span>
				</a>
				<a class="right carousel-control" href="#carousel{$carousel-id}" role="button" data-slide="next">
					<span class="glyphicon glyphicon-chevron-right" aria-hidden="true"></span>
					<span class="sr-only">Next</span>
				</a>
			</div>
		</xsl:when>
		<xsl:otherwise>
			<!-- Carousel appearance, but data that should not be presented in a carousel -->
			<xsl:apply-templates select="." mode="ContentAppearance"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="rdf:RDF" mode="NavbarAppearance">
	<nav class="navbar navbar-default">
		<div class="container">
			<div class="navbar-header">
				<button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
					<span class="sr-only">Toggle navigation</span>
					<span class="icon-bar"></span>
					<span class="icon-bar"></span>
					<span class="icon-bar"></span>
				</button>
				<xsl:if test="exists(rdf:Description/dcterms:title)">
					<a class="navbar-brand" href="/"><xsl:value-of select="rdf:Description/dcterms:title[1]"/></a>
				</xsl:if>
			</div>
			<div id="navbar" class="collapse navbar-collapse">
				<ul class="nav navbar-nav">
					<xsl:for-each select="rdf:Description[exists(rdfs:label)]"><xsl:sort select="elmo:index"/>
						<li><a href="{html:link}"><xsl:value-of select="rdfs:label"/></a></li>
					</xsl:for-each>
				</ul>
			</div>
		</div>
	</nav>
</xsl:template>

<xsl:template match="rdf:Description" mode="nav">
	<xsl:if test="exists(rdfs:label)">
		<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdfs:label"/></xsl:call-template></xsl:variable>
		<li>
			<xsl:choose>
				<xsl:when test="exists(elmo:data)">
					<xsl:attribute name="class">dropdown</xsl:attribute>
					<a class="dropdown-toggle" role="button" aria-expanded="false" href="#" data-toggle="dropdown"><xsl:value-of select="$label"/><span class="caret"/></a>
					<ul class="dropdown-menu" role="menu">
						<xsl:for-each select="elmo:data"><xsl:sort select="key('nav-bnode',@rdf:nodeID)/elmo:index"/>
							<xsl:apply-templates select="key('nav-bnode',@rdf:nodeID)" mode="nav"/>
						</xsl:for-each>
					</ul>
				</xsl:when>
				<xsl:when test="exists(html:link)">
					<a href="{html:link}"><xsl:value-of select="$label"/></a>
				</xsl:when>
				<xsl:otherwise>
					<a href="#"><xsl:value-of select="$label"/></a>
				</xsl:otherwise>
			</xsl:choose>
		</li>
	</xsl:if>
</xsl:template>

<xsl:template match="rdf:RDF" mode="NavbarSearchAppearance">
	<nav class="navbar navbar-default">
		<div class="container">
			<div class="navbar-header">
				<button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
					<span class="sr-only">Toggle navigation</span>
					<span class="icon-bar"></span>
					<span class="icon-bar"></span>
					<span class="icon-bar"></span>
				</button>
				<xsl:variable name="root" select="rdf:Description[1]"/>
				<xsl:if test="exists($root/rdfs:label)">
					<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="$root/rdfs:label"/></xsl:call-template></xsl:variable>
					<xsl:variable name="link">
						<xsl:choose>
							<xsl:when test="exists($root/html:link)"><xsl:value-of select="$root/html:link"/></xsl:when>
							<xsl:otherwise><xsl:value-of select="$docroot"/></xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<a class="navbar-brand" href="{$link}"><xsl:value-of select="$label"/></a>
				</xsl:if>
			</div>
			<div id="navbar" class="collapse navbar-collapse">
				<ul class="nav navbar-nav">
					<xsl:for-each select="rdf:Description[1]/elmo:data"><xsl:sort select="key('nav-bnode',@rdf:nodeID)/elmo:index"/>
						<xsl:apply-templates select="key('nav-bnode',@rdf:nodeID)" mode="nav"/>
					</xsl:for-each>
				</ul>
				<form class="navbar-form navbar-right" method="get" action="{$docroot}{$subdomain}/query/search">
					<div class="input-group">
						<input class="form-control" type="text" placeholder="Search" name="term"/>
						<span class="input-group-btn">
							<button class="btn btn-primary" type="submit">
								<span class="glyphicon glyphicon-search"/>
							</button>
						</span>
					</div>
				</form>
			</div>
		</div>
	</nav>
</xsl:template>

<xsl:template match="rdf:RDF" mode="LoginAppearance">
	<script type="text/javascript" language="javascript" charset="utf-8">
		function setUsername(inputName) {
			if (inputName.value.match(/@/)) {
				inputName.parentNode.inputDomainUsername.value = inputName.value;
			} else {
				inputName.parentNode.inputDomainUsername.value = inputName.value+'@'+window.location.hostname;
			}
		}
	</script>
	<form class="form-signin" action="{$docroot}/j_security_check" method="post">
		<xsl:if test="exists(rdf:Description/html:alert[1])">
			<xsl:variable name="text"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description/html:alert"/></xsl:call-template></xsl:variable>
			<div class="alert alert-danger" role="alert"><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"/><xsl:text> </xsl:text><xsl:value-of select="$text"/></div>
		</xsl:if>
		<xsl:if test="exists(rdf:Description/html:status[1])">
			<xsl:variable name="text"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description/html:status"/></xsl:call-template></xsl:variable>
			<div class="alert alert-info" role="alert"><span class="glyphicon glyphicon-info-sign" aria-hidden="true"/><xsl:text> </xsl:text><xsl:value-of select="$text"/></div>
		</xsl:if>
		<xsl:if test="exists(rdf:Description/html:h2[1])">
			<xsl:variable name="text"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description/html:h2"/></xsl:call-template></xsl:variable>
			<h2 class="form-signin-heading"><xsl:value-of select="$text"/></h2>
		</xsl:if>
		<label for="inputUsername" class="sr-only">Username</label>
		<input type="text" id="inputUsername" class="form-control" placeholder="Username" required="required" autofocus="autofocus" onchange="setUsername(this)"/>
		<label for="inputPassword" class="sr-only">Password</label>
		<input type="hidden" id="inputDomainUsername" name="j_username"/>
		<input type="password" id="inputPassword" name="j_password" class="form-control" placeholder="Password" required="required"/>
		<xsl:if test="exists(rdf:Description/html:button[1])">
			<xsl:variable name="text"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description/html:button"/></xsl:call-template></xsl:variable>
			<button class="btn btn-lg btn-primary btn-block" type="submit"><xsl:value-of select="$text"/></button>
		</xsl:if>
	</form>
</xsl:template>

<xsl:template match="rdf:RDF" mode="GraphAppearance">
	<div class="row" style="position: relative">
		<div class="panel panel-primary" style="position:absolute;right:20px;top:50px">
			<div class="panel-heading"><span class="glyphicon glyphicon-off" style="position:absolute;right:5px;margin-top:2px;cursor:pointer" onclick="this.parentNode.parentNode.style.display='none'"/></div>	
			<table style="margin-left:10px">
				<xsl:for-each select="rdf:Description[html:stylesheet!='' and elmo:applies-to!='']">
					<tr>
						<td><input name="{elmo:applies-to}" type="checkbox" checked="checked" onclick="togglenode(this.checked,this.name);"/></td>
						<td><svg style="display: inline;" width="140" height="30"><g><rect x="5" y="5" width="120" height="20" class="s{elmo:applies-to}"/><text x="15" y="18" style="line-height: normal; font-family: sans-serif; font-size: 10px; font-style: normal; font-variant: normal; font-weight: normal; font-size-adjust: none; font-stretch: normal;"><xsl:value-of select="elmo:applies-to"/></text></g></svg></td>
					</tr>
				</xsl:for-each>
			</table>
		</div>
		<div class="panel panel-primary">
			<div id="graphtitle" class="panel-heading"/>
			<div id="graph" class="panel-body"/>
		</div>
	</div>
	<style>
	<!-- Styling for the edge between nodes -->
	.link line.border {
	  stroke: #fff;
	  stroke-opacity: 0;
	  stroke-width: 8px;
	}
	.link line.stroke {
	  pointer-events: none;
	}
	.link text {
	  pointer-events: none;
	}
	<!-- Styling of nodes -->
	.node text {
	  pointer-events: none;
	}
	<!-- Styling of canvas -->
	.canvas {
	  fill: none;
	  pointer-events: all;
	}
	<!-- Default styling (should be part of node or edge??) -->
	.default {
		fill: white;
		fill-opacity: .3;
		stroke: #666;
	}
	<!-- DIV Detailbox -->
	div.detailbox {
		background-color: black;
		border-radius: 5px;
		-moz-border-radius: 5px;
		font-size: 0.8em;
		top: 5px;
		right: 5px;
		width: 300px;
		padding: 5px;
		position: absolute;
	}
	div.detailbox div.header {
		color: white;
		font-weight: bold;
		margin: 0px 0px 5px;
	}
	div.detailbox div.button {
		height: 30px;
		padding: 0px;
	}

	div.detailbox table {
		width:100%;
		background-color:white;
		table-layout: fixed;
		word-wrap:break-word;
	}
	div.detailbox table tr td.data {
		width:80%;
	}

	div.detailbox div.button #expand {
		padding: 5px;
		float: right;
		text-align: right;
		z-index: 5000;
		background-color: #808080;
		border-color: #808080;
		color: white;
		cursor: pointer;
		border-radius: 5px;
		-moz-border-radius: 5px;
		padding-left: 15px;
		text-indent: -10px;
		font-weight: bold;
	}
	<xsl:for-each select="rdf:Description[html:stylesheet!='' and elmo:applies-to!='']">
		.s<xsl:value-of select="elmo:applies-to"/> {
		<xsl:value-of select="html:stylesheet"/>
		}
	</xsl:for-each>
	<xsl:for-each select="rdf:Description[html:stylesheet!='' and elmo:applies-to!='']">
		.t<xsl:value-of select="elmo:applies-to"/> {
			visibility: visible
		}
	</xsl:for-each>
	</style>
	<script type="text/javascript">
		var jsonApiSubject = "<xsl:value-of select="/results/context/subject"/>";
		var jsonApiCall = "<xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource.d3json?representation=<xsl:value-of select="encode-for-uri(@elmo:query)"/>&amp;subject=";
		var uriEndpoint = "<xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource?subject=";
	</script>
	<script src="{$docroot}/js/d3graphs-inner.js" type="text/javascript"/>
</xsl:template>

<!-- Fragment afhandeling -->
<xsl:template match="*[@class='container']">
	<xsl:param name="notitle"/>
	<xsl:if test="exists(*[@class='title']) and not($notitle)"><p class="title"><xsl:value-of select="*[@class='title']"/></p></xsl:if>
	<xsl:choose>
		<xsl:when test="exists(*[@class='marker'])">
			<li>
				<span class="marker"><xsl:value-of select="*[@class='marker']"/></span>
				<xsl:apply-templates select="*[@class='container' or @class='block']"/>
			</li>
		</xsl:when>
		<xsl:when test="exists(*[@class='container']/*[@class='marker'])">
			<ul class="fragment">
				<xsl:apply-templates select="*[@class='container' or @class='block']"/>
			</ul>
		</xsl:when>
		<!-- Hier mist nog een stuk voor de afhandeling van het tonen van tabellen. Dit staat wel in het verouderde stuk: nog overnemen dus! -->
		<xsl:otherwise>
			<xsl:apply-templates select="*[@class='container' or @class='block']"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*[@class='block']">
	<xsl:value-of select="text()"/>
	<xsl:apply-templates select="*[exists(@class)]"/><p class="break" />
</xsl:template>

<xsl:template match="*[@class='inline']">
	<xsl:choose>
		<xsl:when test="@ref!=''"><a href="{$docroot}/resource?subject={encode-for-uri(concat('http://wetten.overheid.nl/',@ref))}"><xsl:value-of select="."/></a></xsl:when>
		<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*[@class='annotation']">
	<i><xsl:text>[</xsl:text><xsl:value-of select="."/><xsl:text>]</xsl:text></i>
</xsl:template>

<xsl:template match="rdf:RDF" mode="TextAppearance">
	<style>
p.title {
	font-weight: bold;
}

tr.title {
	font-weight: bold;
}

p.break {
	margin-bottom: 0.5em;
}

ul.fragment {
	list-style-type: none;
}

table.fragment{
	margin-bottom: 10px;
}

table.fragment tr td{
	padding: 3px;
    border:1px solid #d9d9d9;
}
.marker {
	display:-moz-inline-block; display:-moz-inline-box; display:inline-block; 
	font-weight: bold;
	left: -40px;
	width: 40px;
	margin-right: -40px;
	position: relative;
}
	</style>
	<div class="row">
		<div class="panel panel-primary">
			<div id="graphtitle" class="panel-heading"><xsl:value-of select="xmldocs/xmldoc/document/*[1]/*[@class='title']"/></div>
			<div id="graph" class="panel-body">
				<xsl:for-each select="xmldocs/xmldoc/document">
					<xsl:choose>
						<xsl:when test="exists(*[@class='container']/*[@class='marker'])">
							<ul class="fragment">
								<xsl:apply-templates select="*[@class='container' or @class='block']"/>
							</ul>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="*[@class='container' or @class='block']">
								<xsl:with-param name="notitle">notitle</xsl:with-param>
							</xsl:apply-templates>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</div>
		</div>
	</div>
</xsl:template>

<xsl:template match="rdf:RDF" mode="FormAppearance">
	<script>
var substringMatcher = function(strs) {
  return function findMatches(q, cb) {
    var matches, substrRegex;
 
    // an array that will be populated with substring matches
    matches = [];
 
    // regex used to determine if a string contains the substring `q`
    substrRegex = new RegExp(q, 'i');
 
    // iterate through the pool of strings and for any string that
    // contains the substring `q`, add it to the `matches` array
    $.each(strs, function(i, str) {
      if (substrRegex.test(str)) {
        // the typeahead jQuery plugin expects suggestions to a
        // JavaScript object, refer to typeahead docs for more info
        matches.push({ value: str });
      }
    });
 
    cb(matches);
  };
};
	</script>
	<script>
		<xsl:for-each select="key('rdf',rdf:Description/elmo:valuesFrom/@rdf:resource)">
			<xsl:text>var options</xsl:text><xsl:value-of select="generate-id()"/>
			<xsl:text>= [</xsl:text>
			<xsl:for-each select="rdf:Description/rdfs:label">
				<xsl:if test="position()!=1">,</xsl:if>
				<xsl:text>'</xsl:text>
				<xsl:value-of select="replace(.,'''','\\''')"/>
				<xsl:text>'</xsl:text>
			</xsl:for-each>
			<xsl:text>];</xsl:text>
			<xsl:text>var values</xsl:text><xsl:value-of select="generate-id()"/>
			<xsl:text>= {</xsl:text>
			<xsl:for-each select="rdf:Description">
				<xsl:if test="position()!=1">,</xsl:if>
				<xsl:text>'</xsl:text>
				<xsl:value-of select="replace(rdfs:label[1],'''','\\''')"/>
				<xsl:text>':{uri:'</xsl:text>
				<xsl:value-of select="replace(@rdf:about,'''','\\''')"/>
				<xsl:text>'</xsl:text>
				<xsl:for-each select="*[namespace-uri()='var:']">
					<xsl:text>,</xsl:text>
					<xsl:value-of select="local-name()"/>
					<xsl:text>:'</xsl:text>
					<xsl:value-of select="."/>
					<xsl:text>'</xsl:text>
				</xsl:for-each>
				<xsl:text>}</xsl:text>
			</xsl:for-each>
			<xsl:text>};</xsl:text>
		</xsl:for-each>
	</script>
	<div class="row">
		<div class="panel panel-primary">
			<div class="panel-heading">
				<h3 class="panel-title">
					<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description[1]/rdfs:label"/></xsl:call-template></xsl:variable>
					<xsl:value-of select="$label"/>
				</h3>
			</div>
			<div class="panel-body">
				<form role="form" class="form-horizontal" method="post" action="{/results/context/url}">
					<xsl:if test="exists(rdf:Description/elmo:valueDatatype[@rdf:resource='http://purl.org/dc/dcmitype/Dataset'])">
						<xsl:attribute name="enctype">multipart/form-data</xsl:attribute>
					</xsl:if>
					<xsl:variable name="turtleEditorID" select="rdf:Description[elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#TurtleEditor']/elmo:applies-to"/>
					<xsl:variable name="sparqlEditorID" select="rdf:Description[elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#SparqlEditor']/elmo:applies-to"/>
					<xsl:if test="$turtleEditorID!=''">
						<link rel="stylesheet" href="{$docroot}/css/codemirror.css"/>
						<script src="{$docroot}/js/codemirror.js"/>
						<script src="{$docroot}/js/turtle.js"/>
					</xsl:if>
					<xsl:if test="$sparqlEditorID!=''">
						<link rel="stylesheet" href="{$docroot}/css/codemirror.css"/>
						<link rel="stylesheet" href="{$docroot}/css/yasqe.min.css"/>
						<script src="{$docroot}/js/codemirror.js"/>
						<script src="{$docroot}/js/yasqe.min.js"/>
					</xsl:if>
					<xsl:for-each select="rdf:Description[exists(elmo:applies-to)]"><xsl:sort select="elmo:index"/>
						<xsl:variable name="applies-to" select="elmo:applies-to"/>
						<div class="form-group">
							<label for="{elmo:applies-to}" class="control-label col-sm-2">
								<xsl:if test="exists(elmo:constraint[@rdf:resource='http://bp4mc2.org/elmo/def#OneOfGroupConstraint'])">
									<input type="radio" class="pull-left" id="manselect" name="manselect"/><xsl:text> </xsl:text>
								</xsl:if>
								<xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdfs:label"/></xsl:call-template>
							</label>
							<div class="col-sm-10" id="the-basics">
								<xsl:choose>
									<xsl:when test="elmo:valuesFrom/@rdf:resource!=''">
										<xsl:choose>
											<xsl:when test="count(key('rdf',elmo:valuesFrom/@rdf:resource)/rdf:Description)>2">
												<input type="text" class="form-control typeahead" id="{elmo:applies-to}"/>
												<input type="hidden" id="{elmo:applies-to}-value" name="{elmo:applies-to}"/>
												<xsl:for-each-group select="key('rdf',elmo:valuesFrom/@rdf:resource)/rdf:Description/*[namespace-uri()='var:']" group-by="local-name()">
													<input type="hidden" id="{local-name()}" name="{local-name()}"/>
												</xsl:for-each-group>
											</xsl:when>
											<xsl:otherwise>
												<xsl:variable name="applies" select="elmo:applies-to"/>
												<xsl:variable name="default" select="rdf:value/@rdf:resource"/>
												<xsl:for-each select="key('rdf',elmo:valuesFrom/@rdf:resource)/rdf:Description"><xsl:sort select="@rdf:about"/>
													<label class="radio-inline">
														<input type="radio" id="{$applies}" name="{$applies}" value="{@rdf:about}">
															<xsl:if test="@rdf:about=$default"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
														</input>
														<xsl:value-of select="rdfs:label"/>
													</label>
												</xsl:for-each>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#HiddenAppearance'">
										<input type="hidden" id="{elmo:applies-to}" name="{elmo:applies-to}" value="{rdf:value}"/>
									</xsl:when>
									<xsl:when test="elmo:valueDatatype/@rdf:resource='http://purl.org/dc/dcmitype/Dataset'">
										<input type="file" class="form-control" id="{elmo:applies-to}" name="{elmo:applies-to}"/>
									</xsl:when>
									<xsl:when test="elmo:valueDatatype/@rdf:resource='http://www.w3.org/2001/XMLSchema#Date'">
										<input type="text" class="form-control datepicker" id="{elmo:applies-to}" name="{elmo:applies-to}"/>
									</xsl:when>
									<xsl:when test="elmo:valueDatatype/@rdf:resource='http://www.w3.org/2001/XMLSchema#String'">
										<textarea type="text" class="form-control" id="{elmo:applies-to}" name="{elmo:applies-to}" rows="30">
											<xsl:if test="html:stylesheet!=''"><xsl:attribute name="style"><xsl:value-of select="html:stylesheet"/></xsl:attribute></xsl:if>
											<xsl:value-of select="rdf:value"/>
										</textarea>
									</xsl:when>
									<xsl:otherwise>
										<input type="text" class="form-control" id="{$applies-to}" name="{$applies-to}" value="{/results/context/parameters/parameter[name=$applies-to]/value}"/>
									</xsl:otherwise>
								</xsl:choose>
							</div>
						</div>
					</xsl:for-each>
					<xsl:for-each select="rdf:Description[elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#SubmitAppearance']">
						<div class="form-group">
							<label for="btn{position()}" class="control-label col-sm-2"/>
							<div class="col-sm-10">
								<button id="btn{position()}" type="submit" class="btn btn-primary pull-right"><xsl:value-of select="rdfs:label"/></button>
							</div>
						</div>
					</xsl:for-each>
					<script>$('.datepicker').datepicker({language: '<xsl:value-of select="/results/context/language"/>'});</script>
					<xsl:if test="$turtleEditorID!=''">
						<script>var editor = CodeMirror.fromTextArea(document.getElementById("<xsl:value-of select="$turtleEditorID"/>"), {mode: "text/turtle",matchBrackets: true,lineNumbers:true});</script>
					</xsl:if>
					<xsl:if test="$sparqlEditorID!=''">
						<script>var editor = new YASQE.fromTextArea(document.getElementById("<xsl:value-of select="$sparqlEditorID"/>"), {persistent: null});</script>
					</xsl:if>
				</form>
			</div>
		</div>
	</div>
	<script>
		<xsl:for-each select="rdf:Description[exists(elmo:valuesFrom/@rdf:resource)]">
			<xsl:variable name="id"><xsl:value-of select="elmo:applies-to"/></xsl:variable>
			<xsl:variable name="cnt" select="count(key('rdf',elmo:valuesFrom/@rdf:resource)/rdf:Description)"/>
			<xsl:variable name="var"><xsl:value-of select="key('rdf',elmo:valuesFrom/@rdf:resource)/generate-id()"/></xsl:variable>
			<xsl:if test="$id!='' and $var!='' and $cnt>2">
				$('#<xsl:value-of select="elmo:applies-to"/>').typeahead({
				  hint: true,
				  highlight: true,
				  minLength: 1
				},
				{
				  name: 'vars',
				  displayKey: 'value',
				  source: substringMatcher(options<xsl:value-of select="$var"/>),
				}).bind('typeahead:selected',function(obj,datum) {
					$('#<xsl:value-of select="elmo:applies-to"/>-value').val(values<xsl:value-of select="$var"/>[datum.value].uri);
					<xsl:for-each-group select="key('rdf',elmo:valuesFrom/@rdf:resource)/rdf:Description/*[namespace-uri()='var:']" group-by="local-name()">
						$('#<xsl:value-of select="local-name()"/>').val(values<xsl:value-of select="$var"/>[datum.value].<xsl:value-of select="local-name()"/>);
					</xsl:for-each-group>
				});
			</xsl:if>
		</xsl:for-each>
	</script>
</xsl:template>

<xsl:template match="rdf:RDF" mode="GeoAppearance">
	<xsl:param name="backmap"/>
	<xsl:param name="appearance"/>

	<xsl:if test="exists(rdf:Description/@rdf:about)">

		<xsl:choose>
			<xsl:when test="$backmap='image'">
				<link href="{$docroot}/css/leaflet.css" rel="stylesheet"/>
				<script src="{$docroot}/js/leaflet.js"></script>
				<script src="{$docroot}/js/leaflet.label.js"></script>
				<script src="{$docroot}/js/easy-button.js"></script>
				<!-- Print form -->
				<form id="svgform" method="post" action="{$subdomain}/print-graph" enctype="multipart/form-data">
					<input type="hidden" id="type" name="type" value=""/>
					<input type="hidden" id="data" name="data" value=""/>
					<input type="hidden" id="dimensions" name="dimensions" value=""/>
					<input type="hidden" id="imgsrc" name="imgsrc" value=""/>
				</form>
				<!-- TOT HIER -->
			</xsl:when>
			<xsl:otherwise>
				<link href="{$docroot}/css/leaflet.css" rel="stylesheet"/>
				<script src="{$docroot}/js/leaflet.js"></script>
				<script src="{$docroot}/js/proj4-compressed.js"></script>
				<script src="{$docroot}/js/proj4leaflet.js"></script>
				<!-- Clickable map form -->
				<form id="clickform" method="get" action="">
					<input type="hidden" id="lat" name="lat" value=""/>
					<input type="hidden" id="long" name="long" value=""/>
				</form>
			</xsl:otherwise>
		</xsl:choose>
		<script src="{$docroot}/js/linkeddatamap.js"></script>
		
		<xsl:variable name="latlocator" select="rdf:Description[rdf:type/@rdf:resource='http://bp4mc2.org/elmo/def#GeoLocator'][1]/geo:lat"/>
		<xsl:variable name="latdata">
			<xsl:value-of select="$latlocator"/>
			<xsl:if test="not($latlocator!='')"><xsl:value-of select="rdf:Description[1]/geo:lat"/></xsl:if>
		</xsl:variable>
		<xsl:variable name="lat">
			<xsl:choose>
				<xsl:when test="not($latdata!='') or contains($latdata,'@')">52.155</xsl:when>
				<xsl:otherwise><xsl:value-of select="$latdata"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="longlocator" select="rdf:Description[rdf:type/@rdf:resource='http://bp4mc2.org/elmo/def#GeoLocator'][1]/geo:long"/>
		<xsl:variable name="longdata">
			<xsl:value-of select="$longlocator"/>
			<xsl:if test="not($longlocator!='')"><xsl:value-of select="rdf:Description[1]/geo:long"/></xsl:if>
		</xsl:variable>
		<xsl:variable name="long">
			<xsl:choose>
				<xsl:when test="not($longdata!='') or contains($longdata,'@')">5.38</xsl:when>
				<xsl:otherwise><xsl:value-of select="$longdata"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="doZoom">
			<xsl:choose>
				<xsl:when test="$longdata!=''">0</xsl:when>
				<xsl:otherwise>1</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="htmlimg" select="rdf:Description/html:img"/>
		<xsl:variable name="htmlleft" select="rdf:Description/html:left"/>
		<xsl:variable name="htmltop" select="rdf:Description/html:top"/>
		<xsl:variable name="htmlwidth" select="rdf:Description/html:width"/>
		<xsl:variable name="htmlheight" select="rdf:Description/html:height"/>
		<xsl:variable name="container" select="@elmo:container"/>
		<xsl:variable name="img"><xsl:value-of select="$htmlimg"/><xsl:if test="not($htmlimg!='')">Background.png</xsl:if></xsl:variable>
		<xsl:variable name="left"><xsl:value-of select="$htmlleft"/><xsl:if test="not($htmlleft!='')">0</xsl:if></xsl:variable>
		<xsl:variable name="top"><xsl:value-of select="$htmltop"/><xsl:if test="not($htmltop!='')">0</xsl:if></xsl:variable>
		<xsl:variable name="width"><xsl:value-of select="$htmlwidth"/><xsl:if test="not($htmlwidth!='')">1000</xsl:if></xsl:variable>
		<xsl:variable name="height"><xsl:value-of select="$htmlheight"/><xsl:if test="not($htmlheight!='')">600</xsl:if></xsl:variable>
		
		<div class="row">
			<div class="panel panel-primary">
				<div class="panel-heading"/>
				<div class="panel-body">
					<div id="map"></div>
					<style>
						<xsl:for-each select="rdf:Description[html:stylesheet!='' and elmo:applies-to!='' and elmo:applies-to!='http://bp4mc2.org/elmo/def#Appearance']">
							.s<xsl:value-of select="elmo:applies-to"/> {
							<xsl:value-of select="html:stylesheet"/>
							}
							.shidden-object {
								display:none;
								pointer-events: none;
							}
							.edgestyle {
								stroke: #606060;
								stroke-width: 2px;
								pointer-events: none;
							}
						</xsl:for-each>
						<xsl:choose>
							<xsl:when test="exists(rdf:Description[html:stylesheet!='' and elmo:applies-to='http://bp4mc2.org/elmo/def#Appearance'])">
								.leaflet-container {
									<xsl:value-of select="rdf:Description[elmo:applies-to='http://bp4mc2.org/elmo/def#Appearance']/html:stylesheet[1]"/>
								}
							</xsl:when>
							<xsl:otherwise>
								.leaflet-container {
									height: 500px;
									width: 100%;
								}
							</xsl:otherwise>
						</xsl:choose>
					</style>
					<!-- TODO: width en height moet ergens vandaan komen. Liefst uit plaatje, maar mag ook uit eigenschappen -->
					<script type="text/javascript">
						initMap('<xsl:value-of select="$docroot"/>',<xsl:value-of select="$lat"/>, <xsl:value-of select="$long"/>, '<xsl:value-of select="$backmap"/>', '<xsl:value-of select="$img"/>', '<xsl:value-of select="$container"/>', <xsl:value-of select="$left"/>, <xsl:value-of select="$top"/>, <xsl:value-of select="$width"/>, <xsl:value-of select="$height"/>);
						
						<xsl:for-each select="rdf:Description[geo:lat!='' and geo:long!='' and rdfs:label!='']">
							<xsl:variable name="resource-uri"><xsl:call-template name="resource-uri"><xsl:with-param name="uri" select="@rdf:about"/></xsl:call-template></xsl:variable>
							addPoint(<xsl:value-of select="geo:lat[1]"/>,<xsl:value-of select="geo:long[1]"/>,"<xsl:value-of select="rdfs:label"/>","<xsl:value-of select="$resource-uri"/>");
						</xsl:for-each>
						<xsl:for-each select="rdf:Description[geo:geometry!='']"><xsl:sort select="string-length(geo:geometry[1])" data-type="number" order="descending"/>
							<!-- //<xsl:value-of select="string-length(geo:geometry[1])"/>-<xsl:value-of select="key('resource',elmo:style[1]/@rdf:resource)/elmo:name"/> -->
							<xsl:variable name="link-uri">
								<xsl:choose>
									<xsl:when test="exists(html:link)"><xsl:value-of select="html:link/@rdf:resource"/></xsl:when>
									<xsl:otherwise><xsl:value-of select="@rdf:about"/></xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:variable name="resource-uri">
								<!-- TIJDELIJK -->
								<xsl:choose>
									<xsl:when test="exists(html:link)"><xsl:value-of select="$link-uri"/></xsl:when>
									<xsl:otherwise><xsl:call-template name="resource-uri"><xsl:with-param name="uri" select="$link-uri"/></xsl:call-template></xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:variable name="styleclass">
								<xsl:choose>
									<xsl:when test="elmo:style/@rdf:resource='http://bp4mc2.org/elmo/def#HiddenStyle'">hidden-object</xsl:when>
									<xsl:otherwise><xsl:value-of select="key('resource',elmo:style[1]/@rdf:resource)/elmo:name[1]"/></xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							addWKT('<xsl:value-of select="@rdf:about"/>','<xsl:value-of select="geo:geometry[1]"/>','<xsl:value-of select="rdfs:label[1]"/>','<xsl:value-of select="$resource-uri"/>','s<xsl:value-of select="$styleclass"/>');
						</xsl:for-each>

						<xsl:for-each select="rdf:Description[geo:geometry!='']/(* except (html:link|elmo:style))[exists(@rdf:resource)]">
							addEdge('<xsl:value-of select="../@rdf:about"/>','<xsl:value-of select="name()"/>','<xsl:value-of select="@rdf:resource"/>');
						</xsl:for-each>
						
						showLocations(<xsl:value-of select="$doZoom"/>,'<xsl:value-of select="$appearance"/>');
					</script>
				</div>
			</div>
		</div>
	</xsl:if>
	
</xsl:template>

<xsl:template match="rdf:RDF" mode="ChartAppearance">
	<div class="row">
		<div class="panel panel-primary">
			<div class="panel-heading"/>
			<div id="blub" class="panel-body">
			</div>
		</div>
	</div>
	<style>
		.bar {
		  fill: steelblue;
		}

		.axis text {
		  font: 10px sans-serif;
		}

		.axis path,
		.axis line {
		  fill: none;
		  stroke: #000;
		  shape-rendering: crispEdges;
		}

		.x.axis path {
		  display: none;
		}
	</style>
	<script xmlns:weather="http://elmo.localhost/def/weather#">
		var data=[<xsl:for-each select="rdf:Description"><xsl:if test="position()!=1">,</xsl:if>{name:"<xsl:value-of select="weather:time"/>",value:1+<xsl:value-of select="weather:rain"/>}</xsl:for-each>];

		var margin = {top: 20, right: 30, bottom: 30, left: 40},
			width = 800 - margin.left - margin.right,
			height = 200 - margin.top - margin.bottom;

		var x = d3.scale.ordinal()
			.rangeRoundBands([0, width], .1);

		var y = d3.scale.linear()
			.range([height, 0])

		var xAxis = d3.svg.axis()
			.scale(x)
			.orient("bottom");

		var yAxis = d3.svg.axis()
			.scale(y)
			.orient("left");

		var chart = d3.select("#blub").append("svg")
			.attr("width", width + margin.left + margin.right)
			.attr("height", height + margin.top + margin.bottom)
		  .append("g")
			.attr("transform", "translate(" + margin.left + "," + margin.top + ")");

		x.domain(data.map(function (d) {return d.name;}));
		//y.domain([0,d3.max(data, function (d) {return d.value;})]);
		y.domain([0,256]);
			
		  chart.append("g")
			  .attr("class", "x axis")
			  .attr("transform", "translate(0," + height + ")")
			  .call(xAxis);

		  chart.append("g")
			  .attr("class", "y axis")
			  .call(yAxis);

		  chart.selectAll(".bar")
			  .data(data)
			.enter().append("rect")
			  .attr("class", "bar")
			  .attr("x", function(d) { return x(d.name); })
			  .attr("y", function(d) { return y(d.value); })
			  .attr("height", function(d) { return height - y(d.value); })
			  .attr("width", x.rangeBand());
	</script>
</xsl:template>

<xsl:template match="rdf:Description" mode="makeTree">
	<!-- To avoid cycles, a resource can be present only ones -->
	<xsl:param name="done"/>
	<xsl:variable name="uri" select="@rdf:about"/>
	<xsl:variable name="resource-uri">
		<xsl:call-template name="resource-uri">
			<xsl:with-param name="uri" select="$uri"/>
			<xsl:with-param name="var" select=".."/> <!-- Was rdf:Description, maar dit lijkt beter -->
		</xsl:call-template>
	</xsl:variable>
	<li>
		<a href="{$resource-uri}">
			<xsl:choose>
				<xsl:when test="rdfs:label!=''"><xsl:value-of select="rdfs:label"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="@rdf:about"/></xsl:otherwise>
			</xsl:choose>
			<xsl:call-template name="cross-site-marker">
				<xsl:with-param name="url" select="$resource-uri"/>
			</xsl:call-template>
		</a>
		<xsl:variable name="new">
			<xsl:for-each select="../rdf:Description[*/@rdf:resource=$uri]">
				<xsl:variable name="about" select="@rdf:about"/>
				<xsl:if test="not(exists($done[uri=$about]))">
					<uri><xsl:value-of select="."/></uri>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="exists($new/uri)">
			<ul style="display: none"> <!-- Default: collapsed tree -->
				<xsl:for-each select="../rdf:Description[*/@rdf:resource=$uri]">
					<xsl:variable name="about" select="@rdf:about"/>
					<xsl:if test="not(exists($done[uri=$about]))">
						<xsl:apply-templates select="." mode="makeTree">
							<xsl:with-param name="done">
								<xsl:copy-of select="$done"/>
								<xsl:copy-of select="$new"/>
							</xsl:with-param>
						</xsl:apply-templates>
					</xsl:if>
				</xsl:for-each>
			</ul>
		</xsl:if>
	</li>
</xsl:template>

<xsl:template match="rdf:RDF" mode="TreeAppearance">
	<!--<div class="panel panel-primary">
		<div class="panel-heading"/>
		<div class="panel-body tree">--><div class="tree">
			<ul>
				<xsl:variable name="done">
					<xsl:for-each select="rdf:Description[not(exists(*/@rdf:resource))]/@rdf:about">
						<uri><xsl:value-of select="."/></uri>
					</xsl:for-each>
				</xsl:variable>
				<xsl:apply-templates select="rdf:Description[not(exists(*/@rdf:resource))]" mode="makeTree"><xsl:with-param name="done" select="$done"/></xsl:apply-templates>
			</ul></div><!--
		</div>
	</div>-->
	<link rel="stylesheet" href="{$docroot}/css/treestyle.css"/>
	<script src="{$docroot}/js/MultiNestedList.js"></script>
</xsl:template>

</xsl:stylesheet>