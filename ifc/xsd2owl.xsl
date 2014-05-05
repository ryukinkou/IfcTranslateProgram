<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
	xmlns:fcn="http://www.liujinhang.cn/paper/ifc/xsd2owl-functions.xsl"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:xlink="http://www.w3.org/1999/xlink#" xmlns:owl="http://www.w3.org/2002/07/owl#">

	<xsl:import href="xsd2owl-functions.xsl" />

	<!-- 文档输出定义 -->
	<xsl:output media-type="text/xml" version="1.0" encoding="UTF-8"
		indent="yes" use-character-maps="owl" />

	<xsl:strip-space elements="*" />

	<xsl:character-map name="owl">
		<xsl:output-character character="&amp;" string="&amp;" />
	</xsl:character-map>

	<!-- 全局变量定义 -->
	<xsl:variable name="targetNamespace">
		<xsl:value-of select="/xsd:schema/@targetNamespace" />
	</xsl:variable>

	<xsl:variable name="targetPrefix">
		<xsl:for-each select="/xsd:schema/namespace::*">
			<xsl:if test=". = $targetNamespace">
				<xsl:value-of select="name()" />
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>

	<xsl:variable name="targetEntity">
		<!-- 输出 '&' -->
		<xsl:text disable-output-escaping="yes">&amp;</xsl:text>
		<!-- 输出 targetPrefix -->
		<xsl:value-of select="$targetPrefix" />
		<!-- 输出 ';' -->
		<xsl:text disable-output-escaping="yes">;</xsl:text>
	</xsl:variable>

	<xsl:variable name="localXMLSchemaPrefix">
		<xsl:for-each select="/xsd:schema/namespace::*">
			<xsl:if test=". = 'http://www.w3.org/2001/XMLSchema'">
				<xsl:value-of select="name()" />
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>

	<xsl:variable name="localNamespaces"
		select="
			/xsd:schema/namespace::*[
			not(
				name() = '' or 
				name() = 'xsd' or 
				name() = 'xml' or 
				name() = 'xlink' or
				name() = $localXMLSchemaPrefix
			)]" />

	<!-- 不与xsd:schema下属有命名冲突的元素与属性 -->
	<!-- 担心重名的一种做法 -->
	<xsl:key name="entityProperties"
		match="
		//xsd:element[
			@name 
			and (ancestor::xsd:complexType or ancestor::xsd:group) 
			and not(fcn:containsElementOrAttribute(/xsd:schema, @name))
		] |
		//xsd:attribute[
			@name 
			and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup) 
			and not(fcn:containsElementOrAttribute(/xsd:schema, @name))
		]"
		use="@name" />

	<xsl:template match="/xsd:schema">

		<!-- DTD START -->
		<!-- 输出 '<!DOCTYPE rdf:RDF [' -->
		<xsl:text disable-output-escaping="yes">&#10;&lt;!DOCTYPE rdf:RDF
			[&#10;</xsl:text>
		<!-- 输出 <!ENTITY xsd 'http://www.w3.org/2001/XMLSchema#'> -->
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xsd
			'http://www.w3.org/2001/XMLSchema#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xml
			'http://www.w3.org/XML/1998/namespace#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xlink
			'http://www.w3.org/1999/xlink#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY owl
			'http://www.w3.org/2002/07/owl#' &gt;&#10;</xsl:text>

		<xsl:for-each select="$localNamespaces">
			<!-- 输出 <!ENTITY name() . > -->
			<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY
			</xsl:text>
			<xsl:value-of select="name()" />
			<xsl:text disable-output-escaping="yes"> '</xsl:text>
			<xsl:choose>
				<!-- 输出targetNamespace的时候，使用'#'符号代替命名空间 -->
				<xsl:when test=". = $targetNamespace">
					<xsl:text disable-output-escaping="yes">#</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<!-- 输出命名空间，并且自动补全'#'符号 -->
					<xsl:value-of select="." />
					<xsl:if test="not(contains(.,'#'))">
						<xsl:text disable-output-escaping="yes">#</xsl:text>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
			<!-- 输出 '> -->
			<xsl:text disable-output-escaping="yes">' &gt;&#10;</xsl:text>
		</xsl:for-each>

		<!-- 输出 ]> -->
		<xsl:text disable-output-escaping="yes">]&gt;&#10;</xsl:text>
		<!-- DTD END -->

		<rdf:RDF>
			<!-- 输出本地Namespace，命名空间暂时定义为'&name();' -->
			<xsl:variable name="localNamespacesTemp">
				<xsl:for-each select="$localNamespaces">
					<xsl:element name="{name()}:x" namespace="&#38;{name()};" />
				</xsl:for-each>
			</xsl:variable>
			<xsl:copy-of select="$localNamespacesTemp/*/namespace::*" />

			<!-- 本体的顶级信息定义，暂时没有 -->
			<owl:Ontology rdf:about="">
				<rdfs:comment>IFC</rdfs:comment>
			</owl:Ontology>

			<!-- 模板输出占位符 -->
			<xsl:apply-templates />

			<owl:ObjectProperty rdf:ID="any" />

			<xsl:for-each
				select=" 
				//xsd:element [ 
					@name 
					and (ancestor::xsd:complexType or ancestor::xsd:group)
					and generate-id()=generate-id(key('entityProperties',@name)[1])
				]|
				//xsd:attribute [ 
					@name
					and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup) 
					and generate-id()=generate-id(key('entityProperties',@name)[1])
				] ">
				<xsl:sort select="@name" order="ascending" />

				<xsl:variable name="currentName">
					<xsl:value-of select="@name" />
				</xsl:variable>

				<xsl:choose>

					<!-- 转换为DatatypeProperty -->
					<xsl:when
						test="fcn:isConvertToDatatypeProperty(.,//xsd:complexType[@name],namespace::*)">
						<owl:DatatypeProperty rdf:ID="{@name}" />
					</xsl:when>

					<!-- 转换为ObjectProperty -->
					<xsl:when
						test="fcn:isConvertToObjectProperty(.,//xsd:simpleType[@name],namespace::*)">
						<owl:ObjectProperty rdf:ID="has{@name}" />
					</xsl:when>

					<!-- 转换为Property -->
					<xsl:otherwise>
						<rdf:Property rdf:ID="{@name}" />
					</xsl:otherwise>

				</xsl:choose>

			</xsl:for-each>
		</rdf:RDF>

	</xsl:template>

	<xsl:template match="xsd:complexType">
		<!-- 匹配显式的complexType定义 -->
		<xsl:if test="@name">
			<owl:Class rdf:ID="{@name}">
				<xsl:call-template name="explicitComplexTypePropertyTranslateTemplate">
					<xsl:with-param name="complexType" select="." />
				</xsl:call-template>
			</owl:Class>
		</xsl:if>
		<!-- 匹配隐式的complexTyp定义，他们通常都被包围在一个element里面 -->
		<xsl:if test="not(@name)">
			<xsl:if test="parent::xsd:element[@name]">
			</xsl:if>
			<owl:Class rdf:ID="{../@name}">
			</owl:Class>
		</xsl:if>
	</xsl:template>

	<xsl:template match="xsd:attributeGroup[@name]">
		<xsl:if test="@name">
			<owl:Class rdf:ID="{@name}">
				<xsl:apply-templates />
			</owl:Class>
		</xsl:if>
	</xsl:template>

	<!-- complexType/element|attribute => property 转换模板 -->
	<xsl:template name="explicitComplexTypePropertyTranslateTemplate">
		<xsl:param name="complexType" />
		<xsl:variable name="base"
			select="$complexType/xsd:complexContent/xsd:extension/@base 
					|
					$complexType/xsd:complexContent/xsd:restriction/@base" />
		<xsl:if test="$base">
			<rdfs:subClassOf rdf:resource="{fcn:getRdfURI($base, namespace::*)}" />
			<xsl:call-template name="propertyTranslationTemplate">
				<xsl:with-param name="properties"
					select="
					$complexType/xsd:complexContent/xsd:extension/* 
					|
					$complexType/xsd:complexContent/xsd:restriction/*" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="propertyTranslationTemplate">
		<xsl:param name="properties" />
		<xsl:param name="isArrayMode" required="no" select="false()" />
		<xsl:choose>
			<xsl:when test="count($properties) > 0">
				<xsl:for-each select="$properties">
					<xsl:choose>

						<!-- 解释element/attribute -->
						<xsl:when
							test="
							./@type and 
							./@name and
							(
							./name() = concat($localXMLSchemaPrefix,':element') or 
							./name() = concat($localXMLSchemaPrefix,':attribute')
							)">

							<xsl:if test="$isArrayMode = false()">
								<!-- 解释type为xsd的属性 -->
								<xsl:if test="fcn:isXsdURI(./@type,namespace::*)">
									<rdfs:subClassOf>
										<owl:Restriction>
											<owl:onProperty rdf:resource="#{./@name}" />
											<owl:allValuesFrom rdf:resource="{fcn:getXsdURI(./@type,namespace::*)}" />
										</owl:Restriction>
									</rdfs:subClassOf>
								</xsl:if>

								<!-- 解释type为本地定义的属性 -->
								<xsl:if test="fcn:isLocalURI(./@type,namespace::*)">
									<rdfs:subClassOf>
										<owl:Restriction>
											<owl:onProperty rdf:resource="#has{./@name}" />
											<owl:allValuesFrom rdf:resource="{fcn:getRdfURI(./@type,namespace::*)}" />
										</owl:Restriction>
									</rdfs:subClassOf>
								</xsl:if>

							</xsl:if>

							<xsl:if test="$isArrayMode = true()">
								<!-- 解释type为xsd的属性 -->
								<xsl:if test="fcn:isXsdURI(./@type,namespace::*)">
									<owl:Restriction>
										<owl:onProperty rdf:resource="#{./@name}" />
										<owl:allValuesFrom rdf:resource="{fcn:getXsdURI(./@type,namespace::*)}" />
										<!-- TODO 基数定义 -->
									</owl:Restriction>
								</xsl:if>

								<!-- 解释type为本地定义的属性 -->
								<xsl:if test="fcn:isLocalURI(./@type,namespace::*)">
									<owl:Restriction>
										<owl:onProperty rdf:resource="#has{./@name}" />
										<owl:allValuesFrom rdf:resource="{fcn:getRdfURI(./@type,namespace::*)}" />
										<!-- TODO 基数定义 -->
									</owl:Restriction>
								</xsl:if>

							</xsl:if>

						</xsl:when>

						<!-- 解释sequence -->
						<xsl:when test="./name() = concat($localXMLSchemaPrefix,':sequence')">
							<xsl:choose>
								<xsl:when test="count(child::*) = 1">
									<xsl:call-template name="propertyTranslationTemplate">
										<xsl:with-param name="properties" select="child::*" />
									</xsl:call-template>
								</xsl:when>

								<xsl:when test="count(child::*) > 1">
									<rdfs:subClassOf>
										<owl:Class>
											<owl:intersectionOf rdf:parseType="Collection">
												<xsl:call-template name="propertyTranslationTemplate">
													<xsl:with-param name="properties" select="child::*" />
													<xsl:with-param name="isArrayMode" select="true()" />
												</xsl:call-template>
											</owl:intersectionOf>
										</owl:Class>
									</rdfs:subClassOf>
								</xsl:when>
								<xsl:otherwise>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>

						<!-- 解释choice -->
						<xsl:when test="./name() = concat($localXMLSchemaPrefix,':choice')">
							<xsl:choose>
								<xsl:when test="count(child::*) = 1">
									<xsl:call-template name="propertyTranslationTemplate">
										<xsl:with-param name="properties" select="child::*" />
									</xsl:call-template>
								</xsl:when>
								<xsl:when test="count(child::*) > 1">
									<rdfs:subClassOf>
										<owl:Class>
											<owl:unionOf rdf:parseType="Collection">
												<xsl:call-template name="propertyTranslationTemplate">
													<xsl:with-param name="properties" select="child::*" />
													<xsl:with-param name="isArrayMode" select="true()" />
												</xsl:call-template>
											</owl:unionOf>
										</owl:Class>
									</rdfs:subClassOf>
								</xsl:when>
								<xsl:otherwise>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>

					</xsl:choose>
				</xsl:for-each>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- 转换simpleType -->
	<xsl:template match="xsd:simpleType">

		<xsl:choose>

			<!-- 转换显式定义的语法糖级simpleType，他们往往只是简单的基本类型包装，转换为datatype -->
			<xsl:when
				test="
					@name and
					./xsd:restriction/@base and
					count(./xsd:restriction/xsd:enumeration) = 0 ">
				<rdfs:Datatype rdf:about="{fcn:getRdfURI(@name,namespace::*)}">
					<owl:equivalentClass
						rdf:resource="{fcn:getRdfURI(./xsd:restriction/@base,namespace::*)}" />
				</rdfs:Datatype>
			</xsl:when>

			<!-- 转换显式定义的枚举型simpleType，将simpleType本身转换为class，其枚举值转换为它的个体 -->
			<xsl:when
				test="
					@name and
					./xsd:restriction/@base and
					count(./xsd:restriction/xsd:enumeration) > 0 ">
				<xsl:variable name="className" select="@name" />
				<owl:Class rdf:ID="{$className}" />
				<xsl:for-each select="./xsd:restriction/child::*">
					<owl:NamedIndividual rdf:about="{fcn:getRdfURI(./@value,namespace::*)}">
						<rdf:type rdf:resource="#{$className}" />
					</owl:NamedIndividual>
				</xsl:for-each>
			</xsl:when>

			<!-- 转换显式定义的列表类simpleType -->
			<xsl:when test="@name and ./xsd:restriction/xsd:simpleType/xsd:list">

				<xsl:call-template name="IfcListGenerationTemplate" />
				
				<xsl:variable name="minLength"
					select="./xsd:restriction/xsd:minLength/@value" />
				<xsl:variable name="maxLength"
					select="./xsd:restriction/xsd:maxLength/@value" />
					
				<xsl:variable name="itemType"
					select="fcn:getXsdURI(./xsd:restriction/xsd:simpleType/xsd:list/@itemType,namespace::*)" />

				<xsl:choose>
				
					<!-- minLength与maxLength相等的时候 -->
					<xsl:when test="$minLength = &maxLength">
					</xsl:when>
					
					<!-- minLength小于maxLength相等的时候 -->
					<xsl:when test="$minLength &lt; &maxLength">
					</xsl:when>
				
				</xsl:choose>

				<!-- 1 <= i <= minLength 最小长度内的元素被定义为exactly 1，必须 -->
				<xsl:for-each select="1 to $minLength">
					<xsl:message>the first : <xsl:value-of select="." /></xsl:message>
				</xsl:for-each>

				<!-- 0 < i <= minLength 最小长度与最大长度之间的元素倍定义为max 1，可选 -->
				<xsl:for-each select="$minLength to $maxLength">
					<!-- 跳过$minLength位置 -->
					<xsl:if test=". &gt; $minLength" >
					
						<xsl:choose>
							<xsl:when test=". = $minLength">
							</xsl:when>
							<xsl:otherwise>
							</xsl:otherwise>
						</xsl:choose>
					
						<xsl:message>the second : <xsl:value-of select="." /></xsl:message>
					</xsl:if>
					
				</xsl:for-each>
				
				<!-- minLength < i <= maxLength -->

				<!-- 
				<owl:Class rdf:about="#List-IfcComplexNumber_1">
					<rdfs:subClassOf rdf:resource="#IfcList" />
					<rdfs:subClassOf>
						<owl:Restriction>
							<owl:onProperty rdf:resource="#hasDouble" />
							<owl:qualifiedCardinality rdf:datatype="&xsd;nonNegativeInteger">1
							</owl:qualifiedCardinality>
							<owl:onDataRange rdf:resource="&xsd;double" />
						</owl:Restriction>
					</rdfs:subClassOf>

					<rdfs:subClassOf>
						<owl:Restriction>
							<owl:onProperty rdf:resource="#hasNext" />
							<owl:onClass rdf:resource="#List-IfcComplexNumber_2" />
							<owl:qualifiedCardinality rdf:datatype="&xsd;nonNegativeInteger">1
							</owl:qualifiedCardinality>
						</owl:Restriction>
					</rdfs:subClassOf>
				</owl:Class>
 				-->
			</xsl:when>

			<xsl:otherwise>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- 列表辅助模板，来源 http://protege.stanford.edu/conference/2006/submissions/slides/7.1_Drummond.pdf 
		修改针对datatype property -->
	<xsl:template name="IfcListGenerationTemplate">

		<owl:ObjectProperty rdf:about="{fcn:getRdfURI('hasContents',namespace::*)}" />

		<owl:ObjectProperty rdf:about="{fcn:getRdfURI('hasNext',namespace::*)}">
			<rdfs:subPropertyOf rdf:resource="#isFollowedBy" />
		</owl:ObjectProperty>

		<owl:ObjectProperty rdf:about="{fcn:getRdfURI('isFollowedBy',namespace::*)}">
			<rdf:type rdf:resource="&amp;owl;TransitiveProperty" />
			<rdfs:range rdf:resource="#IfcList" />
			<rdfs:domain rdf:resource="#IfcList" />
		</owl:ObjectProperty>

		<owl:DatatypeProperty rdf:about="{fcn:getRdfURI('hasDouble',namespace::*)}">
			<rdfs:range rdf:resource="&amp;xsd;double" />
		</owl:DatatypeProperty>

		<owl:DatatypeProperty rdf:about="{fcn:getRdfURI('hasString',namespace::*)}">
			<rdfs:range rdf:resource="&amp;xsd;string" />
		</owl:DatatypeProperty>

		<owl:Class rdf:about="{fcn:getRdfURI('EmptyDoubleList',namespace::*)}">
			<rdfs:subClassOf rdf:resource="#IfcList" />
			<rdfs:subClassOf>
				<owl:Class>
					<owl:intersectionOf rdf:parseType="Collection">
						<owl:Restriction>
							<owl:onProperty rdf:resource="#hasContents" />
							<owl:maxCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">0
							</owl:maxCardinality>
						</owl:Restriction>
						<owl:Restriction>
							<owl:onProperty rdf:resource="#hasDouble" />
							<owl:maxQualifiedCardinality
								rdf:datatype="&amp;xsd;nonNegativeInteger">0</owl:maxQualifiedCardinality>
							<owl:onDataRange rdf:resource="&amp;xsd;double" />
						</owl:Restriction>
					</owl:intersectionOf>
				</owl:Class>
			</rdfs:subClassOf>
		</owl:Class>

		<owl:Class rdf:about="{fcn:getRdfURI('IfcList',namespace::*)}">
			<rdfs:subClassOf>
				<owl:Restriction>
					<owl:onProperty rdf:resource="#isFollowedBy" />
					<owl:onClass rdf:resource="#IfcList" />
					<owl:qualifiedCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">1
					</owl:qualifiedCardinality>
				</owl:Restriction>
			</rdfs:subClassOf>
		</owl:Class>

	</xsl:template>

	<xsl:template name="for-loop">
		<xsl:param name="i" />
		<xsl:param name="count" />
		<xsl:if test="$i &lt; $count">
			<xsl:message>the a</xsl:message>
			<xsl:call-template name="for-loop">
				<xsl:with-param name="i">
					<xsl:value-of select="$i + 1" />
				</xsl:with-param>
				<xsl:with-param name="count">
					<xsl:value-of select="$count" />
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
