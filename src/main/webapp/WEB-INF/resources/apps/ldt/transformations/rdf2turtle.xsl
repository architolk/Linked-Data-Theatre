<!--

    NAME     rdf2turtle.xsl
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
	Transformation of RDF document to turtle format

	Used by TurtleAppearance.xsl and rdf2ttl.xsl

-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"

	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="fn"
	exclude-result-prefixes="xs fn"
>

<xsl:variable name="rdf2turtle-spaces">. .</xsl:variable>

<xsl:function name="fn:rdf2turtle-spaces" as="xs:string">
	<xsl:param name="tab" as="xs:integer"/>
	<xsl:variable name="result">
		<xsl:for-each select="2 to $tab"><xsl:value-of select="substring($rdf2turtle-spaces,2,1)"/></xsl:for-each>
	</xsl:variable>
	<xsl:value-of select="$result"/>
</xsl:function>

<xsl:template match="rdf:RDF" mode="rdf2turtle-getprefixes">
	<!-- Default prefixes -->
	<prefix name="xsd">http://www.w3.org/2001/XMLSchema#</prefix>
	<!-- Prefixes used in properties -->
	<xsl:for-each-group select="*/*" group-by="substring-before(name(),':')">
		<xsl:variable name="prefix" select="substring-before(name(),':')"/>
		<xsl:choose>
			<xsl:when test="$prefix!=''"><prefix name="{substring-before(name(),':')}"><xsl:value-of select="namespace-uri()"/></prefix></xsl:when>
			<xsl:otherwise>
				<xsl:for-each-group select="current-group()" group-by="namespace-uri()">
					<xsl:if test="namespace-uri()!=''">
						<prefix name="ns{position()}"><xsl:value-of select="namespace-uri()"/></prefix>
					</xsl:if>
				</xsl:for-each-group>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:for-each-group>
	<!-- Prefixes used in subject position -->
	<xsl:for-each-group select="*[exists(@rdf:about)]" group-by="replace(@rdf:about,'(/|#|\\)([0-9A-Za-z-_~]+)$','$1')"><xsl:sort select="replace(@rdf:about,'(/|#|\\)([0-9A-Za-z-_~]+)$','$1')" order="descending"/>
		<xsl:variable name="prefix" select="replace(@rdf:about,'(/|#|\\)([0-9A-Za-z-_~]+)$','$1')"/>
		<xsl:if test="$prefix!='' and substring-after(@rdf:about,$prefix)!=''">
			<prefix name="n{position()}"><xsl:value-of select="$prefix"/></prefix>
		</xsl:if>
	</xsl:for-each-group>
</xsl:template>

<xsl:template match="@rdf:about|@rdf:resource" mode="rdf2turtle-uri"><xsl:param name="prefix" as="node()"/>
	<xsl:variable name="fulluri" select="."/>
	<xsl:variable name="uriprefix" select="$prefix/prefix[substring-after($fulluri,.)!=''][1]"/>
	<xsl:variable name="localname"><xsl:value-of select="substring-after($fulluri,$uriprefix)"/></xsl:variable>
	<xsl:choose>
		<xsl:when test="$uriprefix/@name!='' and matches($localname,'^[0-9A-Za-z-_~.]+$')">
			<xsl:value-of select="$uriprefix/@name"/>:<xsl:value-of select="$localname"/>
		</xsl:when>
		<xsl:otherwise>&lt;<xsl:value-of select="."/>></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="rdf2turtle-property"><xsl:param name="prefix" as="node()"/>
	<xsl:choose>
		<xsl:when test="contains(name(),':') or namespace-uri()=''"><xsl:value-of select="name()"/></xsl:when>
		<xsl:otherwise>
			<xsl:variable name="ns" select="namespace-uri()"/>
			<xsl:value-of select="$prefix/prefix[.=$ns]/@name"/>:<xsl:value-of select="name()"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="rdf2turtle-literalvalue">
	<xsl:value-of select="replace(.,'\\','\\\\')"/>
</xsl:template>

<xsl:template match="*" mode="rdf2turtle-literal">
	<xsl:choose>
		<xsl:when test="contains(.,'&#10;') or contains(.,'&quot;')">'''<xsl:apply-templates select="." mode="rdf2turtle-literalvalue"/>'''<xsl:apply-templates select="." mode="rdf2turtle-datatype"/></xsl:when>
		<xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#integer'"><xsl:apply-templates select="." mode="rdf2turtle-literalvalue"/></xsl:when>
		<xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#decimal'"><xsl:apply-templates select="." mode="rdf2turtle-literalvalue"/></xsl:when>
		<xsl:when test="@rdf:datatype='http://www.w3.org/2001/XMLSchema#boolean'"><xsl:apply-templates select="." mode="rdf2turtle-literalvalue"/></xsl:when>
		<xsl:otherwise>"<xsl:apply-templates select="." mode="literalvalue"/>"<xsl:apply-templates select="." mode="rdf2turtle-datatype"/></xsl:otherwise>
	</xsl:choose>
	<xsl:if test="not(@rdf:datatype!='') and @xml:lang!=''">@<xsl:value-of select="@xml:lang"/></xsl:if>
