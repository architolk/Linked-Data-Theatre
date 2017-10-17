<!--

    NAME     rdf2html.xsl
    VERSION  1.19.1-SNAPSHOT
    DATE     2017-10-17

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
	Transformation of RDF document to html format. Depends upon rdf2rdfa.xsl
	rdf2html includes the appearances templates within the subdirectory /appearances

	This file contains only the "basic" appearances:
	For content:
	- ContentAppearance: default appearance for CONSTRUCT queries
	- TableAppearance: default appearance for SELECT queries
	- CarouselAppearance: a twist at the ContentAppearance: every resource at a different page
	- ShortTableAppearance: a twist at the TableAppearance, for short tables only
	- TextSearchAppearance: a twist at the TableAppearance, for text searches only
	For navigation
	- HeaderAppearance and FooterAppearance
	- NavbarAppearance and NavbarSearchAppearance
	- IndexAppearance
	Special:
	- HiddenAppearance (an appearance for a representation which content is hidden)

	Other appearances should be placed into a separate file. Please include a <xsl:include> entry at the bottom of this file
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:res="http://www.w3.org/2005/sparql-results#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:html="http://www.w3.org/1999/xhtml/vocab#"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>

<xsl:output method="xml" indent="yes"/>

<xsl:key name="rdf" match="results/rdf:RDF" use="@elmo:query"/>
<xsl:key name="resource" match="results/rdf:RDF/rdf:Description" use="@rdf:about"/>
<xsl:key name="nav-bnode" match="results/rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#NavbarSearchAppearance' or @elmo:appearance='http://bp4mc2.org/elmo/def#NavbarAppearance']/rdf:Description" use="@rdf:nodeID|@rdf:about"/>
<xsl:key name="nav-data" match="results/rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#NavbarSearchAppearance' or @elmo:appearance='http://bp4mc2.org/elmo/def#NavbarAppearance']/rdf:Description" use="elmo:data/@rdf:nodeID|elmo:data/@rdf:resource"/>

<xsl:key name="nested" match="results/rdf:RDF/rdf:Description/*[@elmo:appearance='http://bp4mc2.org/elmo/def#NestedAppearance']/rdf:Description" use="@rdf:about"/>

<xsl:variable name="serverdomain"><xsl:value-of select="substring-before(replace(/results/context/url,'^((http|https)://)',''),'/')"/></xsl:variable>
<xsl:variable name="docroot"><xsl:value-of select="/results/context/@docroot"/></xsl:variable>
<xsl:variable name="staticroot"><xsl:value-of select="/results/context/@staticroot"/></xsl:variable>
<xsl:variable name="subdomain"><xsl:value-of select="/results/context/subdomain"/></xsl:variable>
<xsl:variable name="subject"><xsl:value-of select="/results/context/subject"/></xsl:variable>

<xsl:variable name="language"><xsl:value-of select="/results/context/language"/></xsl:variable>
<xsl:variable name="ldtversion">?version=<xsl:value-of select="/results/context/@version"/></xsl:variable>
<!--
	Helper templates
-->
<xsl:template match="*" mode="predicate">
	<xsl:variable name="predicate">
		<xsl:choose>
			<xsl:when test="@html:meta!='' and @html:meta!='http://www.w3.org/1999/02/22-rdf-syntax-ns#nil'"><xsl:value-of select="@html:meta"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<a href="{$predicate}">
		<xsl:if test="@html:meta='http://www.w3.org/1999/02/22-rdf-syntax-ns#nil'"><xsl:attribute name="onclick">return false;</xsl:attribute></xsl:if>
		<xsl:if test="@elmo:comment!=''"><xsl:attribute name="title"><xsl:value-of select="@elmo:comment"/></xsl:attribute></xsl:if>
		<xsl:choose>
			<xsl:when test="@elmo:label!=''"><xsl:value-of select="@elmo:label"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="local-name()"/></xsl:otherwise>
		</xsl:choose>
	</a>
