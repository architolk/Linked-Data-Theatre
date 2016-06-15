<!--

    NAME     rdf2yed.xsl
    VERSION  1.8.0
    DATE     2016-06-15

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
	Transformation of RDF document to graphml format, with yed extension
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:yed="http://bp4mc2.org/yed#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
>

<xsl:key name="nodes" match="/root/results/rdf:RDF[1]/rdf:Description" use="@rdf:about"/>
<xsl:key name="blanks" match="/root/results/rdf:RDF[1]/rdf:Description" use="@rdf:nodeID"/>
<xsl:key name="fragments" match="/root/view/representation[1]/fragment" use="@applies-to"/>

<xsl:template match="/">
<xsl:for-each select="root/results/rdf:RDF[1]">
<graphml xmlns:y="http://www.yworks.com/xml/graphml">
	<key for="node" id="d6" yfiles.type="nodegraphics"/>
	<key for="edge" id="d10" yfiles.type="edgegraphics"/>
	<graph id="G" edgedefault="directed">
		<!-- Nodes -->
		<xsl:for-each select="rdf:Description[exists(rdf:type)]">
			<xsl:variable name="slabel"><xsl:value-of select="substring-after(@rdf:about,'#')"/></xsl:variable>
			<xsl:variable name="label">
				<xsl:value-of select="rdfs:label"/>
				<xsl:if test="not(rdfs:label!='')">
					<xsl:value-of select="$slabel"/>
					<xsl:if test="$slabel=''"><xsl:value-of select="@rdf:about"/></xsl:if>
				</xsl:if>
			</xsl:variable>
			<xsl:variable name="fragment" select="key('fragments',elmo:style[1])"/>
			<xsl:variable name="backgroundColor">
				<xsl:value-of select="$fragment/yed:backgroundColor"/>
				<xsl:if test="not(exists($fragment/yed:backgroundColor))">#FFFFFF</xsl:if> <!-- #B7C9E3 -->
			</xsl:variable>
			<node id="{@rdf:about}{@rdf:nodeID}"> <!-- URI nodes and blank nodes -->
				<data key="d6">
					<y:GenericNode configuration="com.yworks.entityRelationship.big_entity">
						<y:Geometry height="100.0" width="200.0" x="0.5" y="0"/>
						<y:Fill color="#E8EEF7" color2="#B7C9E3" transparent="false"/>
						<y:BorderStyle color="#000000" type="line" width="1.0"/>
						<y:NodeLabel alignment="center" autoSizePolicy="node_width" backgroundColor="{$backgroundColor}" configuration="CroppingLabel" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasLineColor="false" modelName="internal" modelPosition="t" textColor="#000000" visible="true"><xsl:value-of select="$label"/></y:NodeLabel>
						<y:NodeLabel alignment="left" autoSizePolicy="node_width" configuration="CroppingLabel" fontFamily="Dialog" fontSize="8" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" modelName="custom" textColor="#000000" visible="true">
							<xsl:for-each select="rdfs:comment">
								<xsl:if test="position()!=1"><xsl:text>
