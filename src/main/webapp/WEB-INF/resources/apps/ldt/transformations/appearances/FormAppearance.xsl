<!--

    NAME     FormAppearance.xsl
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
	FormAppearance, add-on of rdf2html.xsl
	
	A FormAppearance creates a form from which a user can enter some parameters. A FormAppearance is used when a certain representation
	requests a parameter and that particular parameter is not present. Most common example is the "advanced search" form.
	
	The FormAppearance is also used for the SPARQL editor and the simple container (with a turtle entry-form)
	
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

<xsl:template match="rdf:RDF" mode="FormAppearance">
	<script type="text/javascript" src="{$staticroot}/js/chosen.jquery.min.js"></script>
	<link rel="stylesheet" type="text/css" href="{$staticroot}/css/bootstrap-chosen.css"/>
	<div class="panel panel-primary">
		<div class="panel-heading">
			<h3 class="panel-title">
				<xsl:variable name="label"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdf:Description[1]/rdfs:label"/></xsl:call-template></xsl:variable>
				<xsl:value-of select="$label"/>
			</h3>
		</div>
		<div class="panel-body">
			<xsl:variable name="turtleEditorID" select="rdf:Description[elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#TurtleEditor']/elmo:applies-to"/>
			<xsl:variable name="sparqlEditorID" select="rdf:Description[elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#SparqlEditor']/elmo:applies-to"/>
			<xsl:variable name="alt-action" select="rdf:Description[elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#SubmitAppearance']/html:link"/>
			<xsl:variable name="action">
				<xsl:value-of select="$alt-action"/>
				<xsl:if test="not($alt-action!='')"><xsl:value-of select="replace(/results/context/url,'^[a-z]+://[^/]+','')"/></xsl:if>
			</xsl:variable>
			<form class="form-horizontal" method="post" action="{$action}">
				<xsl:if test="exists(rdf:Description/elmo:valueDatatype[@rdf:resource='http://purl.org/dc/dcmitype/Dataset'])">
					<xsl:attribute name="enctype">multipart/form-data</xsl:attribute>
				</xsl:if>
				<xsl:if test="$turtleEditorID!=''">
					<link rel="stylesheet" href="{$staticroot}/css/codemirror.min.css"/>
					<script src="{$staticroot}/js/codemirror.js"/>
					<script src="{$staticroot}/js/turtle.js"/>
				</xsl:if>
				<xsl:if test="$sparqlEditorID!=''">
					<link rel="stylesheet" href="{$staticroot}/css/codemirror.min.css"/>
					<link rel="stylesheet" href="{$staticroot}/css/yasqe.min.css"/>
					<script src="{$staticroot}/js/codemirror.js"/>
					<script src="{$staticroot}/js/yasqe.min.js"/>
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
						<div class="col-sm-10">
							<xsl:choose>
								<xsl:when test="elmo:valuesFrom/@rdf:resource!=''">
									<xsl:variable name="applies" select="elmo:applies-to"/>
									<xsl:variable name="param" select="/results/context/parameters/parameter[name=$applies]/value[1]"/>
									<xsl:variable name="default">
										<xsl:if test="not($param!='')"><xsl:value-of select="rdf:value/@rdf:resource"/></xsl:if>
									</xsl:variable>
									<xsl:variable name="paramlabel" select="/results/context/parameters/parameter[name=concat($applies,'_label')]/value[1]"/>
									<xsl:variable name="selcount" select="count(key('rdf',elmo:valuesFrom/@rdf:resource)/rdf:Description)"/>
									<xsl:variable name="paramquery">
										<xsl:for-each select="/results/context/parameters/parameter[name!=$applies and not(ends-with(name,'_label'))]">&amp;<xsl:value-of select="name"/>=<xsl:value-of select="encode-for-uri(value[1])"/></xsl:for-each>
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="$selcount=0">
											<script src="{$staticroot}/js/chosen.ajax.min.js" type="text/javascript"/>
											<div class="input-group" style="width:100%;">
												<input type="hidden" id="{$applies}_label" name="{$applies}_label" value="{$paramlabel}"/>
												<select data-placeholder="Select..." class="chosen-select" multiple="multiple" id="{$applies}" name="{$applies}" onchange="$('#{$applies}_label').val($('option:selected',this).text());">
													<xsl:if test="$param!=''"><option value="{$param}" selected="selected"><xsl:value-of select="$paramlabel"/></option></xsl:if>
												</select>
												<script>$('#<xsl:value-of select="$applies"/>').chosen({max_selected_options: 1});</script>
												<script>$("#<xsl:value-of select="$applies"/>").ajaxChosen({type:'GET',jsonTermKey:'<xsl:value-of select="$applies"/>',url:'<xsl:value-of select="$docroot"/><xsl:value-of select="$subdomain"/>/resource.plainjson?representation=<xsl:value-of select="encode-for-uri(elmo:valuesFrom/@rdf:resource)"/><xsl:value-of select="$paramquery"/>',dataType:'json'});</script>
											</div>
										</xsl:when>
										<xsl:when test="$selcount>2">
											<div class="input-group" style="width:100%;">
												<input type="hidden" id="{$applies}_label" name="{$applies}_label" value="{$paramlabel}"/>
												<select data-placeholder="Select..." class="chosen-select" multiple="multiple" id="{$applies}" name="{$applies}">
													<xsl:attribute name="onchange">$('#<xsl:value-of select="$applies"/>_label').val($('option:selected',this).text());
														<xsl:if test="exists(elmo:value-to)">
															<xsl:choose>
																<xsl:when test="elmo:value-to=$sparqlEditorID">if(this.selectedIndex!=-1) {editor.setValue($('option:selected',this).attr('data-rdfvalue'))};</xsl:when>
																<xsl:otherwise>if(this.selectedIndex!=-1) {$('#<xsl:value-of select="elmo:value-to"/>').val($('option:selected',this).attr('data-rdfvalue'))};</xsl:otherwise>
															</xsl:choose>
														</xsl:if>
													</xsl:attribute>
													<xsl:for-each select="key('rdf',elmo:valuesFrom/@rdf:resource)/rdf:Description"><xsl:sort select="rdfs:label[1]"/>
														<option value="{@rdf:about}" data-rdfvalue="{rdf:value}">
															<xsl:if test="$param=@rdf:about or @rdf:about=$default"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
															<xsl:value-of select="rdfs:label"/>
														</option>
													</xsl:for-each>
												</select>
												<script>$('#<xsl:value-of select="$applies"/>').chosen({max_selected_options: 1});</script>
											</div>
										</xsl:when>
										<xsl:otherwise>
											<xsl:for-each select="key('rdf',elmo:valuesFrom/@rdf:resource)/rdf:Description"><xsl:sort select="rdfs:label[1]"/>
												<label class="radio-inline">
													<input type="radio" id="{$applies}" name="{$applies}" value="{@rdf:about}">
														<xsl:if test="@rdf:about=$param or @rdf:about=$default"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
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
								<xsl:when test="elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#ReadOnly'">
									<span class="btn btn-default"><xsl:value-of select="rdf:value"/></span>
								</xsl:when>
								<xsl:when test="elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#Message'">
									<div class="alert alert-danger"><xsl:value-of select="rdf:value"/></div>
								</xsl:when>
								<xsl:when test="elmo:valueDatatype/@rdf:resource='http://purl.org/dc/dcmitype/Dataset'">
									<input type="file" class="form-control" id="{elmo:applies-to}" name="{elmo:applies-to}"/>
								</xsl:when>
								<xsl:when test="elmo:valueDatatype/@rdf:resource='http://www.w3.org/2001/XMLSchema#Date'">
									<input type="text" class="form-control datepicker" id="{elmo:applies-to}" name="{elmo:applies-to}">
										<xsl:if test="rdf:value/@rdf:resource='http://bp4mc2.org/elmo/def#Now'">
											<xsl:attribute name="value"><xsl:value-of select="substring-before(/results/context/timestamp,'T')"/></xsl:attribute>
										</xsl:if>
									</input>
								</xsl:when>
								<xsl:when test="elmo:valueDatatype/@rdf:resource='http://www.w3.org/2001/XMLSchema#String'">
									<textarea type="text" class="form-control" id="{elmo:applies-to}" name="{elmo:applies-to}" rows="30">
										<xsl:if test="html:stylesheet!=''"><xsl:attribute name="style"><xsl:value-of select="html:stylesheet"/></xsl:attribute></xsl:if>
										<xsl:value-of select="rdf:value"/>
									</textarea>
								</xsl:when>
								<xsl:otherwise>
									<input type="text" class="form-control" id="{$applies-to}" name="{$applies-to}" value="{/results/context/parameters/parameter[name=$applies-to]/value[1]}">
										<xsl:if test="elmo:valuePattern[1]!=''"><xsl:attribute name="pattern"><xsl:value-of select="elmo:valuePattern[1]"/></xsl:attribute></xsl:if>
										<xsl:if test="elmo:valueHint[1]!=''"><xsl:attribute name="title"><xsl:value-of select="elmo:valueHint[1]"/></xsl:attribute></xsl:if>
									</input>
								</xsl:otherwise>
							</xsl:choose>
						</div>
					</div>
				</xsl:for-each>
				<xsl:for-each select="rdf:Description[elmo:appearance/@rdf:resource='http://bp4mc2.org/elmo/def#SubmitAppearance']">
					<div class="form-group">
						<xsl:variable name="blabel"><xsl:call-template name="normalize-language"><xsl:with-param name="text" select="rdfs:label"/></xsl:call-template></xsl:variable>
						<label for="btn{position()}" class="control-label col-sm-2"/>
						<div class="col-sm-10">
							<button id="btn{position()}" type="submit" class="btn btn-primary pull-right"><xsl:value-of select="$blabel"/></button>
						</div>
					</div>
				</xsl:for-each>
				<script>$('.datepicker').datepicker({format: 'yyyy-mm-dd', todayHighlight: true, autoclose: true, language: '<xsl:value-of select="/results/context/language"/>'});</script>
				<xsl:if test="$turtleEditorID!=''">
					<script>var editor = CodeMirror.fromTextArea(document.getElementById("<xsl:value-of select="$turtleEditorID"/>"), {mode: "text/turtle",matchBrackets: true,lineNumbers:true});</script>
				</xsl:if>
				<xsl:if test="$sparqlEditorID!=''">
					<script>var editor = new YASQE.fromTextArea(document.getElementById("<xsl:value-of select="$sparqlEditorID"/>"), {persistent: null});</script>
				</xsl:if>
			</form>
		</div>
	</div>
</xsl:template>

</xsl:stylesheet>