</xsl:template>

<xsl:template name="normalize-language">
	<xsl:param name="text"/>

	<xsl:choose>
		<xsl:when test="$text[@xml:lang=$language]!=''"><xsl:value-of select="$text[@xml:lang=$language]"/></xsl:when> <!-- First choice: language of browser -->
		<xsl:when test="$text[not(exists(@xml:lang))]!=''"><xsl:value-of select="$text[not(exists(@xml:lang))]"/></xsl:when> <!-- Second choice: no language -->
		<xsl:when test="$text[@xml:lang='nl']!=''"><xsl:value-of select="$text[@xml:lang='nl']"/></xsl:when> <!-- Third choice: dutch -->
		<xsl:when test="$text[@xml:lang='en']!=''"><xsl:value-of select="$text[@xml:lang='en']"/></xsl:when> <!-- Fourth choice: english -->
		<xsl:otherwise><xsl:value-of select="$text[1]"/></xsl:otherwise> <!-- If all fails, the first label -->
	</xsl:choose>
</xsl:template>

<xsl:template name="resource-uri">
	<xsl:param name="uri"/>
	<xsl:param name="var"><none/></xsl:param>
	<xsl:param name="params"/>

	<xsl:variable name="urlpart"><xsl:value-of select="replace($uri,'^((http|https)://)','')"/></xsl:variable>
	<xsl:variable name="domain"><xsl:value-of select="substring-before($urlpart,'/')"/></xsl:variable>
	<xsl:choose>
		<xsl:when test="$var/@elmo:link!=''">
			<xsl:value-of select="$docroot"/>
			<xsl:if test="not(starts-with($var/@elmo:link,'/'))">
				<xsl:value-of select="$subdomain"/>
				<xsl:if test="$docroot!='' or $subdomain!=''">/</xsl:if>
			</xsl:if>
			<xsl:value-of select="$var/@elmo:link"/>
			<xsl:choose>
				<xsl:when test="matches($var/@elmo:link,'\?')">&amp;</xsl:when>
				<xsl:otherwise>?</xsl:otherwise>
			</xsl:choose>
			<xsl:text>subject=</xsl:text>
			<xsl:value-of select="encode-for-uri($uri)"/>
			<xsl:value-of select="$params"/>
		</xsl:when> <!-- Link fragment, so locally derefenceable -->
		<xsl:when test="$var/@elmo:appearance='http://bp4mc2.org/elmo/def#GlobalLink'"><xsl:value-of select="$uri"/></xsl:when> <!-- Global link, so plain uri -->
		<xsl:when test="$urlpart=''"><xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource?subject=<xsl:value-of select="encode-for-uri($uri)"/></xsl:when> <!-- Make non-dereferenceable uri's locally dereferenceable -->
		<xsl:when test="$domain!=$serverdomain"><xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource?subject=<xsl:value-of select="encode-for-uri($uri)"/></xsl:when> <!-- External uri's are treated as non-dereferenceable -->
		<xsl:when test="matches($uri,'#')"><xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource?subject=<xsl:value-of select="encode-for-uri($uri)"/></xsl:when> <!-- Hash uri's are treated as non-dereferenceable (to avoid losing the part after the hash) -->
		<xsl:otherwise><xsl:value-of select="$uri"/></xsl:otherwise> <!--Plain URI -->
	</xsl:choose>
</xsl:template>

<xsl:template name="cross-site-marker">
	<xsl:param name="url"/>

	<xsl:variable name="urlpart"><xsl:value-of select="replace($url,'^((http|https)://)','')"/></xsl:variable>
	<xsl:variable name="domain"><xsl:value-of select="substring-before($urlpart,'/')"/></xsl:variable>

	<xsl:if test="$domain!='' and $domain!=$serverdomain">
		<span class="glyphicon glyphicon-share-alt" aria-hidden="true"/>
	</xsl:if>
</xsl:template>

