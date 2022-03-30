<!--

    NAME     rdf2yed.xsl
		VERSION  1.25.3-SNAPSHOT
    DATE     2021-11-07

    Copyright 2012-2021

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

<xsl:key name="nodes" match="/root/results/rdf:RDF[1]/rdf:Description[exists(rdf:type)]" use="@rdf:about"/>
<xsl:key name="items" match="/root/results/rdf:RDF[1]/rdf:Description" use="@rdf:about"/>
<xsl:key name="blanks" match="/root/results/rdf:RDF[1]/rdf:Description" use="@rdf:nodeID"/>
<xsl:key name="fragments" match="/root/view/representation[1]/fragment" use="@applies-to"/>

<xsl:template match="/">
	<graphml>
		<key attr.name="url" attr.type="string" for="node" id="d3"/>
		<key attr.name="url" attr.type="string" for="edge" id="d7"/>
		<key attr.name="subject-uri" attr.type="string" for="edge" id="d90"/>
		<key attr.name="object-uri" attr.type="string" for="edge" id="d91"/>
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

<xsl:template match="*" mode ="yed-vocab-node">
	<xsl:param name="geometry"/>
	<xsl:param name="uripostfix"/>

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
	<node id="{@uri}{$uripostfix}">
		<data key="d3"><xsl:value-of select="@uri"/></data>
		<data key="d6">
			<y:GenericNode configuration="com.yworks.entityRelationship.big_entity">
				<xsl:variable name="enumerationcnt">
					<xsl:choose>
						<xsl:when test="exists(enumvalue|enumeration)"><xsl:value-of select="count(enumvalue|enumeration)+1"/></xsl:when>
						<xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="exists($geometry)">
						<y:Geometry height="{$geometry/@height}" width="{$geometry/@width}" x="{$geometry/@x}" y="{$geometry/@y}"/>
					</xsl:when>
					<xsl:otherwise>
						<y:Geometry height="{40+13*($enumerationcnt+count(property[not(exists(refshape[@type='role']) or exists(ref-nodes/item) or exists(refshape[@empty='false']))]))}" width="200.0" x="0.5" y="0"/>
					</xsl:otherwise>
				</xsl:choose>
				<y:Fill color="#E8EEF7" color2="#B7C9E3" transparent="false"/>
				<xsl:variable name="linestyle">
					<xsl:choose>
						<xsl:when test="@class-uri!=''">line</xsl:when>
						<xsl:otherwise>dashed</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<y:BorderStyle color="#000000" type="{$linestyle}" width="1.0"/>
				<y:NodeLabel alignment="center" autoSizePolicy="node_width" configuration="CroppingLabel" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasLineColor="false" modelName="internal" modelPosition="t" textColor="#000000" visible="true" hasBackgroundColor="false">
					<xsl:value-of select="$label"/>
				</y:NodeLabel>
				<y:NodeLabel alignment="left" autoSizePolicy="content" configuration="com.yworks.entityRelationship.label.attributes" fontFamily="Dialog" fontSize="10" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" modelName="custom" textColor="#000000" visible="true" y="30.1328125">
					<!--Properties-->
					<xsl:for-each select="property[@nodekind='BlankNode' or not(exists(refshape[@type='role']) or exists(ref-nodes/item) or exists(refshape[@empty='false']))]"><xsl:sort select="@order"/>
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
				<xsl:if test="exists(description)">
						<y:NodeLabel alignment="left" autoSizePolicy="node_width" configuration="CroppingLabel" fontFamily="Dialog" fontSize="8" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" modelName="internal" modelPosition="b" textColor="#000000" visible="true">
							<xsl:for-each select="description">
								<xsl:if test="position()!=1"><xsl:text>
</xsl:text></xsl:if><xsl:value-of select="."/>
							</xsl:for-each>
						</y:NodeLabel>
				</xsl:if>
				<y:StyleProperties>
					<y:Property class="java.lang.Boolean" name="y.view.ShadowNodePainter.SHADOW_PAINTING" value="true"/>
				</y:StyleProperties>
			</y:GenericNode>
		</data>
	</node>
</xsl:template>