</xsl:text></xsl:if><xsl:value-of select="."/>
							</xsl:for-each>
							<y:LabelModel>
								<y:ErdAttributesNodeLabelModel/>
							</y:LabelModel>
							<y:ModelParameter>
								<y:ErdAttributesNodeLabelModelParameter/>
							</y:ModelParameter>
						</y:NodeLabel>
						<y:StyleProperties>
							<y:Property class="java.lang.Boolean" name="y.view.ShadowNodePainter.SHADOW_PAINTING" value="true"/>
						</y:StyleProperties>
					</y:GenericNode>
				</data>
			</node>
		</xsl:for-each>
		<!-- Edges for URI nodes -->
		<xsl:for-each select="rdf:Description/*[exists(key('nodes',@rdf:resource))]">
			<xsl:variable name="puri"><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></xsl:variable>
			<xsl:variable name="pfragment" select="key('fragments',$puri)"/>
			<xsl:variable name="label">
				<xsl:value-of select="$pfragment/rdfs:label"/>
				<xsl:if test="not(exists($pfragment/rdfs:label))"><xsl:value-of select="name()"/></xsl:if>
			</xsl:variable>
			<xsl:variable name="source">
				<xsl:value-of select="$pfragment/yed:sourceArrow"/>
				<xsl:if test="not(exists($pfragment/yed:sourceArrow))">none</xsl:if>
			</xsl:variable>
			<xsl:variable name="target">
				<xsl:value-of select="$pfragment/yed:targetArrow"/>
				<xsl:if test="not(exists($pfragment/yed:targetArrow))">standard</xsl:if>
			</xsl:variable>
			<xsl:variable name="line">
				<xsl:value-of select="$pfragment/yed:line"/>
				<xsl:if test="not(exists($pfragment/yed:line))">line</xsl:if>
			</xsl:variable>
			<xsl:variable name="edgetype">
				<xsl:choose>
					<xsl:when test="$pfragment/yed:edge/@rdf:resource='http://bp4mc2.org/yed#BezierEdge'">y:BezierEdge</xsl:when>
					<xsl:when test="$pfragment/yed:edge/@rdf:resource='http://bp4mc2.org/yed#PolyLineEdge'">y:PolyLineEdge</xsl:when>
					<xsl:otherwise>y:PolyLineEdge</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<edge source="{../@rdf:about}" target="{@rdf:resource}">-
				<data key="d10">
					<xsl:element name="{$edgetype}">
						<y:LineStyle color="#000000" type="{$line}" width="1.0"/>
						<y:Arrows source="{$source}" target="{$target}"/>
						<y:EdgeLabel alignment="center" configuration="AutoFlippingLabel" distance="2.0" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" modelName="custom" preferredPlacement="anywhere" ratio="0.5" textColor="#000000" visible="true"><xsl:value-of select="$label"/><y:LabelModel>
								<y:SmartEdgeLabelModel autoRotationEnabled="false" defaultAngle="0.0" defaultDistance="10.0"/>
							</y:LabelModel>
							<y:ModelParameter>
								<y:SmartEdgeLabelModelParameter angle="0.0" distance="30.0" distanceToCenter="true" position="center" ratio="0.5" segment="0"/>
							</y:ModelParameter>
							<y:PreferredPlacementDescriptor angle="0.0" angleOffsetOnRightSide="0" angleReference="absolute" angleRotationOnRightSide="co" distance="-1.0" frozen="true" placement="anywhere" side="anywhere" sideReference="relative_to_edge_flow"/>
						</y:EdgeLabel>
						<y:BendStyle smoothed="false"/>
					</xsl:element>
				</data>
			</edge>
		</xsl:for-each>
		<!-- Edges for blank nodes -->
		<xsl:for-each select="rdf:Description/*[exists(key('blanks',@rdf:nodeID))]">
			<edge source="{../@rdf:about}" target="{@rdf:nodeID}">-
				<data key="d10">
					<y:PolyLineEdge>
						<y:LineStyle color="#000000" type="line" width="1.0"/>
						<y:Arrows source="none" target="standard"/>
						<y:EdgeLabel alignment="center" configuration="AutoFlippingLabel" distance="2.0" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" modelName="custom" preferredPlacement="anywhere" ratio="0.5" textColor="#000000" visible="true"><xsl:value-of select="name()"/><y:LabelModel>
								<y:SmartEdgeLabelModel autoRotationEnabled="false" defaultAngle="0.0" defaultDistance="10.0"/>
							</y:LabelModel>
							<y:ModelParameter>
								<y:SmartEdgeLabelModelParameter angle="0.0" distance="30.0" distanceToCenter="true" position="center" ratio="0.5" segment="0"/>
							</y:ModelParameter>
							<y:PreferredPlacementDescriptor angle="0.0" angleOffsetOnRightSide="0" angleReference="absolute" angleRotationOnRightSide="co" distance="-1.0" frozen="true" placement="anywhere" side="anywhere" sideReference="relative_to_edge_flow"/>
						</y:EdgeLabel>
						<y:BendStyle smoothed="false"/>
					</y:PolyLineEdge>
				</data>
			</edge>
		</xsl:for-each>
	</graph>
</graphml>
</xsl:for-each>
</xsl:template>

</xsl:stylesheet>