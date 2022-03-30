<!--

    NAME     FBMTranslator.xsl
    VERSION  1.25.3-SNAPSHOT
    DATE     2020-11-25

    Copyright 2012-2020

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
	xmlns:MM_ModelPackage="http://www.bizzdesign.com/metamodels/MM_ModelPackage"
>

	<xsl:template match="/">
		<rdf:RDF>
			<xsl:apply-templates select="MM_Document/MM_StorageUnit/MM_ModelPackage:MM_ModelPackage/MM_ModelPackage:MM_Models/UML:UMLMM_Model" mode="parse"/>
		</rdf:RDF>
	</xsl:template>

</xsl:stylesheet>