<xsl:template name="cross-site-target-marker">
	<xsl:param name="url"/>

	<xsl:variable name="urlpart"><xsl:value-of select="replace($url,'^((http|https)://)','')"/></xsl:variable>
	<xsl:variable name="domain"><xsl:value-of select="substring-before($urlpart,'/')"/></xsl:variable>

	<xsl:choose>
		<xsl:when test="$domain!='' and $domain!=$serverdomain">_blank</xsl:when>
		<xsl:otherwise>_self</xsl:otherwise>
	</xsl:choose>
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
			<!-- Tokenizer works for terms separated with spaces. To fix the problem with ',' and '.', spaces are added before the ',' and '.' -->
			<xsl:for-each select="tokenize(replace(replace(concat(' ',.,' '),'(,|\.|:)',' $0'),substring($tokenizer,2,9999),'@@$0@@','i'),'@@')">
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
		<!-- Reference to another resource, nested -->
		<xsl:when test="exists(rdf:Description/@rdf:about) and @elmo:appearance='http://bp4mc2.org/elmo/def#NestedAppearance'">
			<table>
				<xsl:for-each-group select="rdf:Description/*" group-by="name()">
					<xsl:if test="not(@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance')">
						<tr>
							<td><xsl:apply-templates select="." mode="predicate"/></td>
							<td>
								<xsl:for-each select="current-group()">
									<xsl:if test="position()!=1">; </xsl:if>
									<xsl:apply-templates select="." mode="object"/>
								</xsl:for-each>
							</td>
						</tr>
					</xsl:if>
				</xsl:for-each-group>
			</table>
		</xsl:when>
		<!-- Reference to another resource, with a label -->
		<xsl:when test="exists(rdf:Description/@rdf:about)">
			<xsl:variable name="resource-uri">
				<xsl:call-template name="resource-uri">
					<xsl:with-param name="uri" select="rdf:Description/@rdf:about"/>
					<xsl:with-param name="var" select="."/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="target">
				<xsl:call-template name="cross-site-target-marker">
					<xsl:with-param name="url" select="$resource-uri"/>
				</xsl:call-template>
			</xsl:variable>
			<a href="{$resource-uri}">
				<xsl:if test="$target!='_self'"><xsl:attribute name="target"><xsl:value-of select="$target"/></xsl:attribute></xsl:if>
				<xsl:choose>
					<xsl:when test="rdf:Description/rdfs:label!=''"><xsl:value-of select="rdf:Description/rdfs:label"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="rdf:Description/@rdf:about"/></xsl:otherwise>
				</xsl:choose>
				<xsl:call-template name="cross-site-marker">
					<xsl:with-param name="url" select="$resource-uri"/>
				</xsl:call-template>
			</a>
		</xsl:when>
		<!-- Blank node (list) -->
		<xsl:when test="exists(rdf:Description/rdf:first)">
			<xsl:apply-templates select="rdf:Description/rdf:first" mode="object"/>
			<xsl:if test="not(rdf:Description/rdf:rest/@rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#nil')">
				<xsl:text>, </xsl:text>
				<xsl:apply-templates select="rdf:Description/rdf:rest" mode="object"/>
			</xsl:if>
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
		<!-- Markdown -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#MarkdownAppearance'">
			<xsl:variable name="markdown" as="xs:string" select="."/>
			<xsl:variable name="html">&lt;div&gt;<xsl:value-of select="md2html:process($markdown)" xmlns:md2html="com.github.rjeschke.txtmark.Processor"/>&lt;/div&gt;</xsl:variable>
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

