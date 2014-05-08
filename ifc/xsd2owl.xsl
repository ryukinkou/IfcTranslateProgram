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
	
	<xsl:variable name="ontologBase">
		<xsl:value-of select="'http://liujinhang.cn/paper/ifc/ifcOWL.owl'" />
	</xsl:variable>
	
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

	<!-- 忽略列表 -->
	<xsl:variable name="ignoreNameList"
		select="'ifcXML','uos','Seq-anyURI','instanceAttributes','pos','arraySize','itemType','cType',nil" />

	<!-- 忽略模式列表 -->
	<xsl:variable name="ignoreNamePatternList" select="'-wrapper',nil" />

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

	<!-- 实体属性 -->
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
		<!-- 输出常用的命名空间DTD -->
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xsd
			'http://www.w3.org/2001/XMLSchema#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xml
			'http://www.w3.org/XML/1998/namespace#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xlink
			'http://www.w3.org/1999/xlink#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY owl
			'http://www.w3.org/2002/07/owl#' &gt;&#10;</xsl:text>

		<!-- 输出本地命名空间的DTD -->
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
			<owl:Ontology rdf:about="{$ontologBase}">
				<rdfs:comment>IFC</rdfs:comment>
			</owl:Ontology>

			<!-- 模板输出占位符 -->
			<xsl:apply-templates />

			<!-- 列表基类 -->
			<xsl:call-template name="IfcListSuperClassTemplate" />
			
			
			
			<owl:ObjectProperty rdf:ID="any" />

			<xsl:for-each
				select=" 
				//xsd:element [ 
					@name 
					and (ancestor::xsd:complexType or ancestor::xsd:group)
					and generate-id()=generate-id(key('entityProperties',@name)[1])
				]
				|
				//xsd:attribute [ 
					@name
					and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup) 
					and generate-id()=generate-id(key('entityProperties',@name)[1])
				] ">
				<xsl:sort select="@name" order="ascending" />

				<xsl:variable name="currentName">
					<xsl:value-of select="@name" />
					</xsl:variable>
					
				<xsl:if test="@name = 'ActualDate'">
					<xsl:message>the name : <xsl:value-of select="fcn:isConvertToDatatypeProperty(.,//xsd:simpleType[@name],namespace::*)" /></xsl:message>
					<xsl:message>the name : <xsl:value-of select="fcn:isConvertToObjectProperty(.,//xsd:complexType[@name],namespace::*)" /></xsl:message>
				</xsl:if>
					
				<xsl:choose>
					
					<!-- 转换为DatatypeProperty -->
					<xsl:when
						test="fcn:isConvertToDatatypeProperty(.,//xsd:simplexType[@name],namespace::*)">
						<owl:DatatypeProperty rdf:ID="{@name}" />
					</xsl:when>

					<!-- 转换为ObjectProperty -->
					<xsl:when
						test="fcn:isConvertToObjectProperty(.,//xsd:compleType[@name],namespace::*)">
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

	<!-- complexType匹配模板 -->
	<xsl:template match="xsd:complexType">
		<!-- 匹配显式的complexType定义 -->
		<xsl:if test="@name and fcn:isNameIgnored(@name) = false()">
			<owl:Class rdf:ID="{@name}">
				<xsl:call-template name="explicitComplexTypePropertyTranslateTemplate">
					<xsl:with-param name="complexType" select="." />
				</xsl:call-template>
			</owl:Class>
		</xsl:if>
		<!-- 匹配隐式的complexTyp定义，他们通常都被包围在一个element里面 -->
		<xsl:if test="not(@name)">
			<xsl:if test="../@name and fcn:isNameIgnored(../@name) = false()">
				<owl:Class rdf:ID="{../@name}">
					<!-- TODO，内部处理尚未完成 -->
				</owl:Class>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<!-- 属性组匹配模板 -->
	<xsl:template match="xsd:attributeGroup[@name]">
		<xsl:if test="@name and fcn:isNameIgnored(@name) = false()">
			<owl:Class rdf:ID="{@name}">
				<!-- TODO，内部处理尚未完成 -->
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
											<owl:onProperty rdf:resource="{$ontologBase}#{./@name}" />
											<owl:allValuesFrom rdf:resource="{fcn:getXsdURI(./@type,namespace::*)}" />
											<!-- TODO 基数定义 -->
										</owl:Restriction>
									</rdfs:subClassOf>
								</xsl:if>

								<!-- 解释type为本地定义的属性 -->
								<xsl:if test="fcn:isLocalURI(./@type,namespace::*)">
									<rdfs:subClassOf>
										<owl:Restriction>
											<owl:onProperty rdf:resource="{$ontologBase}#has{./@name}" />
											<owl:allValuesFrom rdf:resource="{fcn:getRdfURI(./@type,namespace::*)}" />
											<!-- TODO 基数定义 -->
										</owl:Restriction>
									</rdfs:subClassOf>
								</xsl:if>

							</xsl:if>

							<xsl:if test="$isArrayMode = true()">
								<!-- 解释type为xsd的属性 -->
								<xsl:if test="fcn:isXsdURI(./@type,namespace::*)">
									<owl:Restriction>
										<owl:onProperty rdf:resource="{$ontologBase}#{./@name}" />
										<owl:allValuesFrom rdf:resource="{fcn:getXsdURI(./@type,namespace::*)}" />
										<!-- TODO 基数定义 -->
									</owl:Restriction>
								</xsl:if>

								<!-- 解释type为本地定义的属性 -->
								<xsl:if test="fcn:isLocalURI(./@type,namespace::*)">
									<owl:Restriction>
										<owl:onProperty rdf:resource="{$ontologBase}#has{./@name}" />
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
					@name and fcn:isNameIgnored(@name) = false() and
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
					@name and fcn:isNameIgnored(@name) = false() and
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
			<xsl:when
				test="@name and fcn:isNameIgnored(@name) = false() and
			 		 ./xsd:restriction/xsd:simpleType/xsd:list">

				<xsl:variable name="classNamePrefix" select="@name" />

				<xsl:variable name="minLength"
					select="./xsd:restriction/xsd:minLength/@value" />

				<xsl:variable name="maxLength"
					select="./xsd:restriction/xsd:maxLength/@value" />

				<xsl:variable name="itemType"
					select="fcn:getXsdURI(./xsd:restriction/xsd:simpleType/xsd:list/@itemType,namespace::*)" />

				<xsl:call-template name="IfcListTemplate">
					<xsl:with-param name="classNamePrefix" select="$classNamePrefix" />
					<xsl:with-param name="minLength" select="$minLength" />
					<xsl:with-param name="maxLength" select="$maxLength" />
					<xsl:with-param name="itemType" select="$itemType" />
				</xsl:call-template>

			</xsl:when>

			<xsl:otherwise>
				<!-- nothing but ignore things -->
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<xsl:template name="IfcListTemplate">
		<xsl:param name="classNamePrefix" />
		<xsl:param name="minLength" />
		<xsl:param name="maxLength" />
		<xsl:param name="itemType" />

		<xsl:choose>
			<!-- minLength与maxLength相等的时候 -->
			<xsl:when test="$minLength = $maxLength">

				<!-- 一个包装类，为了不改变名称 -->
				<owl:Class rdf:about="#{$classNamePrefix}">
					<rdfs:subClassOf rdf:resource="#{concat($classNamePrefix,'1')}" />
				</owl:Class>

				<xsl:for-each select="1 to $minLength">
					<xsl:choose>

						<!-- 列表尾部元素处理，hasNext为EmptyList -->
						<xsl:when test=". = $minLength">
							<xsl:call-template name="IfcListItemTemplate">
								<xsl:with-param name="className" select="concat($classNamePrefix,.)" />
								<xsl:with-param name="nextClassName" select="'EmptyList'" />
								<xsl:with-param name="itemType" select="$itemType" />
								<xsl:with-param name="isNextItemFixed" select="true()" />
							</xsl:call-template>
						</xsl:when>

						<xsl:otherwise>
							<!-- 列表对象处理 -->
							<xsl:call-template name="IfcListItemTemplate">
								<xsl:with-param name="className" select="concat($classNamePrefix,.)" />
								<xsl:with-param name="nextClassName"
									select="concat($classNamePrefix,(. + 1))" />
								<xsl:with-param name="itemType" select="$itemType" />
								<xsl:with-param name="isNextItemFixed" select="true()" />
							</xsl:call-template>
						</xsl:otherwise>

					</xsl:choose>
				</xsl:for-each>
			</xsl:when>

			<!-- minLength小于maxLength相等的时候 -->
			<xsl:when test="$minLength &lt; $maxLength">

				<!-- 一个包装类，为了不改变名称 -->
				<owl:Class rdf:about="#{$classNamePrefix}">
					<rdfs:subClassOf rdf:resource="#{concat($classNamePrefix,'1')}" />
				</owl:Class>

				<!-- 区间：1 <= i <= minLength -->
				<xsl:for-each select="1 to $minLength">
					<xsl:choose>
						<!-- 区间尾部元素，hasNext为非必须项 -->
						<xsl:when test=". = $minLength">
							<xsl:call-template name="IfcListItemTemplate">
								<xsl:with-param name="className" select="concat($classNamePrefix,.)" />
								<xsl:with-param name="nextClassName"
									select="concat($classNamePrefix,(. + 1))" />
								<xsl:with-param name="itemType" select="$itemType" />
								<xsl:with-param name="isNextItemFixed" select="false()" />
							</xsl:call-template>
						</xsl:when>
						<!-- 区间元素，hasNext为必须项 -->
						<xsl:otherwise>
							<xsl:call-template name="IfcListItemTemplate">
								<xsl:with-param name="className" select="concat($classNamePrefix,.)" />
								<xsl:with-param name="nextClassName"
									select="concat($classNamePrefix,(. + 1))" />
								<xsl:with-param name="itemType" select="$itemType" />
								<xsl:with-param name="isNextItemFixed" select="true()" />
							</xsl:call-template>
						</xsl:otherwise>

					</xsl:choose>
				</xsl:for-each>

				<!-- 区间：minLength < i <= maxLength -->
				<xsl:for-each select="$minLength to $maxLength">
					<!-- 跳过$minLength位置 -->
					<xsl:if test=". &gt; $minLength">
						<xsl:choose>
							<!-- 区间尾部元素 hasNext为EmptyList -->
							<xsl:when test=". = $maxLength">
								<xsl:call-template name="IfcListItemTemplate">
									<xsl:with-param name="className"
										select="concat($classNamePrefix,.)" />
									<xsl:with-param name="nextClassName" select="'EmptyList'" />
									<xsl:with-param name="itemType" select="$itemType" />
									<xsl:with-param name="isNextItemFixed" select="true()" />
								</xsl:call-template>
							</xsl:when>
							<!-- 区间元素 hasNext为非必须项 -->
							<xsl:otherwise>
								<xsl:call-template name="IfcListItemTemplate">
									<xsl:with-param name="className"
										select="concat($classNamePrefix,.)" />
									<xsl:with-param name="nextClassName"
										select="concat($classNamePrefix,(. + 1))" />
									<xsl:with-param name="itemType" select="$itemType" />
									<xsl:with-param name="isNextItemFixed" select="false()" />
								</xsl:call-template>
							</xsl:otherwise>

						</xsl:choose>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>

			<xsl:otherwise>
				<!-- nothing -->
			</xsl:otherwise>

		</xsl:choose>

	</xsl:template>

	<!-- 列表基类 -->
	<xsl:template name="IfcListSuperClassTemplate">

		<owl:ObjectProperty rdf:about="{fcn:getRdfURI('hasNext',namespace::*)}">
			<rdfs:subPropertyOf rdf:resource="#isFollowedBy" />
		</owl:ObjectProperty>

		<owl:ObjectProperty rdf:about="{fcn:getRdfURI('isFollowedBy',namespace::*)}">
			<rdf:type rdf:resource="&amp;owl;TransitiveProperty" />
			<rdfs:range rdf:resource="#IfcList" />
			<rdfs:domain rdf:resource="#IfcList" />
		</owl:ObjectProperty>

		<owl:ObjectProperty rdf:about="{fcn:getRdfURI('hasContent',namespace::*)}" />
		<owl:DatatypeProperty rdf:about="{fcn:getRdfURI('hasValue',namespace::*)}" />

		<owl:Class rdf:about="{fcn:getRdfURI('EmptyList',namespace::*)}">
			<rdfs:subClassOf rdf:resource="#IfcList" />
			<rdfs:subClassOf>
				<owl:Class>
					<owl:intersectionOf rdf:parseType="Collection">
						<owl:Restriction>
							<owl:onProperty rdf:resource="#hasContent" />
							<owl:maxCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">0
							</owl:maxCardinality>
						</owl:Restriction>
						<owl:Restriction>
							<owl:onProperty rdf:resource="#hasValue" />
							<owl:maxQualifiedCardinality
								rdf:datatype="&amp;xsd;nonNegativeInteger">0</owl:maxQualifiedCardinality>
							<owl:onDataRange rdf:resource="&amp;xsd;anySimpleType" />
						</owl:Restriction>
					</owl:intersectionOf>
				</owl:Class>
			</rdfs:subClassOf>
		</owl:Class>

		<owl:Class rdf:about="{fcn:getRdfURI('EndlessList',namespace::*)}">
			<rdfs:subClassOf rdf:resource="#IfcList" />
			<rdfs:subClassOf>
				<owl:Class>
					<owl:intersectionOf rdf:parseType="Collection">
						<owl:Restriction>
							<owl:onProperty rdf:resource="#hasContent" />
							<owl:maxCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">0
							</owl:maxCardinality>
						</owl:Restriction>
						<owl:Restriction>
							<owl:onProperty rdf:resource="#hasValue" />
							<owl:maxQualifiedCardinality
								rdf:datatype="&amp;xsd;nonNegativeInteger">0</owl:maxQualifiedCardinality>
							<owl:onDataRange rdf:resource="&amp;xsd;anySimpleType" />
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

	<xsl:template name="IfcListItemTemplate">

		<xsl:param name="className" />
		<xsl:param name="nextClassName" />
		<xsl:param name="itemType" />
		<!-- 下一个元素是否必须 -->
		<xsl:param name="isNextItemFixed" select="true()" />

		<owl:Class rdf:about="#{$className}">
			<rdfs:subClassOf rdf:resource="#IfcList" />
			<rdfs:subClassOf>
				<owl:Restriction>
					<owl:onProperty rdf:resource="#hasValue" />
					<owl:qualifiedCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">1
					</owl:qualifiedCardinality>
					<owl:onDataRange rdf:resource="{$itemType}" />
				</owl:Restriction>
			</rdfs:subClassOf>
			<xsl:if test="$isNextItemFixed = true()">
				<rdfs:subClassOf>
					<owl:Restriction>
						<owl:onProperty rdf:resource="#hasNext" />
						<owl:onClass rdf:resource="#{$nextClassName}" />
						<owl:qualifiedCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">1
						</owl:qualifiedCardinality>
					</owl:Restriction>
				</rdfs:subClassOf>
			</xsl:if>
			<xsl:if test="$isNextItemFixed = false()">
				<rdfs:subClassOf>
					<owl:Restriction>
						<owl:onProperty rdf:resource="#hasNext" />
						<owl:onClass rdf:resource="#{$nextClassName}" />
						<owl:maxQualifiedCardinality
							rdf:datatype="&amp;xsd;nonNegativeInteger">1</owl:maxQualifiedCardinality>
					</owl:Restriction>
				</rdfs:subClassOf>
			</xsl:if>
		</owl:Class>
	</xsl:template>

</xsl:stylesheet>
