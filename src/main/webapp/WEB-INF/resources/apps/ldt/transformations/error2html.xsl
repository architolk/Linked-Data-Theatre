<!--

    NAME     error2html.xsl
    VERSION  1.5.0
    DATE     2016-01-05

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

<xsl:template match="/">

	<html>
		<header>
			<title>Error</title>
		</header>
		<body>
			<table>
				<thead>
					<tr>
						<th>Error type</th>
						<th>Error</th>
					</tr>
				</thead>
				<tbody>
					<xsl:for-each select="results/parameters">
						<tr>
							<td><xsl:value-of select="error/@type"/></td>
							<td><xsl:value-of select="error"/></td>
						</tr>
					</xsl:for-each>
					<xsl:for-each select="results/exceptions/exception">
						<tr>
							<td><xsl:value-of select="type"/></td>
							<td><xsl:value-of select="message"/></td>
						</tr>
					</xsl:for-each>
				</tbody>
			</table>
		</body>
	</html>

</xsl:template>

</xsl:stylesheet>