<xsl:template match="rdf:Description" mode="PropertyTable">
	<div class="panel panel-primary {../@elmo:name}">
		<div class="panel-heading">
			<h3 class="panel-title">
				<span><xsl:value-of select="../@elmo:label"/></span>
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
												<!-- Nested resources sorteren -->
										<xsl:for-each select="current-group()"><xsl:sort select="rdf:Description/@rdf:about"/>
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
		<xsl:when test="$vars[.=$parname]/@elmo:appearance='http://bp4mc2.org/elmo/def#MarkdownAppearance'">
			<xsl:variable name="markdown" as="xs:string" select="res:value"/>
			<xsl:variable name="html">&lt;div&gt;<xsl:value-of select="md2html:process($markdown)" xmlns:md2html="com.github.rjeschke.txtmark.Processor"/>&lt;/div&gt;</xsl:variable>
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

<!--
	Main entry
-->
<xsl:template match="rdf:RDF" mode="present">
	<xsl:choose>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance'"/> <!-- Hidden, dus niet tonen -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#HeaderAppearance'"/> <!-- Al gedaan -->
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#FooterAppearance'"/> <!-- Al gedaan -->
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
			<xsl:apply-templates select="." mode="GeoAppearance"><xsl:with-param name="backmap"><xsl:value-of select="rdf:Description[elmo:applies-to='http://bp4mc2.org/elmo/def#Appearance']/elmo:backmap[1]"/></xsl:with-param><xsl:with-param name="appearance" select="substring-after(@elmo:appearance,'http://bp4mc2.org/elmo/def#')"/></xsl:apply-templates>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ImageAppearance'">
			<xsl:apply-templates select="." mode="GeoAppearance"><xsl:with-param name="backmap">image</xsl:with-param><xsl:with-param name="appearance">ImageAppearance</xsl:with-param></xsl:apply-templates>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ChartAppearance'">
			<xsl:apply-templates select="." mode="ChartAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#CesiumAppearance'">
			<xsl:apply-templates select="." mode="CesiumAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#VocabularyAppearance'">
			<xsl:apply-templates select="." mode="VocabularyAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#FrameAppearance'">
			<xsl:apply-templates select="." mode="FrameAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#ModelAppearance'">
			<xsl:apply-templates select="." mode="ModelAppearance"/>
		</xsl:when>
		<xsl:when test="@elmo:appearance='http://bp4mc2.org/elmo/def#MarkdownAppearance'">		
			<xsl:apply-templates select="." mode="MarkdownAppearance"/>		
		</xsl:when>
		<xsl:otherwise>
			<!-- No, or an unknown appearance, use the data to select a suitable appearance -->
			<xsl:apply-templates select="." mode="ContentAppearance"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="/">
	<xsl:for-each select="results">
		<html lang="{$language}">
			<xsl:apply-templates select="." mode="html-head"/>
			<body>
				<div id="page">
					<!-- More than one query is possible -->
					<!-- First header appearances -->
					<!-- More than one navbar leads to non-defined behaviour -->
					<xsl:apply-templates select="rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#HeaderAppearance']" mode="HeaderAppearance"/>
					<xsl:apply-templates select="rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#NavbarAppearance']" mode="NavbarSearchAppearance"><xsl:with-param name="search">false</xsl:with-param></xsl:apply-templates>
					<xsl:apply-templates select="rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#NavbarSearchAppearance']" mode="NavbarSearchAppearance"><xsl:with-param name="search">true</xsl:with-param></xsl:apply-templates>
					<!-- Real content -->
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
					<!-- Last footer appearances-->
					<xsl:apply-templates select="rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#FooterAppearance']" mode="FooterAppearance"/>
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
		<title><xsl:value-of select="context/title"/></title>

		<link rel="stylesheet" type="text/css" href="{$staticroot}/css/bootstrap.min.css{$ldtversion}"/>
		<link rel="stylesheet" type="text/css" href="{$staticroot}/css/dataTables.bootstrap.min.css{$ldtversion}"/>
		<link rel="stylesheet" type="text/css" href="{$staticroot}/css/bootstrap-datepicker3.standalone.min.css{$ldtversion}"/>
		<link rel="stylesheet" type="text/css" href="{$staticroot}/css/ldt-theme.min.css{$ldtversion}"/>
		<link rel="stylesheet" type="text/css" href="{$staticroot}/css/font-awesome.min.css{$ldtversion}"/>

		<!-- Alternative styling -->
		<xsl:for-each select="context/stylesheet">
			<link rel="stylesheet" type="text/css" href="{@href}"/>
		</xsl:for-each>

		<!-- TODO: Make this generic (appearances with specific stylesheets) -->
		<xsl:if test="exists(rdf:RDF[@elmo:appearance='http://bp4mc2.org/elmo/def#LoginAppearance'])">
			<link rel="stylesheet" type="text/css" href="{$staticroot}/css/signin.min.css{$ldtversion}"/>
		</xsl:if>

		<script type="text/javascript" src="{$staticroot}/js/jquery-3.1.1.min.js{$ldtversion}"></script>
		<script type="text/javascript" src="{$staticroot}/js/jquery.dataTables.min.js{$ldtversion}"></script>
		<script type="text/javascript" src="{$staticroot}/js/dataTables.bootstrap.min.js{$ldtversion}"></script>
		<script type="text/javascript" src="{$staticroot}/js/bootstrap.min.js{$ldtversion}"></script>
		<script type="text/javascript" src="{$staticroot}/js/bootstrap-datepicker.min.js{$ldtversion}"></script>
		<script type="text/javascript" src="{$staticroot}/js/locales/bootstrap-datepicker.nl.min.js{$ldtversion}"></script>
		<script type="text/javascript" src="{$staticroot}/js/d3.v3.min.js{$ldtversion}"></script>
		<script type="text/javascript" src="{$staticroot}/js/ldt.min.js{$ldtversion}"></script>

		<xsl:apply-templates select="context" mode="datatable-languageset"/>

	</head>
