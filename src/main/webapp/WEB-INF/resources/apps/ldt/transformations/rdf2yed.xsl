<!--

    NAME     rdf2yed.xsl
    VERSION  1.22.0
    DATE     2018-06-13

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
	Transformation of RDF document to graphml format, with yed extension

	Depended on: ModelTemplates.xsl (in case of a elmo:VocabularyAppearance)
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:yed="http://bp4mc2.org/yed#"
	xmlns:elmo="http://bp4mc2.org/elmo/def#"
	xmlns:y="http://www.yworks.com/xml/graphml"
>

<xsl:key name="nodes" match="/root/results/rdf:RDF[1]/rdf:Description" use="@rdf:about"/>
<xsl:key name="blanks" match="/root/results/rdf:RDF[1]/rdf:Description" use="@rdf:nodeID"/>
<xsl:key name="fragments" match="/root/view/representation[1]/fragment" use="@applies-to"/>

<xsl:template match="/">
	<graphml>
		<key for="node" id="d6" yfiles.type="nodegraphics"/>
		<key for="edge" id="d10" yfiles.type="edgegraphics"/>
		<graph id="G" edgedefault="directed">
			<xsl:choose>
				<!-- Interpret the RDF in a specific way to get a vocab appearance -->
				<xsl:when test="root/view/representation[1]/@appearance='http://bp4mc2.org/elmo/def#VocabularyAppearance'"><xsl:apply-templates select="root/results/rdf:RDF[1]" mode="yed-vocab"/></xsl:when>
				<xsl:otherwise><xsl:apply-templates select="root/results/rdf:RDF[1]" mode="yed-default"/></xsl:otherwise>
			</xsl:choose>
		</graph>
	</graphml>
</xsl:template>

<xsl:template match="rdf:RDF" mode="yed-vocab">
	<!-- Parse RDF graph and put result in vocabulary variable -->
	<xsl:variable name="vocabulary"><xsl:apply-templates select="." mode="VocabularyVariable"/></xsl:variable>

