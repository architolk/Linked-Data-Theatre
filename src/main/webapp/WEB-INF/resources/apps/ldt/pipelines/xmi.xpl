<!--

    NAME     xmi.xpl
    VERSION  1.5.1
    DATE     2016-02-09

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
	xmi output of an ontology definition
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
		  xmlns:xforms="http://www.w3.org/2002/xforms"
          xmlns:oxf="http://www.orbeon.com/oxf/processors"
		  xmlns:ev="http://www.w3.org/2001/xml-events"
		  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		  xmlns:elmo="http://bp4mc2.org/elmo/def#">

	<!-- Configuration> -->
	<p:param type="input" name="instance"/>
		  
	<p:processor name="oxf:xforms-submission">
		<p:input name="submission">
			<xforms:submission method="get" action="http://localhost:8890/sparql">
				<xforms:header>
					<xforms:name>Accept</xforms:name>
					<xforms:value>application/sparql-results+xml</xforms:value>
				</xforms:header>
				<xforms:setvalue ev:event="xforms-submit-error" ref="error" value="event('response-body')"/>
				<xforms:setvalue ev:event="xforms-submit-error" ref="error/@type" value="event('error-type')"/>
			</xforms:submission>
		</p:input>
		<p:input name="request" transform="oxf:xslt" href="#instance">
			<parameters xsl:version="2.0">
				<query>
				<![CDATA[
				SELECT
					?s ?s_label
					?p ?p_label
					?o ?o_label
				WHERE {
					GRAPH <]]><xsl:value-of select="submission/subject"/><![CDATA[> {
						{
							{
								?s ?p ?o
								FILTER (
									?p = <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> &&
									(
										?o = <http://www.w3.org/2002/07/owl#Class> ||
										?o = <http://www.w3.org/2002/07/owl#ObjectProperty> ||
										?o = <http://www.w3.org/2002/07/owl#DatatypeProperty> ||
										?o = <http://www.w3.org/2002/07/owl#Ontology>
									)
								)
							}
							UNION
							{
								?s ?p ?o.
								{
									{?s rdf:type owl:Class} UNION
									{?s rdf:type owl:ObjectProperty} UNION
									{?s rdf:type owl:DatatypeProperty} 
								}
								FILTER (
									?p = <http://www.w3.org/2000/01/rdf-schema#isDefinedBy>
								)
							}
							UNION
							{
								{
									{?s rdf:type owl:Class} UNION
									{?s rdf:type owl:ObjectProperty} UNION
									{?s rdf:type owl:DatatypeProperty} 
								}
								BIND (<http://www.w3.org/2000/01/rdf-schema#isDefinedBy> as ?p)
								BIND (<@SUBJECT@> as ?o)
								FILTER NOT EXISTS {
									?s <http://www.w3.org/2000/01/rdf-schema#isDefinedBy> ?ox
								}
							}
							UNION
							{
								?s ?p ?o.
								?s rdf:type owl:Class
								FILTER (
									?p = <http://www.w3.org/2000/01/rdf-schema#subClassOf>
								)
							}
							UNION
							{
								?s ?p ?o.
								{
									{?s rdf:type owl:ObjectProperty} UNION
									{?s rdf:type owl:DatatypeProperty} 
								}
								FILTER (
									?p = <http://www.w3.org/2000/01/rdf-schema#domain> ||
									?p = <http://www.w3.org/2000/01/rdf-schema#range>
								)
							}
						}
						OPTIONAL {
							?s rdfs:label ?s_label
							FILTER (lang(?s_label)="en" or lang(?s_label)="")
						}
						OPTIONAL {
							?p rdfs:label ?p_label
							FILTER (lang(?p_label)="en" or lang(?o_label)="")
						}
						OPTIONAL {
							?o rdfs:label ?o_label
							FILTER (lang(?p_label)="en" or lang(?o_label)="")
						}
					}
				}
				]]>
				</query>
				<default-graph-uri/>
				<error type=""/>
			</parameters>
		</p:input>
		<p:output name="response" id="sparql"/>
	</p:processor>

<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config>
		</config>
	</p:input>
	<p:input name="data" href="#sparql"/>
</p:processor>
-->
	
	<!-- Transform to obj intermediate language -->
    <p:processor name="oxf:xslt">
        <p:input name="data" href="#sparql"/>
        <p:input name="config" href="../transformations/sparql2obj.xsl"/>
        <p:output name="data" id="intermediate"/>
    </p:processor>

<!--
<p:processor name="oxf:xml-serializer">
	<p:input name="config">
		<config>
		</config>
	</p:input>
	<p:input name="data" href="#intermediate"/>
</p:processor>
-->
	
	<!-- Transform from obj to xmi/xml -->
	<p:processor name="oxf:xslt">
		<p:input name="data" href="#intermediate"/>
		<p:input name="config" href="../transformations/obj2xmi.xsl"/>
		<p:output name="data" id="xml"/>
	</p:processor>
	<!-- Convert XML result to XML document -->
	<p:processor name="oxf:xml-converter">
		<p:input name="config">
			<config>
				<encoding>utf-8</encoding>
			</config>
		</p:input>
		<p:input name="data" href="#xml"/>
		<p:output name="data" id="converted"/>
	</p:processor>
	<!-- Serialize -->
	<p:processor name="oxf:http-serializer">
		<p:input name="config">
			<config>
				<content-type>application/xml</content-type>
				<header>
					<name>Content-Disposition</name>
					<value>attachment; filename=result.xmi.xml</value>
				</header>
			</config>
		</p:input>
		<p:input name="data" href="#converted"/>
	</p:processor>

</p:config>