</xsl:template>

<xsl:template match="context" mode="datatable-languageset">
	<script type="text/javascript">
		<xsl:text>var elmo_language = </xsl:text>
		<xsl:choose>
			<xsl:when test="language='nl'">{language:{info:"_START_ tot _END_ van _TOTAL_ resultaten",search:"Filter:",lengthMenu:"Toon _MENU_ rijen",zeroRecords:"Niets gevonden",infoEmpty: "Geen resultaten",paginate:{first:"Eerste",previous:"Vorige",next:"Volgende",last:"Laatste"}},paging:true,searching:true,info:true}</xsl:when>
			<xsl:otherwise>{};</xsl:otherwise>
		</xsl:choose>

	</script>
</xsl:template>

<!--
	Basis appearances
-->
<xsl:template match="rdf:RDF" mode="IndexAppearance">
	<!-- IndexAppearance with dynamic data -->
	<xsl:for-each select="rdf:Description/res:solution[1]">
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
			<xsl:variable name="para1" select="elmo:name"/>
			<xsl:variable name="current" select="/results/context/parameters/parameter[name=$para1]/value[1]"/>
			<xsl:variable name="otherparas"> <!-- pass all parameters to the href, except para1 -->
				<xsl:for-each select="/results/context/parameters/parameter">
					<xsl:if test="name!=$para1">
						&amp;<xsl:value-of select="name"/>=<xsl:value-of select="value"/>
					</xsl:if>
			  </xsl:for-each>
			</xsl:variable>
			<xsl:for-each select="tokenize(rdfs:label,'\|')">
				<xsl:variable name="pos" select="position()"/>
				<li>
					<xsl:if test="$value[$pos]=$current"><xsl:attribute name="class">active</xsl:attribute></xsl:if>
					<a href="{$link}?{$para1}={$value[$pos]}{$otherparas}"><xsl:value-of select="."/></a>
				</li>
			</xsl:for-each>
		</ul>
	</xsl:for-each>
	<!-- IndexAppearance with static data -->
	<xsl:for-each select="rdf:Description[exists(rdfs:label)][1]">
		<ul class="nav nav-tabs">
			<xsl:variable name="value" select="tokenize(rdf:value,'\|')"/>
			<xsl:variable name="link"><xsl:value-of select="html:link"/></xsl:variable>
			<xsl:variable name="reallink">
				<xsl:value-of select="$link"/>
				<xsl:choose>
					<xsl:when test="$link=''">
						<xsl:value-of select="/results/context/url"/>
						<xsl:text>?</xsl:text>
						<xsl:if test="matches(/results/context/url,'/resource$')">subject=<xsl:value-of select="encode-for-uri(/results/context/subject)"/>&amp;</xsl:if>
					</xsl:when>
					<xsl:when test="contains($link,'?')">&amp;</xsl:when>
					<xsl:otherwise>?</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="para1" select="elmo:name"/>
			<xsl:variable name="current" select="/results/context/parameters/parameter[name=$para1]/value[1]"/>
			<xsl:variable name="otherparas"> <!-- pass all parameters to the href, except para1 -->
				<xsl:for-each select="/results/context/parameters/parameter">
					<xsl:if test="name!=$para1">
						&amp;<xsl:value-of select="name"/>=<xsl:value-of select="value"/>
					</xsl:if>
			  </xsl:for-each>
			</xsl:variable>
			<xsl:for-each select="tokenize(rdfs:label,'\|')">
				<xsl:variable name="pos" select="position()"/>
				<li>
					<xsl:if test="$value[$pos]=$current"><xsl:attribute name="class">active</xsl:attribute></xsl:if>
					<a href="{$reallink}{$para1}={$value[$pos]}{$otherparas}"><xsl:value-of select="."/></a>
				</li>
			</xsl:for-each>
		</ul>
	</xsl:for-each>
