<!--

    NAME     redirect.xpl
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
	Standard redirect page conform the URI 303 strategy
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
          xmlns:oxf="http://www.orbeon.com/oxf/processors"
		  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!-- Configuration> -->
	<p:param type="input" name="instance"/>

	<!-- Header information needed for Cool-URI implementation -->
	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request/request-url</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>

<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config/>
	</p:input>
	<p:input name="data" href="#request"/>
</p:processor>
-->
	
	<p:processor xmlns:p="http://www.orbeon.com/oxf/pipeline" name="oxf:redirect">    
		<p:input name="data" transform="oxf:xslt" href="#request">
			<redirect-url xsl:version="2.0">
				<xsl:variable name="domain" select="substring-before(request/request-url,'/id/')"/>
				<xsl:variable name="term" select="substring-after(request/request-url,'/id/')"/>
				<path-info><xsl:value-of select="$domain"/>/doc/<xsl:value-of select="$term"/></path-info>
				<server-side>false</server-side>
			</redirect-url>   
		</p:input>
	</p:processor>

</p:config>