<xsl:template match="rdf:RDF" mode="yed-vocab">
	<!-- Parse RDF graph and put result in vocabulary variable -->
	<xsl:variable name="vocabulary"><xsl:apply-templates select="." mode="VocabularyVariable"/></xsl:variable>

	<!-- Nodes -->
	<xsl:for-each select="$vocabulary/nodeShapes/shape[@empty!='true']">
		<xsl:variable name="resource" select="."/>
		<xsl:apply-templates select="$resource" mode="yed-vocab-node">
			<xsl:with-param name="geometry" select="geometry[1]"/>
		</xsl:apply-templates>
		<xsl:for-each select="geometry[position()!=1]">
			<xsl:apply-templates select="$resource" mode="yed-vocab-node">
				<xsl:with-param name="uripostfix">___<xsl:value-of select="position()"/></xsl:with-param>
				<xsl:with-param name="geometry" select="."/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:for-each>
	<!-- Logic nodes, with edges -->
	<xsl:for-each select="$vocabulary/nodeShapes/shape/property/ref-nodes">
		<xsl:variable name="nodeuri" select="@uri"/>
		<node id="{$nodeuri}">
			<data key="d3"><xsl:value-of select="$nodeuri"/></data>
			<data key="d6">
				<y:ShapeNode>
					<xsl:choose>
						<xsl:when test="exists(geometry)">
							<y:Geometry height="{geometry/@height}" width="{geometry/@width}" x="{geometry/@x}" y="{geometry/@y}"/>
						</xsl:when>
						<xsl:otherwise>
							<y:Geometry height="30.0" width="{string-length(@logic)*10}" x="376.0" y="185.0"/>
						</xsl:otherwise>
					</xsl:choose>
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
				<edge source="{$nodeuri}" target="{@uri}">
					<data key="d90"><xsl:value-of select="$nodeuri"/></data>
					<data key="d91"><xsl:value-of select="@uri"/></data>
					<data key="d10">
						<y:PolyLineEdge>
							<y:Arrows source="none" target="standard"/>
							<xsl:for-each select="path">
								<y:Path sx="{@sx}" sy="{@sy}" tx="{@tx}" ty="{@ty}">
									<xsl:for-each select="point">
										<y:Point x="{@x}" y="{@y}"/>
									</xsl:for-each>
								</y:Path>
							</xsl:for-each>
						</y:PolyLineEdge>
					</data>
				</edge>
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
			<!-- Annotate linestyle for specific metadata statements -->
			<!-- This needs to be improved.-->
			<!-- Current situation: any reified statement will trigger this linestyle -->
			<!-- A better solution would be to trigger a specific linestyle for specific metadata -->
			<xsl:variable name="linestyle">
				<xsl:choose>
						<xsl:when test="exists(../statement)">
							<color><xsl:value-of select="../statement/yed:color"/></color>
							<width>3.0</width>
						</xsl:when>
						<xsl:otherwise>
							<color>#000000</color>
							<width>1.0</width>
						</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<edge source="{../../@uri}" target="{@uri}">
				<data key="d7"><xsl:value-of select="../@uri"/></data>
				<data key="d90"><xsl:value-of select="../../@uri"/></data>
				<data key="d91"><xsl:value-of select="@uri"/></data>
				<data key="d10">
					<y:PolyLineEdge>
						<xsl:for-each select="path">
							<y:Path sx="{@sx}" sy="{@sy}" tx="{@tx}" ty="{@ty}">
								<xsl:for-each select="point">
									<y:Point x="{@x}" y="{@y}"/>
								</xsl:for-each>
							</y:Path>
						</xsl:for-each>
						<xsl:choose>
							<xsl:when test="@type='role'">
								<y:LineStyle color="#000000" type="dashed" width="1.0"/>
								<y:Arrows source="none" target="white_delta"/>
							</xsl:when>
							<xsl:when test="../@reification='subject'">
								<y:LineStyle color="#000000" type="line" width="1.0"/>
								<y:Arrows source="none" target="none"/>
							</xsl:when>
							<xsl:when test="../@reification='object'">
								<y:LineStyle color="#000000" type="line" width="1.0"/>
								<y:Arrows source="none" target="standard"/>
							</xsl:when>
							<xsl:otherwise>
								<y:LineStyle color="{$linestyle/color}" type="line" width="{$linestyle/width}"/>
								<y:Arrows source="{$sourcestyle}" target="standard"/>
								<y:EdgeLabel alignment="center" backgroundColor="#FFFFFF" configuration="AutoFlippingLabel" distance="2.0" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasLineColor="false" modelName="custom" preferredPlacement="anywhere" ratio="0.5" textColor="#000000" visible="true">
									<xsl:apply-templates select=".." mode="property-placement"/>
									<y:LabelModel>
										<y:SmartEdgeLabelModel autoRotationEnabled="false" defaultAngle="0.0" defaultDistance="10.0"/>
									</y:LabelModel>
									<y:ModelParameter>
										<xsl:variable name="label-distance">
											<xsl:value-of select="labelpos/@distance"/>
											<xsl:if test="not(labelpos/@distance!='')">30.0</xsl:if>
										</xsl:variable>
										<xsl:variable name="label-ratio">
											<xsl:value-of select="labelpos/@ratio"/>
											<xsl:if test="not(labelpos/@ratio!='')">0.5</xsl:if>
										</xsl:variable>
										<xsl:variable name="label-segment">
											<xsl:value-of select="labelpos/@segment"/>
											<xsl:if test="not(labelpos/@segment!='')">0</xsl:if>
										</xsl:variable>
										<y:SmartEdgeLabelModelParameter angle="0.0" distance="{$label-distance}" distanceToCenter="true" position="center" ratio="{$label-ratio}" segment="{$label-segment}"/>
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
		<xsl:variable name="supershape" select="supershape"/>
		<xsl:for-each select="$vocabulary/classes/class[@uri=$class]/super">
			<xsl:variable name="super" select="@uri"/>
			<xsl:for-each select="$vocabulary/nodeShapes/shape[@class-uri=$super and @empty!='true']">
				<edge source="{$source}" target="{@uri}">
					<data key="d90"><xsl:value-of select="$source"/></data>
					<data key="d91"><xsl:value-of select="@uri"/></data>
					<data key="d10">
						<y:PolyLineEdge>
							<xsl:for-each select="$supershape/path">
								<y:Path sx="{@sx}" sy="{@sy}" tx="{@tx}" ty="{@ty}">
									<xsl:for-each select="point">
										<y:Point x="{@x}" y="{@y}"/>
									</xsl:for-each>
								</y:Path>
							</xsl:for-each>
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