</xsl:template>

<xsl:template match="rdf:RDF" mode="TableAppearance">
	<xsl:param name="paging"/>
	<!-- Link for other formats -->
	<xsl:variable name="original-link">
		<xsl:value-of select="../context/url"/>
		<xsl:text>?</xsl:text>
		<xsl:for-each select="../context/parameters/parameter">
			<xsl:value-of select="name"/>=<xsl:value-of select="encode-for-uri(value[1])"/>
			<xsl:text>&amp;</xsl:text>
		</xsl:for-each>
		<xsl:text>representation=</xsl:text><xsl:value-of select="encode-for-uri(@elmo:query)"/>
		<xsl:if test="../context/subject!=''">&amp;subject=<xsl:value-of select="encode-for-uri(../context/subject)"/></xsl:if>
		<xsl:text>&amp;format=</xsl:text>
	</xsl:variable>
	<!-- Unique number for this datatable -->		
	<xsl:variable name="table-id" select="@elmo:index"/>
	<!-- A select query will have @rdf:nodeID elements, with id 'rset' -->
	<xsl:for-each select="rdf:Description[@rdf:nodeID='rset']">
		<xsl:if test="$paging='true' or exists(res:solution)">
			<script type="text/javascript">
				$(document).ready(function() {
					elmo_language.paging = <xsl:value-of select="$paging"/>;
					elmo_language.searching = <xsl:value-of select="$paging"/>;
					elmo_language.info = <xsl:value-of select="$paging"/>;
					elmo_language.order = [];
					$('#datatable<xsl:value-of select="$table-id"/>').dataTable(elmo_language);
				} );
			</script>
			<table id="datatable{$table-id}" class="table table-striped table-bordered">
				<thead>
					<tr>
						<xsl:for-each select="res:resultVariable[not(@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance' or matches(.,'[^_]*_(label|details|count|uri)'))]">
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
									<xsl:for-each select="../res:resultVariable[not(@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance' or matches(.,'[^_]*_(label|details|count|uri)'))]">
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
									<xsl:for-each select="../res:resultVariable[not(@elmo:appearance='http://bp4mc2.org/elmo/def#HiddenAppearance' or matches(.,'[^_]*_(label|details|count|uri)'))]">
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
		</xsl:if>
	</xsl:for-each>
	<!-- If it's not a select query, construct the table: a column for a property, and a row for a resource -->
	<xsl:if test="not(exists(rdf:Description[@rdf:nodeID='rset']))">
		<xsl:variable name="columns">
			<xsl:for-each-group select="rdf:Description[exists(@rdf:about)]/*" group-by="local-name()">
				<xsl:variable name="label">
					<xsl:value-of select="@elmo:label"/>
					<xsl:if test="not(@elmo:label!='')"><xsl:value-of select="local-name()"/></xsl:if>
				</xsl:variable>
				<column name="{local-name()}" label="{$label}"/>
			</xsl:for-each-group>
		</xsl:variable>
		<table id="datatable{$table-id}" class="table table-striped table-bordered">
			<thead>
				<tr>
					<xsl:for-each select="$columns/column">
						<th><xsl:value-of select="@label"/></th>
					</xsl:for-each>
				</tr>
			</thead>
			<tbody>
				<xsl:for-each-group select="rdf:Description" group-by="@rdf:about">
					<tr>
						<xsl:variable name="group" select="current-group()"/>
						<xsl:for-each select="$columns/column">
							<xsl:variable name="column" select="@name"/>
							<td><xsl:value-of select="$group/*[local-name()=$column]"/></td>
						</xsl:for-each>
					</tr>
				</xsl:for-each-group>
			</tbody>
		</table>
	</xsl:if>