</xsl:template>

<xsl:template match="*" mode="rdf2turtle-datatype">
	<xsl:if test="@rdf:datatype!=''">
		<xsl:text>^^</xsl:text>
		<xsl:choose>
			<xsl:when test="matches(@rdf:datatype,'^http://www\.w3\.org/2001/XMLSchema#.+')">xsd:<xsl:value-of select="replace(@rdf:datatype,'^http://www\.w3\.org/2001/XMLSchema#(.+)','$1')"/></xsl:when>
			<xsl:otherwise>&lt;<xsl:value-of select="@rdf:datatype"/>&gt;</xsl:otherwise>
		</xsl:choose>
	</xsl:if>
</xsl:template>

<xsl:template match="*" mode="rdf2turtle-listrec"><xsl:param name="prefix" as="node()"/>
	<xsl:for-each select="rdf:first">
		<xsl:choose>
			<!-- NOTE: blank nodes and lists not supported within a list yet -->
			<xsl:when test="exists(@rdf:resource)"><xsl:apply-templates select="@rdf:resource" mode="rdf2turtle-uri"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates></xsl:when>
			<xsl:otherwise><xsl:apply-templates select="." mode="rdf2turtle-literal"/></xsl:otherwise>
		</xsl:choose>
	</xsl:for-each>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="key('bnode',rdf:rest/@rdf:nodeID)" mode="rdf2turtle-listrec">
		<xsl:with-param name="prefix" select="$prefix"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="*" mode="rdf2turtle-list"><xsl:param name="prefix" as="node()"/>
	<xsl:text>(</xsl:text><xsl:apply-templates select="key('bnode',@rdf:nodeID)" mode="rdf2turtle-listrec"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates><xsl:text>)</xsl:text>
</xsl:template>

<xsl:template match="*" mode="rdf2turtle-object">
	<xsl:param name="prefix" as="node()"/>
	<xsl:param name="tab" as="xs:integer">0</xsl:param>
	<xsl:choose>
		<xsl:when test="exists(@rdf:resource)">
			<xsl:apply-templates select="@rdf:resource" mode="rdf2turtle-uri">
				<xsl:with-param name="prefix" select="$prefix"/>
			</xsl:apply-templates>
		</xsl:when>
		<xsl:when test="exists(@rdf:nodeID) and exists(key('bnode',@rdf:nodeID)/rdf:first)">
			<xsl:apply-templates select="." mode="rdf2turtle-list">
				<xsl:with-param name="prefix" select="$prefix"/>
			</xsl:apply-templates>
		</xsl:when>
		<xsl:when test="exists(@rdf:nodeID)"><xsl:text>[
</xsl:text>
			<xsl:for-each select="key('bnode',@rdf:nodeID)/*">
				<xsl:if test="position()!=1"><xsl:text>;
</xsl:text>
				</xsl:if>
				<xsl:value-of select="fn:rdf2turtle-spaces($tab)"/>
				<xsl:apply-templates select="." mode="rdf2turtle-triple">
					<xsl:with-param name="tab" select="$tab+4"/>
					<xsl:with-param name="prefix" select="$prefix"/>
				</xsl:apply-templates>
			</xsl:for-each>
			<xsl:text>
</xsl:text>
			<xsl:value-of select="fn:rdf2turtle-spaces(-4+$tab)"/><xsl:text>]</xsl:text>
		</xsl:when>
		<xsl:when test="exists(*/@rdf:about)">
			<xsl:apply-templates select="*/@rdf:about" mode="rdf2turtle-uri">
				<xsl:with-param name="prefix" select="$prefix"/>
			</xsl:apply-templates>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="." mode="rdf2turtle-literal"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="rdf2turtle-triple"><xsl:param name="tab" as="xs:integer"/><xsl:param name="prefix" as="node()"/>
	<xsl:apply-templates select="." mode="rdf2turtle-property"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates><xsl:text> </xsl:text>
	<xsl:apply-templates select="." mode="rdf2turtle-object">
		<xsl:with-param name="prefix" select="$prefix"/>
		<xsl:with-param name="tab" select="$tab"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="@rdf:about" mode="resource">
	<xsl:param name="prefix"/>
	<xsl:variable name="about" select="."/>
	<xsl:apply-templates select="." mode="rdf2turtle-uri"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
	<xsl:variable name="nodetype" select="../name()"/>
	<xsl:for-each-group select="../../*[@rdf:about=$about]" group-by="@rdf:about">
		<xsl:variable name="hastype" select="$nodetype!='rdf:Description' or exists(current-group()/rdf:type)"/>
		<xsl:if test="$hastype"><xsl:text> a </xsl:text>
			<xsl:if test="$nodetype!='rdf:Description'">
				<xsl:value-of select="$nodetype"/>
			</xsl:if>
			<xsl:for-each select="current-group()/rdf:type"><xsl:sort select="@rdf:resource"/>
				<xsl:if test="$nodetype!='rdf:Description' or position()!=1">, </xsl:if>
				<xsl:apply-templates select="." mode="rdf2turtle-object">
					<xsl:with-param name="prefix" select="$prefix"/>
				</xsl:apply-templates>
			</xsl:for-each>
		</xsl:if>
		<xsl:for-each select="current-group()/*"><xsl:sort select="name()"/><xsl:sort select="@rdf:resource"/>
			<xsl:if test="name()!='rdf:type'">
				<xsl:choose><xsl:when test="$hastype or position()!=1"><xsl:text>;
	    </xsl:text></xsl:when>
					<xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
				</xsl:choose>
				<xsl:apply-templates select="." mode="rdf2turtle-triple">
					<xsl:with-param name="tab">9</xsl:with-param>
					<xsl:with-param name="prefix" select="$prefix"/>
				</xsl:apply-templates>
			</xsl:if>
		</xsl:for-each>
