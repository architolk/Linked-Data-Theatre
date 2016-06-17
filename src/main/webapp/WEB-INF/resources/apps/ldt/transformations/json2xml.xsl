<?xml version="1.0" encoding="utf-8"?>
<!--

    NAME     json2xml.xsl
    VERSION  1.8.1-SNAPSHOT
    DATE     2016-06-17

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
    Transforms a json file into a xml file
  
-->

<xsl:stylesheet version="1.0" 
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:elmo="http://bp4mc2.org/elmo/def#"
				exclude-result-prefixes="elmo"
>

	<xsl:template match="/">
		<xsl:variable name="output" select="/root/representation/fragment[@applies-to='']"/>
		<xsl:variable name="xml">
			<xsl:call-template name="json2xml">
				<xsl:with-param name="text" select="/root/parameters/response"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="not(exists(/root/context/parameters)) and not(exists(/root/representation/fragment/elmo:path))">
				<xsl:copy-of select="$xml"/>
			</xsl:when>
			<xsl:otherwise>
				<parameters>
					<xsl:copy-of select="/root/context/parameters/parameter"/>
					<xsl:for-each select="$output">
						<xsl:variable name="path" select="elmo:path"/>
						<xsl:variable name="value"><xsl:for-each select="$xml"><xsl:value-of select="saxon:evaluate($path)" xmlns:saxon="http://saxon.sf.net/"/></xsl:for-each></xsl:variable>
						<parameter>
							<name><xsl:value-of select="elmo:name"/></name>
							<value>
								<xsl:value-of select="$value"/>
								<!-- Setting the empty value to an empty URI is a quick fix, should be better solution in query.xsl: not performing query after an empty result -->
								<xsl:if test="$value=''">http://bp4mc2.org/elmo/def#Nothing</xsl:if>
							</value>
						</parameter>
					</xsl:for-each>
				</parameters>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="json2xml">
		<xsl:param name="text"/>
		<xsl:variable name="mode0">
			<xsl:variable name="regexps" select="'//(.*?)\n', '/\*(.*?)\*/', '(''|&quot;)(([^\\]|\\[\\&quot;''/btnvfr])*?)\3', '(-?\d+(\.\d+([eE][+-]?\d+)?|[eE][+-]?\d+))', '(-?[1-9]\d*)', '(-?0[0-7]+)', '(-?0x[0-9a-fA-F]+)', '([:,\{\}\[\]])', '(true|false)', '(null)'"/>
			<xsl:analyze-string select="$text" regex="{string-join($regexps,'|')}" flags="s">
				<xsl:matching-substring>
					<xsl:choose>
						<!-- single line comment -->
						<xsl:when test="regex-group(1)">
							<xsl:comment>
								<xsl:value-of select="regex-group(1)"/>
							</xsl:comment>
							<xsl:text>&#10;</xsl:text>
						</xsl:when>
						<!-- multi line comment -->
						<xsl:when test="regex-group(2)">
							<xsl:comment>
								<xsl:value-of select="regex-group(2)"/>
							</xsl:comment>
						</xsl:when>
						<!-- string -->
						<xsl:when test="regex-group(3)">
							<string>
								<xsl:analyze-string select="regex-group(4)" regex="\\([\\&quot;'/btnvfr])" flags="s">
									<xsl:matching-substring>
										<xsl:variable name="s" select="regex-group(1)"/>
										<xsl:choose>
											<xsl:when test="$s=('\', '&quot;', '''', '/')">
												<xsl:value-of select="regex-group(1)"/>
											</xsl:when>
											<xsl:when test="$s='b'">
												<!--xsl:text>&#8;</xsl:text-->
												<xsl:message select="'escape sequense \b is not supported by XML'"/>
												<xsl:text>\b</xsl:text>
											</xsl:when>
											<xsl:when test="$s='t'">
												<xsl:text>&#9;</xsl:text>
											</xsl:when>
											<xsl:when test="$s='n'">
												<xsl:text>&#10;</xsl:text>
											</xsl:when>
											<xsl:when test="$s='v'">
												<!--xsl:text>&#11;</xsl:text-->
												<xsl:message select="'escape sequence \v is not supported by XML'"/>
												<xsl:text>\v</xsl:text>
											</xsl:when>
											<xsl:when test="$s='f'">
												<!--xsl:text>&#12;</xsl:text-->
												<xsl:message select="'escape sequence \f is not supported by XML'"/>
												<xsl:text>\f</xsl:text>
											</xsl:when>
											<xsl:when test="$s='r'">
												<xsl:text>&#13;</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<xsl:message terminate="yes" select="'internal error'"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:matching-substring>
									<xsl:non-matching-substring>
										<xsl:value-of select="."/>
									</xsl:non-matching-substring>
								</xsl:analyze-string>
							</string>
						</xsl:when>
						<!-- double -->
						<xsl:when test="regex-group(6)">
							<double>
								<xsl:value-of select="regex-group(6)"/>
							</double>
						</xsl:when>
						<!-- integer -->
						<xsl:when test="regex-group(9)">
							<integer>
								<xsl:value-of select="regex-group(9)"/>
							</integer>
						</xsl:when>
						<!-- octal -->
						<xsl:when test="regex-group(10)">
							<integer>
								<xsl:value-of xmlns:Integer="java:java.lang.Integer" select="Integer:parseInt(regex-group(10), 8)"/>
							</integer>
						</xsl:when>
						<!-- hex -->
						<xsl:when test="regex-group(11)">
							<integer>
								<xsl:value-of xmlns:Integer="java:java.lang.Integer" select="Integer:parseInt(replace(regex-group(11), '0x', ''), 16)"/>
							</integer>
						</xsl:when>
						<!-- symbol -->
						<xsl:when test="regex-group(12)">
							<symbol>
								<xsl:value-of select="regex-group(12)"/>
							</symbol>
						</xsl:when>
						<!-- boolean -->
						<xsl:when test="regex-group(13)">
							<boolean>
								<xsl:value-of select="regex-group(13)"/>
							</boolean>
						</xsl:when>
						<!-- null -->
						<xsl:when test="regex-group(14)">
							<null />
						</xsl:when>
						<xsl:otherwise>
							<xsl:message terminate="yes" select="'internal error'"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:matching-substring>
				<xsl:non-matching-substring>
					<xsl:if test="normalize-space()!=''">
						<xsl:message select="concat('unknown token: ', .)"/>
						<xsl:value-of select="."/>
					</xsl:if>
				</xsl:non-matching-substring>
			</xsl:analyze-string>
		</xsl:variable>
		<xsl:variable name="mode1">
			<xsl:apply-templates mode="json2xml1" select="$mode0/node()[1]"/>
		</xsl:variable>
		<xsl:variable name="mode2">
			<xsl:apply-templates mode="json2xml2" select="$mode1"/>
		</xsl:variable>
		<xsl:variable name="mode3">
			<xsl:apply-templates mode="json2xml3" select="$mode2"/>
		</xsl:variable>
		<xsl:copy-of select="$mode3"/> <!-- change $mode3 to $mode[0-2] for easy debug -->
	</xsl:template>

	<!-- json2xml1 mode: group content between {} and [] into object and array elements -->

	<xsl:template mode="json2xml1" match="node()" priority="-9">
		<xsl:copy-of select="."/>
		<xsl:apply-templates mode="json2xml1" select="following-sibling::node()[1]"/>
	</xsl:template>

	<xsl:template mode="json2xml1" match="symbol[.=('}',']')]"/>

	<xsl:template mode="json2xml1" match="symbol[.=('{','[')]">
		<xsl:element name="{if (.='{') then 'object' else 'array'}">
			<xsl:apply-templates mode="json2xml1" select="following-sibling::node()[1]"/>
		</xsl:element>
		<xsl:variable name="level" select="count(preceding-sibling::symbol[.=('{','[')])-count(preceding-sibling::symbol[.=('}',']')])+1"/>
		<xsl:variable name="ender"
			select="following-sibling::symbol[.=('}',']') and count(preceding-sibling::symbol[.=('{','[')])-count(preceding-sibling::symbol[.=('}',']')])=$level][1]"/>
		<xsl:apply-templates mode="json2xml1" select="$ender/following-sibling::node()[1]"/>
	</xsl:template>

	<!-- json2xml2 mode: group <string>:<string|integer|double|object|array> into field element -->

	<xsl:template priority="-9" mode="json2xml2" match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates mode="json2xml2" select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template mode="json2xml2"
		match="string[following-sibling::*[1]/self::symbol[.=':'] and following-sibling::*[2]/(self::string|self::integer|self::double|self::boolean|self::object|self::array|self::null)]"/>

	<xsl:template mode="json2xml2"
		match="symbol[.=':'][preceding-sibling::*[1]/self::string and following-sibling::*[1]/(self::string|self::integer|self::double|self::boolean|self::object|self::array|self::null)]">
		<field name="{preceding-sibling::*[1]}">
			<xsl:for-each select="following-sibling::*[1]">
				<xsl:copy>
					<xsl:apply-templates mode="json2xml2" select="@*|node()"/>
				</xsl:copy>
			</xsl:for-each>
		</field>
	</xsl:template>

	<xsl:template mode="json2xml2"
		match="*[self::string|self::integer|self::double|self::boolean|self::object|self::array|self::null][preceding-sibling::*[2]/self::string and preceding-sibling::*[1]/self::symbol[.=':']]"/>

	<!-- json2xml3 mode: drop comma between consecutive field and object elements -->

	<xsl:template priority="-9" mode="json2xml3" match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates mode="json2xml3" select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template mode="json2xml3" match="object/symbol[.=','][preceding-sibling::*[1]/self::field and following-sibling::*[1]/self::field]"/>

	<xsl:template mode="json2xml3" match="array/symbol[.=','][preceding-sibling::*[1]/(self::string|self::integer|self::double|self::boolean|self::object|self::array|self::null) and following-sibling::*[1]/(self::string|self::integer|self::double|self::boolean|self::object|self::array|self::null)]"/>

</xsl:stylesheet>