<xsl:template match="*" mode="yed-default-node">
	<xsl:param name="geometry"/>
	<xsl:param name="uripostfix"/>

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
	<node id="{@rdf:about}{@rdf:nodeID}{$uripostfix}"> <!-- URI nodes and blank nodes -->
		<data key="d3"><xsl:value-of select="@rdf:about"/><xsl:value-of select="@rdf:nodeID"/></data>
		<data key="d6">
			<xsl:variable name="nodeConfiguration">
				<xsl:value-of select="$fragment/yed:nodeType"/>
				<xsl:if test="not(exists($fragment/yed:nodeType))">com.yworks.entityRelationship.big_entity</xsl:if>
			</xsl:variable>
			<xsl:variable name="nodeType">
					<xsl:choose>
						<xsl:when test="$nodeConfiguration='ellipse'">y:ShapeNode</xsl:when>
						<xsl:when test="$nodeConfiguration='roundrectangle'">y:ShapeNode</xsl:when>
						<xsl:otherwise>y:GenericNode</xsl:otherwise>
					</xsl:choose>
			</xsl:variable>
			<xsl:element name="{$nodeType}">
				<xsl:choose>
					<xsl:when test="$nodeType='y:GenericNode'">
						<xsl:attribute name="configuration"><xsl:value-of select="$nodeConfiguration"/></xsl:attribute>
					</xsl:when>
					<xsl:otherwise>
						<y:Shape type="{$nodeConfiguration}"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:choose>
					<xsl:when test="exists($geometry)">
						<y:Geometry height="{$geometry/yed:height}" width="{$geometry/yed:width}" x="{$geometry/yed:x}" y="{$geometry/yed:y}"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
								<xsl:when test="$nodeType='y:GenericNode'"><y:Geometry height="100.0" width="200.0" x="0.5" y="0"/></xsl:when>
								<xsl:otherwise><y:Geometry height="30.0" width="200.0" x="0.5" y="0"/></xsl:otherwise>
							</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:choose>
					<xsl:when test="not(exists($fragment/yed:fill))"><y:Fill color="#E8EEF7" color2="#B7C9E3" transparent="false"/></xsl:when>
					<xsl:otherwise>
						<y:Fill color="{$fragment/yed:fill}" transparant="false">
							<xsl:if test="exists($fragment/yed:fill2)"><xsl:attribute name="color2"><xsl:value-of select="$fragment/yed:fill2"/></xsl:attribute></xsl:if>
						</y:Fill>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:variable name="borderstyle">
					<xsl:choose>
							<xsl:when test="exists($fragment/yed:color)">
								<color><xsl:value-of select="$fragment/yed:color"/></color>
							</xsl:when>
							<xsl:otherwise>
								<color>#000000</color>
							</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="exists($fragment/yed:line)">
							<line><xsl:value-of select="$fragment/yed:line"/></line>
						</xsl:when>
						<xsl:otherwise>
							<line>line</line>
						</xsl:otherwise>
					</xsl:choose>
					<width>1.0</width>
				</xsl:variable>
				<y:BorderStyle color="{$borderstyle/color}" type="{$borderstyle/line}" width="{$borderstyle/width}"/>
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
			</xsl:element>
		</data>
	</node>
