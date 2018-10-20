<!--

    NAME     TreeAppearance.xsl
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
	TreeAppearance, add-on of rdf2html.xsl

	A TreeAppearance shows triples as a hierarchical tree, at the left side of the screen.

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
	<xsl:variable name="new">
		<xsl:for-each select="../rdf:Description[*/@rdf:resource=$uri]">
			<xsl:variable name="about" select="@rdf:about"/>
			<xsl:if test="not(exists($done[uri=$about]))">
				<uri><xsl:value-of select="."/></uri>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>
	<li>
		<xsl:if test="exists($new/uri)"><xsl:attribute name="class">has-child tree-collapsed</xsl:attribute></xsl:if>
		<p>
			<a href="{$resource-uri}">
				<xsl:choose>
					<xsl:when test="rdfs:label!=''"><xsl:value-of select="rdfs:label"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="@rdf:about"/></xsl:otherwise>
				</xsl:choose>
				<xsl:call-template name="cross-site-marker">
					<xsl:with-param name="url" select="$resource-uri"/>
				</xsl:call-template>
				<xsl:if test="rdf:value!=''">
					<xsl:text> </xsl:text><span class="badge"><xsl:value-of select="rdf:value"/></span>
				</xsl:if>
			</a>
		</p>
		<xsl:if test="exists($new/uri)">
			<a class="" href="#" onclick="toggleNode(this);return false;"><i class="fa fa-plus-square"></i></a>
			<ul class="hide"> <!-- Default: collapsed tree -->
				<xsl:for-each select="../rdf:Description[*/@rdf:resource=$uri]"><xsl:sort select="@rdf:about"/>
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
	<div class="nav-tree">
		<ul>
			<xsl:variable name="done">
				<xsl:for-each select="rdf:Description[not(exists(*/@rdf:resource))]/@rdf:about">
					<uri><xsl:value-of select="."/></uri>
				</xsl:for-each>
			</xsl:variable>
			<xsl:apply-templates select="rdf:Description[not(exists(*/@rdf:resource))]" mode="makeTree"><xsl:with-param name="done" select="$done"/></xsl:apply-templates>
		</ul>
	</div>
	<script>
		$(document).ready(function() {
			var url = '<xsl:value-of select= "/results/context/subject"/>';
			initTree($(".nav-tree"), url);
		});

		function initTree(tree, subject) {
			searchChild(tree[0].children[0].children, subject);
		}

		function searchChild(children, subject) {
			jQuery.each(children, function(index, item) {
			if(decodeURIComponent(item.href) == subject &amp;&amp; item.localName == 'a' ) {
				item.className="active";
				openParentNode(item);
			}
				if(item.children.length != 0) {
					searchChild(item.children, subject);
				}
			});
		}

		function openParentNode(node) {
				if(node.parentElement != null) {
					if(node.parentElement.localName == 'li') {
						node.parentElement.className='has-child';
					} else if(node.parentElement.localName == 'ul') {
						node.parentElement.className='';
						toggle(node.parentElement.parentElement);
					}
					openParentNode(node.parentElement);
				}
			}

			function toggle(node) {
				if(node.localName == 'li') {
					if(node.children.length >= 2) {
						if(node.children[1].localName == 'a') {
							node.children[1].children[0].className='fa fa-minus-square';
						}
					}
				}
			}

		function toggleNode(node) {
			if (node.parentElement.children[2].className!='') {
				node.children[0].className='fa fa-minus-square';
				node.parentElement.className='has-child';
				node.parentElement.children[2].className=''
			} else {
				node.children[0].className='fa fa-plus-square';
				node.parentElement.className='has-child tree-collapsed';
				node.parentElement.children[2].className='hide'
			}
		};
	</script>
</xsl:template>

</xsl:stylesheet>
