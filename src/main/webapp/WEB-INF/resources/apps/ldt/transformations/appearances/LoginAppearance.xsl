<!--

    NAME     LoginAppearance.xsl
    VERSION  1.19.0
    DATE     2017-10-16

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
	LoginAppearance, add-on of rdf2html.xsl
	
	The Login appearance is used whenever a user has to enter his/her credentials (as part of a form-based authentication).
	
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

</xsl:stylesheet>