</xsl:template>

<xsl:template match="rdf:RDF" mode="yed-default">
	<!-- Nodes -->
	<xsl:for-each select="rdf:Description[exists(*)]">
		<xsl:variable name="resource" select="."/>
		<xsl:apply-templates select="$resource" mode="yed-default-node">
			<xsl:with-param name="geometry" select="key('blanks',yed:geometry[1]/@rdf:nodeID)"/>
		</xsl:apply-templates>
		<xsl:for-each select="yed:geometry[position()!=1]">
			<xsl:apply-templates select="$resource" mode="yed-default-node">
				<xsl:with-param name="uripostfix">___<xsl:value-of select="position()"/></xsl:with-param>
				<xsl:with-param name="geometry" select="key('blanks',@rdf:nodeID)"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:for-each>
	<!-- Edges for URI nodes -->
	<xsl:for-each select="rdf:Description/*[exists(key('nodes',@rdf:resource))]">
		<xsl:variable name="puri"><xsl:value-of select="namespace-uri()"/><xsl:value-of select="local-name()"/></xsl:variable>
		<xsl:variable name="pstyle"><xsl:value-of select="key('items',$puri)/elmo:style"/></xsl:variable>
		<xsl:variable name="pfragment" select="key('fragments',$puri)|key('fragments',$pstyle)"/>
		<xsl:variable name="label">
			<xsl:value-of select="$pfragment/rdfs:label"/>
			<xsl:if test="not(exists($pfragment/rdfs:label))">
				<xsl:value-of select="key('items',$puri)/rdfs:label"/>
				<xsl:if test="not(exists(key('items',$puri)/rdfs:label))"><xsl:value-of select="name()"/></xsl:if>
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
		<xsl:variable name="linecolor">
			<xsl:value-of select="$pfragment/yed:color"/>
			<xsl:if test="not(exists($pfragment/yed:color))">#000000</xsl:if>
		</xsl:variable>
		<xsl:variable name="edgetype">
			<xsl:choose>
				<xsl:when test="$pfragment/yed:edge/@rdf:resource='http://bp4mc2.org/yed#BezierEdge'">y:BezierEdge</xsl:when>
				<xsl:when test="$pfragment/yed:edge/@rdf:resource='http://bp4mc2.org/yed#PolyLineEdge'">y:PolyLineEdge</xsl:when>
				<xsl:otherwise>y:PolyLineEdge</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<edge source="{../(@rdf:about|@rdf:nodeID)}" target="{@rdf:resource}">
			<data key="d10">
				<xsl:element name="{$edgetype}">
					<y:LineStyle color="{$linecolor}" type="{$line}" width="1.0"/>
					<y:Arrows source="{$source}" target="{$target}"/>
					<xsl:variable name="hasbgc">
						<xsl:choose>
							<xsl:when test="$label!=''">true</xsl:when>
							<xsl:otherwise>false</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<y:EdgeLabel alignment="center" backgroundColor="#FFFFFF" hasBackgroundColor="{$hasbgc}" configuration="AutoFlippingLabel" distance="2.0" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasLineColor="false" modelName="custom" preferredPlacement="anywhere" ratio="0.5" textColor="#000000" visible="true"><xsl:value-of select="$label"/><y:LabelModel>
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
		<edge source="{../@rdf:about}" target="{@rdf:nodeID}">
			<data key="d10">
				<y:PolyLineEdge>
					<y:LineStyle color="#000000" type="line" width="1.0"/>
					<y:Arrows source="none" target="standard"/>
					<y:EdgeLabel alignment="center" backgroundColor="#FFFFFF" configuration="AutoFlippingLabel" distance="2.0" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasLineColor="false" modelName="custom" preferredPlacement="anywhere" ratio="0.5" textColor="#000000" visible="true"><xsl:value-of select="name()"/><y:LabelModel>
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