</xsl:template>

<xsl:template match="rdf:RDF" mode="ContentAppearance">
	<!-- A construct query will have @rdf:about elements -->
	<xsl:if test="exists(rdf:Description/@rdf:about)">
		<xsl:for-each select="rdf:Description">
			<!-- Don't show already nested resources -->
			<xsl:if test="not(exists(key('nested',@rdf:about)))">
				<xsl:apply-templates select="." mode="PropertyTable"/>
			</xsl:if>
		</xsl:for-each>
	</xsl:if>
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

<xsl:template match="rdf:RDF" mode="FooterAppearance">
	<div class="footer bg-primary">
		<div class="container hidden-xs">
			<xsl:for-each select="rdf:Description/elmo:html">
				<xsl:copy-of select="saxon:parse(.)" xmlns:saxon="http://saxon.sf.net/"/>
			</xsl:for-each>
		</div>
	</div>
</xsl:template>

<xsl:template match="rdf:RDF" mode="CarouselAppearance">
	<xsl:choose>
		<xsl:when test="exists(rdf:Description/@rdf:about)">
			<xsl:variable name="carousel-id" select="@elmo:index"/>
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

<xsl:template match="rdf:Description" mode="nav">
	<xsl:if test="exists(rdfs:label)">
		<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdfs:label"/></xsl:call-template></xsl:variable>
		<!-- This sets the menu to the active menu, but is not full proof! -->
		<xsl:variable name="url" select="/results/context/url"/>
		<xsl:variable name="url-domain" select="replace($url,'^([^/]+//[^/]+).*','$1')"/>
		<xsl:variable name="active-child">
			<xsl:for-each select="key('nav-bnode',elmo:data/@rdf:nodeID)">
				<xsl:if test="($url=html:link) or ($url=concat($url-domain,html:link))">a</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="active">
			<xsl:if test="($active-child!='') or ($url=html:link) or ($url=concat($url-domain,html:link))">active</xsl:if>
		</xsl:variable>
		<li class="{$active}">
			<xsl:choose>
				<xsl:when test="exists(elmo:data)">
					<xsl:attribute name="class">dropdown <xsl:value-of select="$active"/></xsl:attribute>
					<a class="dropdown-toggle" role="button" aria-expanded="false" href="#" data-toggle="dropdown"><xsl:value-of select="$label"/><span class="caret"/></a>
					<ul class="dropdown-menu" role="menu">
						<xsl:for-each select="elmo:data"><xsl:sort select="key('nav-bnode',@rdf:nodeID)/elmo:index"/>
							<xsl:apply-templates select="key('nav-bnode',@rdf:nodeID)" mode="nav"/>
						</xsl:for-each>
					</ul>
				</xsl:when>
				<xsl:when test="exists(html:link)">
					<xsl:variable name="link">
						<!-- If a link is a relative link (not absolute and not starting with a slash), prefix with docroot and subdomain -->
						<xsl:if test="not(matches(html:link,'^(/|[a-zA-Z0-9]+:)'))">
							<xsl:if test="$docroot!=''"><xsl:value-of select="$docroot"/></xsl:if>
							<xsl:if test="$subdomain!=''"><xsl:value-of select="$subdomain"/></xsl:if>
							<xsl:text>/</xsl:text>
						</xsl:if>
						<xsl:value-of select="html:link"/>
						<xsl:if test="exists(elmo:subject/@rdf:resource)">?SUBJECT=<xsl:value-of select="encode-for-uri(elmo:subject/@rdf:resource)"/></xsl:if>
					</xsl:variable>
					<a href="{$link}">
						<xsl:value-of select="$label"/>
					</a>
				</xsl:when>
				<xsl:otherwise>
					<a href="#"><xsl:value-of select="$label"/></a>
				</xsl:otherwise>
			</xsl:choose>
		</li>
	</xsl:if>
