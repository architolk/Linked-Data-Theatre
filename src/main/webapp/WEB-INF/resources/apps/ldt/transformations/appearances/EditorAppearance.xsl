<!--

    NAME     EditorAppearance.xsl
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
	EditorAppearance, add-on of rdf2html.xsl

	An editor appearance shows the data as a editable table respresentation.
	Every row represents one unique subject. Every column represents one unique predicate. Every cell represents a triple.
	Currently, multiple values for a unique subject/predicate combination are not supported.

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

<xsl:template match="rdf:RDF" mode="EditorAppearance">
	<xsl:variable name="container" select="@elmo:container"/>
	<link rel="stylesheet" href="{$staticroot}/css/slick.grid.pkg.min.css" type="text/css"/> 
	<link rel="stylesheet" href="{$staticroot}/css/slickgrid-ldt.min.css" type="text/css"/> 
	<xsl:if test="$container!=''">
		<xsl:for-each select="rdf:Description[exists(@rdf:nodeID) and (elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#SubmitAppearance' or elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#ChangeSubmitAppearance')]">
			<div class="form-group">
				<xsl:variable name="submitaction">
					<xsl:choose>
						<xsl:when test="elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#ChangeSubmitAppearance'">saveChangedGrid</xsl:when>
						<xsl:otherwise>saveGrid</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="blabel"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdfs:label"/></xsl:call-template></xsl:variable>
				<label for="btn{position()}" class="control-label col-sm-2"/>
				<div class="col-sm-10">
					<button id="btn{position()}" type="submit" class="btn btn-primary pull-right" onClick="{$submitaction}(); return false;"><xsl:value-of select="$blabel"/></button>
				</div>
			</div>
		</xsl:for-each>
		<xsl:if test="not(exists(rdf:Description[exists(@rdf:nodeID) and (elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#SubmitAppearance' or elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#ChangeSubmitAppearance')]))">
			<div class="form-group">
				<label for="btn-save" class="control-label col-sm-2"/>
				<div class="col-sm-10">
					<button id="btn-save" type="submit" class="btn btn-primary pull-right" onClick="saveGrid(); return false;">Save</button>
				</div>
			</div>
		</xsl:if>
	</xsl:if>
    <div id="myGrid" style="width:100%;height:500px;"></div>
	<script src="{$staticroot}/js/uuid.min.js"></script>
	<script src="{$staticroot}/js/slick.grid.pkg.min.js"></script>
	<script src="{$staticroot}/js/slick.ldt-remotemodel.min.js"></script>
	<script>
		var staticroot = "<xsl:value-of select="$staticroot"/>";
		var containerurl = "<xsl:value-of select="$container"/>";
		var subjecturi = "<xsl:value-of select="/results/context/subject"/>";
		//var apicall = "<xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource.json?representation=<xsl:value-of select="encode-for-uri(@elmo:query)"/>&amp;subject=<xsl:value-of select="/results/context/subject"/>";
		var apicall = "<xsl:value-of select="/results/context/request-path"/>";
		var defaultItem = {
			<xsl:for-each select="rdf:Description[exists(rdf:value)]">
				<xsl:if test="position()!=1">,</xsl:if>
				"<xsl:value-of select="elmo:applies-to"/>": "<xsl:value-of select="rdf:value"/><xsl:value-of select="rdf:value/@rdf:resource"/>"
			</xsl:for-each>
		}
		var templateItem = {
			<xsl:for-each select="rdf:Description[exists(elmo:valueTemplate)]">
				<xsl:if test="position()!=1">,</xsl:if>
				"<xsl:value-of select="elmo:applies-to"/>": "<xsl:value-of select="elmo:valueTemplate"/>"
			</xsl:for-each>
		}
		var fragments = {
			<xsl:for-each select="rdf:Description[exists(elmo:name)]">
				<xsl:if test="position()!=1">,</xsl:if>
				"<xsl:value-of select="elmo:name"/>": "<xsl:value-of select="elmo:applies-to"/>"
			</xsl:for-each>
		}
		var context = {
          graph: '@graph',
          id: '@id',
		  'http://www.w3.org/1999/02/22-rdf-syntax-ns#type': {'@type':'@id'}
		  <xsl:for-each select="rdf:Description[elmo:valueDatatype/@rdf:resource='http://www.w3.org/2000/01/rdf-schema#Resource']">
		  ,'<xsl:value-of select="elmo:applies-to"/>': {'@type':'@id'}
		  </xsl:for-each>
		}
		var columns = [
			{
				id: "#",
				name: "",
				field: "#",
				width: 20,
				selectable: false,
				resizable: false,
				behaviour: "selectAndMove",
				cssClass: "cell-reorder dnd",
				cannotTriggerInsert: true,
				focusable: false,
				formatter: statusFormatter
			}
		<xsl:for-each select="rdf:Description[not(elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#SubmitAppearance' or elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#ChangeSubmitAppearance')]"><xsl:sort select="elmo:index"/>
			<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdfs:label"/></xsl:call-template></xsl:variable>
			<xsl:variable name="editor">
				<xsl:choose>
					<xsl:when test="elmo:valueDatatype/@rdf:resource='http://www.w3.org/2001/XMLSchema#String'">Slick.Editors.LongText</xsl:when>
					<xsl:otherwise>Slick.Editors.Text</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			,{width: 200, id: "<xsl:value-of select="@rdf:nodeID"/>", name: "<xsl:value-of select="$label"/>", field: "<xsl:value-of select="elmo:applies-to"/>", editor: <xsl:value-of select="$editor"/>}
		</xsl:for-each>
		];
	</script>
	<script src="{$staticroot}/js/slick.ldt-grid.min.js"></script>
</xsl:template>

</xsl:stylesheet>