.
<xsl:for-each select="current-group()/*/*/@rdf:about"><xsl:sort select="."/>
<xsl:apply-templates select="." mode="resource"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
</xsl:for-each>
</xsl:for-each-group>
</xsl:template>

<xsl:template match="rdf:RDF" mode="rdf2turtle">
<xsl:variable name="prefix"><xsl:apply-templates select="." mode="rdf2turtle-getprefixes"/></xsl:variable>
<xsl:for-each-group select="$prefix/prefix" group-by="."><xsl:sort select="@name"/>
	<xsl:text>@prefix </xsl:text>
	<xsl:value-of select="@name"/>: &lt;<xsl:value-of select="."/>
	<xsl:text>>.
</xsl:text>
</xsl:for-each-group>
<xsl:for-each-group select="*" group-by="@rdf:about"><xsl:sort select="@rdf:about"/>
	<xsl:apply-templates select="@rdf:about" mode="rdf2turtle-uri">
		<xsl:with-param name="prefix" select="$prefix"/>
	</xsl:apply-templates>
	<xsl:variable name="nodetype" select="name()"/>
	<xsl:variable name="hastype" select="$nodetype!='rdf:Description' or exists(current-group()/rdf:type)"/>
	<xsl:if test="$hastype"><xsl:text> a </xsl:text>
		<xsl:if test="$nodetype!='rdf:Description'">
			<xsl:value-of select="$nodetype"/>
		</xsl:if>
		<xsl:for-each select="current-group()/rdf:type"><xsl:sort select="@rdf:resource"/>
			<xsl:if test="$nodetype!='rdf:Description' or position()!=1">, </xsl:if>
			<xsl:apply-templates select="." mode="rdf2turtle-object">
				<xsl:with-param name="prefix" select="$prefix"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:if>
	<xsl:for-each select="current-group()/*"><xsl:sort select="name()"/><xsl:sort select="@rdf:resource"/>
		<xsl:if test="name()!='rdf:type'">
			<xsl:choose><xsl:when test="$hastype or position()!=1"><xsl:text>;
    </xsl:text></xsl:when>
				<xsl:otherwise><xsl:text> </xsl:text></xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates select="." mode="rdf2turtle-triple">
				<xsl:with-param name="tab">9</xsl:with-param>
				<xsl:with-param name="prefix" select="$prefix"/>
			</xsl:apply-templates>
		</xsl:if>
	</xsl:for-each>
.
<xsl:for-each select="current-group()/*/*/@rdf:about"><xsl:sort select="."/>
<xsl:apply-templates select="." mode="resource"><xsl:with-param name="prefix" select="$prefix"/></xsl:apply-templates>
</xsl:for-each>
</xsl:for-each-group>
</xsl:template>

</xsl:stylesheet>