<!--<xsl:copy-of select="$vocabulary"/>-->

	<!-- Nodes -->
	<xsl:for-each select="$vocabulary/nodeShapes/shape[@empty!='true']">
		<xsl:variable name="slabel">
			<xsl:choose>
				<xsl:when test="@class-uri!=''"><xsl:value-of select="replace(@class-uri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="replace(@uri,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="label">
			<xsl:value-of select="@name"/>
			<xsl:if test="not(@name!='')">
				<xsl:value-of select="$slabel"/>
				<xsl:if test="$slabel=''">
					<xsl:choose>
						<xsl:when test="@class-uri!=''"><xsl:value-of select="@class-uri"/></xsl:when>
						<xsl:otherwise><xsl:value-of select="@uri"/></xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:if>
		</xsl:variable>
		<node id="{@uri}">
			<data key="d6">
				<y:GenericNode configuration="com.yworks.entityRelationship.big_entity">
					<xsl:variable name="enumerationcnt">
						<xsl:choose>
							<xsl:when test="exists(enumvalue|enumeration)"><xsl:value-of select="count(enumvalue|enumeration)+1"/></xsl:when>
							<xsl:otherwise>0</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<y:Geometry height="{40+13*($enumerationcnt+count(property[not(exists(refshape[@type='role']) or exists(ref-nodes/item) or exists(refshape[@empty='false']))]))}" width="200.0" x="0.5" y="0"/>
					<y:Fill color="#E8EEF7" color2="#B7C9E3" transparent="false"/>
					<y:BorderStyle color="#000000" type="line" width="1.0"/>
					<y:NodeLabel alignment="center" autoSizePolicy="node_width" configuration="CroppingLabel" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasLineColor="false" modelName="internal" modelPosition="t" textColor="#000000" visible="true" hasBackgroundColor="false">
						<xsl:value-of select="$label"/>
					</y:NodeLabel>
					<y:NodeLabel alignment="left" autoSizePolicy="node_width" configuration="CroppingLabel" fontFamily="Dialog" fontSize="10" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" modelName="custom" textColor="#000000" visible="true">
						<!--Properties-->
						<xsl:for-each select="property[not(exists(refshape[@type='role']) or exists(ref-nodes/item) or exists(refshape[@empty='false']))]">
							<xsl:if test="position()!=1"><xsl:text>
</xsl:text></xsl:if><xsl:apply-templates select="." mode="property-placement"/>
						</xsl:for-each>
						<!--Enumerations-->
						<xsl:for-each select="enumvalue">
							<xsl:if test="position()=1">Possible values:</xsl:if><xsl:text>
&#x221a; </xsl:text><xsl:value-of select="@name"/>
						</xsl:for-each>
						<xsl:for-each select="enumeration">
							<xsl:if test="position()=1">Values from:</xsl:if><xsl:text>
- </xsl:text><xsl:value-of select="@uri"/>
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
	<!-- Logic nodes, with edges -->
	<xsl:for-each select="$vocabulary/nodeShapes/shape/property/ref-nodes">
		<xsl:variable name="nodeuri" select="@uri"/>
		<node id="{$nodeuri}">
			<data key="d6">
				<y:ShapeNode>
					<y:Geometry height="30.0" width="{string-length(@logic)*10}" x="376.0" y="185.0"/>
					<y:Fill color="#FFFFFF" transparent="false"/>
					<y:BorderStyle color="#000000" raised="false" type="line" width="1.0"/>
					<y:NodeLabel alignment="center" autoSizePolicy="node_width" configuration="CroppingLabel" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasLineColor="false" modelName="internal" modelPosition="t" textColor="#000000" visible="true" hasBackgroundColor="false">
						<xsl:value-of select="@logic"/>
					</y:NodeLabel>
					<y:Shape type="ellipse"/>
				</y:ShapeNode>
			</data>
		</node>
		<xsl:for-each select="item">
			<xsl:variable name="refuri" select="@uri"/>
			<xsl:variable name="refshape" select="$vocabulary/nodeShapes/shape[@uri=$refuri]"/>
			<xsl:if test="$refshape/@empty!='true'">
				<edge source="{$nodeuri}" target="{@uri}"/>
			</xsl:if>
		</xsl:for-each>
	</xsl:for-each>
	<!-- Edges for URI nodes -->
	<xsl:for-each select="$vocabulary/nodeShapes/shape[@empty!='true']/property/(refshape|ref-nodes)">
		<xsl:variable name="refuri" select="@uri"/>
		<xsl:variable name="refshape" select="$vocabulary/nodeShapes/shape[@uri=$refuri]"/>
		<xsl:variable name="sourcestyle">
			<xsl:choose>
				<xsl:when test="../@nodekind='BlankNode'">diamond</xsl:when>
				<xsl:otherwise>none</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- Show edges whenever -->
		<!-- 1. It's a ref-node, or -->
		<!-- 2. The refshape is not empty AND -->
		<!--   a no explicitly defined refnode is available, or -->
		<!--   b the refshape is the same as the refnode -->
		<xsl:if test="local-name()='ref-nodes' or ($refshape/@empty!='true' and (not(../@refnode!='') or @uri=../@refnode))">
			<edge source="{../../@uri}" target="{@uri}">
				<data key="d10">
					<y:PolyLineEdge>
						<xsl:choose>
							<xsl:when test="@type='role'">
								<y:LineStyle color="#000000" type="dashed" width="1.0"/>
								<y:Arrows source="none" target="white_delta"/>
							</xsl:when>
							<xsl:otherwise>
								<y:LineStyle color="#000000" type="line" width="1.0"/>
								<y:Arrows source="{$sourcestyle}" target="standard"/>
								<y:EdgeLabel alignment="center" configuration="AutoFlippingLabel" distance="2.0" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" modelName="custom" preferredPlacement="anywhere" ratio="0.5" textColor="#000000" visible="true">
									<xsl:apply-templates select=".." mode="property-placement"/>
									<y:LabelModel>
										<y:SmartEdgeLabelModel autoRotationEnabled="false" defaultAngle="0.0" defaultDistance="10.0"/>
									</y:LabelModel>
									<y:ModelParameter>
										<y:SmartEdgeLabelModelParameter angle="0.0" distance="30.0" distanceToCenter="true" position="center" ratio="0.5" segment="0"/>
									</y:ModelParameter>
									<y:PreferredPlacementDescriptor angle="0.0" angleOffsetOnRightSide="0" angleReference="absolute" angleRotationOnRightSide="co" distance="-1.0" frozen="true" placement="anywhere" side="anywhere" sideReference="relative_to_edge_flow"/>
								</y:EdgeLabel>
							</xsl:otherwise>
						</xsl:choose>
						<y:BendStyle smoothed="false"/>
					</y:PolyLineEdge>
				</data>
			</edge>
		</xsl:if>
	</xsl:for-each>
	<!-- Subclasses -->
	<xsl:for-each select="$vocabulary/nodeShapes/shape[@class-uri!='' and @empty!='true']">
		<xsl:variable name="source" select="@uri"/>
		<xsl:variable name="class" select="@class-uri"/>
		<xsl:for-each select="$vocabulary/classes/class[@uri=$class]/super">
			<xsl:variable name="super" select="@uri"/>
			<xsl:for-each select="$vocabulary/nodeShapes/shape[@class-uri=$super and @empty!='true']">
				<edge source="{$source}" target="{@uri}">
					<data key="d10">
						<y:PolyLineEdge>
							<y:LineStyle color="#000000" type="line" width="1.0"/>
							<y:Arrows source="none" target="white_delta"/>
							<!--
							<y:EdgeLabel alignment="center" configuration="AutoFlippingLabel" distance="2.0" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" modelName="custom" preferredPlacement="anywhere" ratio="0.5" textColor="#000000" visible="true">
								<xsl:apply-templates select=".." mode="property-placement"/>
								<y:LabelModel>
									<y:SmartEdgeLabelModel autoRotationEnabled="false" defaultAngle="0.0" defaultDistance="10.0"/>
								</y:LabelModel>
								<y:ModelParameter>
									<y:SmartEdgeLabelModelParameter angle="0.0" distance="30.0" distanceToCenter="true" position="center" ratio="0.5" segment="0"/>
								</y:ModelParameter>
								<y:PreferredPlacementDescriptor angle="0.0" angleOffsetOnRightSide="0" angleReference="absolute" angleRotationOnRightSide="co" distance="-1.0" frozen="true" placement="anywhere" side="anywhere" sideReference="relative_to_edge_flow"/>
							</y:EdgeLabel>
							-->
							<y:BendStyle smoothed="false"/>
						</y:PolyLineEdge>
					</data>
				</edge>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:for-each>
</xsl:template>

<xsl:template match="rdf:RDF" mode="yed-default">
	<!-- Nodes -->
	<xsl:for-each select="rdf:Description[exists(rdf:type)]">
		<xsl:variable name="slabel"><xsl:value-of select="replace(@rdf:about,'^.*(#|/)([^(#|/)]+)$','$2')"/></xsl:variable>
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
		<xsl:variable name="modelposition">
			<xsl:choose>
				<xsl:when test="exists(rdfs:comment)">t</xsl:when>
				<xsl:otherwise>c</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<node id="{@rdf:about}{@rdf:nodeID}"> <!-- URI nodes and blank nodes -->
			<data key="d6">
				<xsl:variable name="nodeType">
					<xsl:value-of select="$fragment/yed:nodeType"/>
					<xsl:if test="not(exists($fragment/yed:nodeType))">com.yworks.entityRelationship.big_entity</xsl:if>
				</xsl:variable>
				<y:GenericNode configuration="{$nodeType}">
					<y:Geometry height="100.0" width="200.0" x="0.5" y="0"/>
					<y:Fill color="#E8EEF7" color2="#B7C9E3" transparent="false"/>
					<y:BorderStyle color="#000000" type="line" width="1.0"/>
					<y:NodeLabel alignment="center" autoSizePolicy="node_width" configuration="CroppingLabel" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasLineColor="false" modelName="internal" modelPosition="{$modelposition}" textColor="#000000" visible="true">
						<xsl:choose>
							<xsl:when test="$fragment/yed:backgroundColor!=''"><xsl:attribute name="backgroundColor"><xsl:value-of select="$fragment/yed:backgroundColor"/></xsl:attribute></xsl:when>
							<xsl:otherwise><xsl:attribute name="hasBackgroundColor">false</xsl:attribute></xsl:otherwise>
						</xsl:choose>
						<xsl:value-of select="$label"/>
					</y:NodeLabel>
					<y:NodeLabel alignment="left" autoSizePolicy="node_width" configuration="CroppingLabel" fontFamily="Dialog" fontSize="10" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" modelName="custom" textColor="#000000" visible="true">
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
			<xsl:if test="not(exists($pfragment/rdfs:label))">
				<xsl:variable name="plabel"><xsl:value-of select="key('nodes',$puri)/rdfs:label"/></xsl:variable>
				<xsl:value-of select="$plabel"/>
				<xsl:if test="$plabel=''"><xsl:value-of select="name()"/></xsl:if>
			</xsl:if>
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
</xsl:template>

<xsl:include href="appearances/ModelTemplates.xsl"/> <!-- Helper templates for model and vocabulary appearance -->

</xsl:stylesheet>