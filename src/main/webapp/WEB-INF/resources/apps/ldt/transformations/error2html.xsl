<!--

    NAME     error2html.xsl
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
  Styles the error page (including page not found, errors and sparql errors)
  
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- Doesn't work - need to include real docroot! -->
<xsl:variable name="docroot"><xsl:value-of select="/results/context/@docroot"/></xsl:variable>

<xsl:template match="/">

	<html>
			<head>
			<meta charset="utf-8"/>
			<meta http-equiv="X-UA-Compatible" content="IE=edge" />
			<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
			<title>Oeps - er ging iets mis</title>

			<link rel="stylesheet" type="text/css" href="{$docroot}/css/bootstrap.min.css"/>
			<link rel="stylesheet" type="text/css" href="{$docroot}/css/dataTables.bootstrap.min.css"/>
			<link rel="stylesheet" type="text/css" href="{$docroot}/css/ldt-theme.css"/>
			<script type="text/javascript" language="javascript" src="{$docroot}/js/jquery-1.11.3.min.js"></script>
			<script type="text/javascript" language="javascript" src="{$docroot}/js/jquery.dataTables.min.js"></script>
			<script type="text/javascript" language="javascript" src="{$docroot}/js/dataTables.bootstrap.min.js"></script>
			<script type="text/javascript" language="javascript" src="{$docroot}/js/bootstrap.min.js"></script>
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
							<img src="{$docroot}/images/ldt-logo.png"/>
						</div>
					</div>
					<div class="container">
						<div class="row">
							<div class="panel panel-primary">
								<div class="panel-heading">
									<h3 class="panel-title">Oeps - er ging iets mis</h3>
								</div>
								<div class="panel-body">
									<xsl:for-each select="results/parameters">
										<p>
											<xsl:if test="error/@type!=''">(<xsl:value-of select="error/@type"/>)</xsl:if>
											<xsl:value-of select="error"/>
										</p>
									</xsl:for-each>
								</div>
							</div>
						</div>
						<xsl:variable name="divclass">
							<xsl:choose>
								<xsl:when test="results/theatre/@env='dev'">row</xsl:when>
								<xsl:otherwise>row hidden</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<div class="{$divclass}">
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
					</div>
				</div>
			</div>
		</body>
	</html>

</xsl:template>

</xsl:stylesheet>