</xsl:template>

<!-- Find root. Warning: no checks for cycles! -->
<xsl:template match="rdf:Description" mode="findroot">
	<xsl:variable name="parent" select="key('nav-data',concat(@rdf:nodeID,@rdf:about))"/>
	<xsl:choose>
		<xsl:when test="exists($parent)"><xsl:apply-templates select="$parent" mode="findroot"/></xsl:when>
		<xsl:otherwise><xsl:value-of select="@rdf:nodeID"/><xsl:value-of select="@rdf:about"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="rdf:RDF" mode="NavbarSearchAppearance">
	<xsl:param name="search"/>
	
	<nav class="navbar navbar-default">
		<xsl:variable name="rootid"><xsl:apply-templates select="rdf:Description[1]" mode="findroot"/></xsl:variable>
		<xsl:variable name="root" select="key('nav-bnode',$rootid)"/>
		<div class="container">
			<div class="navbar-header">
				<button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
					<span class="sr-only">Toggle navigation</span>
					<span class="icon-bar"></span>
					<span class="icon-bar"></span>
					<span class="icon-bar"></span>
				</button>
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
					<xsl:for-each select="$root/elmo:data"><xsl:sort select="key('nav-bnode',concat(@rdf:nodeID,@rdf:resource))/elmo:index"/>
						<xsl:apply-templates select="key('nav-bnode',concat(@rdf:nodeID,@rdf:resource))" mode="nav"/>
					</xsl:for-each>
				</ul>
				<xsl:if test="$search='true'">
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
				</xsl:if>
			</div>
		</div>
	</nav>
</xsl:template>

<!--
	Included appearances. Should be the same number as the files in the /appearances directory
-->
<xsl:include href="appearances/CesiumAppearance.xsl"/>
<xsl:include href="appearances/ChartAppearance.xsl"/>
<xsl:include href="appearances/FormAppearance.xsl"/>
<xsl:include href="appearances/GeoAppearance.xsl"/>
<xsl:include href="appearances/GraphAppearance.xsl"/>
<xsl:include href="appearances/HtmlAppearance.xsl"/>
<xsl:include href="appearances/LoginAppearance.xsl"/>
<xsl:include href="appearances/TextAppearance.xsl"/>
<xsl:include href="appearances/TreeAppearance.xsl"/>
<xsl:include href="appearances/FrameAppearance.xsl"/>
<xsl:include href="appearances/MarkdownAppearance.xsl"/>
<xsl:include href="appearances/ModelTemplates.xsl"/>
<xsl:include href="appearances/ModelAppearance.xsl"/>
<xsl:include href="appearances/VocabularyAppearance.xsl"/>

</xsl:stylesheet>
