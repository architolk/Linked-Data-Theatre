<!--

    NAME     error2html.xsl
    VERSION  1.18.2-SNAPSHOT
    DATE     2017-10-09

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
  Styles the error page (including page not found, errors and sparql errors)
  
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:variable name="staticroot"><xsl:value-of select="/results/context/@staticroot"/></xsl:variable>
<xsl:variable name="ldtversion">?version=<xsl:value-of select="/results/context/@version"/></xsl:variable>

<xsl:template match="/">

	<xsl:variable name="title">
		<xsl:choose>
			<xsl:when test="results/parameters/error-nr='404'">404 Niet gevonden</xsl:when>
			<xsl:otherwise>
				<xsl:if test="results/parameters/error-nr!=''"><xsl:value-of select="results/parameters/error-nr"/><xsl:text> </xsl:text></xsl:if>
				<xsl:choose>
					<xsl:when test="results/parameters/error-title!=''"><xsl:value-of select="results/parameters/error-title"/></xsl:when>
					<xsl:otherwise>Oeps - er ging iets mis</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<html>
			<head>
			<meta charset="utf-8"/>
			<meta http-equiv="X-UA-Compatible" content="IE=edge" />
			<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
			<title><xsl:value-of select="$title"/></title>

			<link rel="stylesheet" type="text/css" href="{$staticroot}/css/bootstrap.min.css{$ldtversion}"/>
			<link rel="stylesheet" type="text/css" href="{$staticroot}/css/dataTables.bootstrap.min.css{$ldtversion}"/>
			<link rel="stylesheet" type="text/css" href="{$staticroot}/css/ldt-theme.min.css{$ldtversion}"/>

			<!-- Alternatieve stijlen -->
			<xsl:for-each select="results/context/stylesheet">
				<link rel="stylesheet" type="text/css" href="{$staticroot}{@href}"/>
			</xsl:for-each>

			<script type="text/javascript" src="{$staticroot}/js/jquery-3.1.1.min.js{$ldtversion}"></script>
			<script type="text/javascript" src="{$staticroot}/js/jquery.dataTables.min.js{$ldtversion}"></script>
			<script type="text/javascript" src="{$staticroot}/js/dataTables.bootstrap.min.js{$ldtversion}"></script>
			<script type="text/javascript" src="{$staticroot}/js/bootstrap.min.js{$ldtversion}"></script>
			<!-- TODO: This won't work for multi language -->
			<script type="text/javascript" language="javascript" charset="utf-8">
				var elmo_language = {language:{info:"_START_ tot _END_ van _TOTAL_ resultaten",search:"Zoeken:",lengthMenu:"Toon _MENU_ rijen",zeroRecords:"Niets gevonden",infoEmpty: "Geen resultaten",paginate:{first:"Eerste",previous:"Vorige",next:"Volgende",last:"Laatste"}},paging:true,searching:true,info:true}
			</script>
		</head>
		<body>
			<div id="page">
				<div class="content">
					<div class="container hidden-xs">
						<div class="row text-center">
							<img src="{$staticroot}/images/ldt-logo.png"/>
						</div>
					</div>
					<div class="container">
						<div class="row">
							<div class="panel panel-primary">
								<div class="panel-heading">
									<h3 class="panel-title"><xsl:value-of select="$title"/><a href="#" onclick="document.getElementById('errors').className = 'row';">.</a></h3>
								</div>
								<div class="panel-body">
									<xsl:for-each select="results/parameters">
										<xsl:choose>
											<xsl:when test="error-nr='404'">
												<p>Het antwoord op uw verzoek kan niet worden gevonden.</p>
												<a href="#" class="btn btn-default" onclick="window.history.back();">Terug naar de vorige pagina.</a>
											</xsl:when>
											<xsl:otherwise>
												<p>
													<xsl:if test="error/@type!=''">(<xsl:value-of select="error/@type"/>)</xsl:if>
													<xsl:value-of select="error"/>
												</p>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:for-each>
								</div>
							</div>
						</div>
						<xsl:if test="exists(results/exceptions) and results/context/@env='dev'">
							<div class="row" id="errors">
								<script type="text/javascript" charset="utf-8">
									$(document).ready(function() {$('#errortable').dataTable(elmo_language);} );
								</script>
								<table id="errortable" class="table table-striped table-bordered">
									<thead>
										<tr>
											<th>Error type</th>
											<th>Error</th>
										</tr>
									</thead>
									<tbody>
										<xsl:for-each select="results/exceptions/exception">
											<tr>
												<td><xsl:value-of select="type"/></td>
												<td><xsl:value-of select="message"/></td>
											</tr>
										</xsl:for-each>
									</tbody>
								</table>
							</div>
						</xsl:if>
					</div>
				</div>
			</div>
		</body>
	</html>

</xsl:template>

</xsl:stylesheet>