<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
	xmlns:fcn="http://www.liujinhang.cn/paper/ifc/xsd2owl-functions.xsl"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:xlink="http://www.w3.org/1999/xlink#" xmlns:owl="http://www.w3.org/2002/07/owl#">

	<!-- function文件引用 -->
	<xsl:import href="xsd2owl-functions.xsl" />

	<!-- 文档输出定义 -->
	<xsl:output media-type="text/xml" version="1.0" encoding="UTF-8"
		indent="yes" use-character-maps="owl" />
	<xsl:strip-space elements="*" />
	<xsl:character-map name="owl">
		<xsl:output-character character="&amp;" string="&amp;" />
	</xsl:character-map>

	<!-- 动词前缀 -->
	<xsl:variable name="predicatePrefix" select="'has'" />

	<!-- 目标命名空间 -->
	<xsl:variable name="targetNamespace">
		<xsl:value-of select="/xsd:schema/@targetNamespace" />
	</xsl:variable>

	<!-- 目标命名空间前缀 -->
	<xsl:variable name="targetNamespacePrefix">
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

	<!-- 本地定义的SimpleType -->
	<xsl:variable name="localSimpleTypes" select="/xsd:schema/xsd:simpleType" />

	<!-- 本地定义的ComplexType -->
	<xsl:variable name="localComplexTypes" select="/xsd:schema/xsd:complexType" />

	<!-- Xsd的本地前缀 -->
	<xsl:variable name="localXsdPrefix">
		<xsl:for-each select="/xsd:schema/namespace::*">
			<xsl:if test=". = 'http://www.w3.org/2001/XMLSchema'">
				<xsl:value-of select="name()" />
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>

	<!-- 命名空间 -->
	<xsl:variable name="namespaces" select="/xsd:schema/namespace::*" />

	<!-- 本地定义的命名空间 -->
	<xsl:variable name="localNamespaces"
		select="namespaces[
			not(name() = '' or 
				name() = 'xsd' or 
				name() = 'xml' or 
				name() = 'xlink' or
				name() = $localXsdPrefix)]" />

	<!-- name|type,node 图 -->
	<xsl:key name="propertyMap"
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
		use="concat(@name,'|',@type)" />

	<!-- schema的匹配模板 -->
	<xsl:template match="/xsd:schema">

		<!-- DTD START -->
		<!-- 输出 '<!DOCTYPE rdf:RDF [' -->
		<xsl:text disable-output-escaping="yes">&#10;&lt;!DOCTYPE rdf:RDF [&#10;</xsl:text>
		<!-- 输出常用的命名空间DTD -->
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xsd 'http://www.w3.org/2001/XMLSchema#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xml 'http://www.w3.org/XML/1998/namespace#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xlink 'http://www.w3.org/1999/xlink#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY owl 'http://www.w3.org/2002/07/owl#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY rdfs 'http://www.w3.org/2000/01/rdf-schema#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY rdf 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' &gt;&#10;</xsl:text>

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

		<rdf:RDF xml:base="{$targetNamespace}">

			<!-- 输出本地Namespace，命名空间暂时定义为'&name();' -->
			<xsl:variable name="localNamespacesTemp">
				<xsl:for-each select="$localNamespaces">
					<xsl:element name="{name()}:x" namespace="&#38;{name()};" />
				</xsl:for-each>
			</xsl:variable>
			<xsl:copy-of select="$localNamespacesTemp/*/namespace::*" />
			<xsl:variable name="baseNamespacesTemp">
				<xsl:element name="{'base'}:x" namespace="{$targetNamespace}" />
			</xsl:variable>
			<xsl:copy-of select="$baseNamespacesTemp/*/namespace::*" />

			<!-- 本体的顶级信息定义 -->
			<owl:Ontology rdf:about="{$targetNamespace}">
				<rdfs:comment>IFC</rdfs:comment>
			</owl:Ontology>

			<owl:ObjectProperty rdf:ID="any" />
			
			<!-- bug fix -->
			<owl:ObjectProperty rdf:about="{fcn:getFullName('hasWeightsData')}" />

			<!-- 自定义注解属性输出模板 -->
			<xsl:call-template name="annotationPropertyGenerateTemplate" />

			<!-- 列表基类输出模板 -->
			<xsl:call-template name="IfcListSuperClassGenerateTemplate" />

			<!-- datatype的转换模板 -->
			<xsl:call-template name="datatypeTranslationTemplate" />

			<!-- group(SELECT类型)转换模板 -->
			<xsl:call-template name="groupTranslationTemplate" />

			<!-- wrapper(包装)类转换模板 -->
			<xsl:call-template name="wrapperTranslationTemplate" />

			<!-- datatypeProperty与ObjectProperty的转换模板 -->
			<xsl:call-template
				name="datatypePropertyAndObjectPropertyTranslationTemplate" />

			<!-- 模板输出占位符 -->
			<xsl:apply-templates />

		</rdf:RDF>

	</xsl:template>

	<xsl:template name="annotationPropertyGenerateTemplate">

		<owl:AnnotationProperty rdf:about="{fcn:getFullName('definition')}">
			<rdfs:subPropertyOf rdf:resource="&amp;rdfs;comment" />
		</owl:AnnotationProperty>

		<owl:AnnotationProperty rdf:about="{fcn:getFullName('fullName')}">
			<rdfs:subPropertyOf rdf:resource="&amp;rdfs;label" />
		</owl:AnnotationProperty>

		<owl:AnnotationProperty rdf:about="{fcn:getFullName('guid')}">
			<rdfs:subPropertyOf rdf:resource="&amp;rdfs;label" />
		</owl:AnnotationProperty>

		<owl:AnnotationProperty rdf:about="{fcn:getFullName('shortName')}">
			<rdfs:subPropertyOf rdf:resource="&amp;rdfs;label" />
		</owl:AnnotationProperty>

		<owl:AnnotationProperty rdf:about="{fcn:getFullName('status')}">
			<rdfs:subPropertyOf rdf:resource="&amp;owl;versionInfo" />
		</owl:AnnotationProperty>

		<owl:AnnotationProperty rdf:about="{fcn:getFullName('versionDate')}">
			<rdfs:subPropertyOf rdf:resource="&amp;owl;versionInfo" />
		</owl:AnnotationProperty>

		<owl:AnnotationProperty rdf:about="{fcn:getFullName('versionId')}">
			<rdfs:subPropertyOf rdf:resource="&amp;owl;versionInfo" />
		</owl:AnnotationProperty>

		<owl:AnnotationProperty rdf:about="{fcn:getFullName('lexeme')}" />

		<owl:AnnotationProperty rdf:about="{fcn:getFullName('blobstoreKey')}" />

		<owl:AnnotationProperty rdf:about="{fcn:getFullName('illustrationUrl')}" />

	</xsl:template>

	<!-- Datatype的转换模板 -->
	<xsl:template name="datatypeTranslationTemplate">
		<xsl:for-each
			select="/xsd:schema/xsd:simpleType[@name and fcn:isNameIgnored(@name) = false()]">
			<xsl:choose>
				<xsl:when test="fcn:isDatatypeDefinition(./@name)">

					<rdfs:Datatype rdf:about="{fcn:getFullName(./@name)}">
						<owl:equivalentClass rdf:resource="{fcn:getFullName(./xsd:restriction/@base)}" />
					</rdfs:Datatype>

				</xsl:when>

				<xsl:otherwise>
					<!-- CHECK -->
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="datatypePropertyAndObjectPropertyTranslationTemplate">

		<xsl:for-each
			select=" 
				//xsd:element [ @name and (ancestor::xsd:complexType or ancestor::xsd:group) 
				and generate-id()=generate-id(key('propertyMap',concat(@name,'|',@type))[1])
				and fcn:isNameIgnored(@name) = false() ] |
				//xsd:attribute [ @name and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup)
				and generate-id()=generate-id(key('propertyMap',concat(@name,'|',@type))[1])
				and fcn:isNameIgnored(@name) = false() ] ">
			<xsl:variable name="currentName" select="./@name" />
			<xsl:variable name="currentType" select="./@type" />
			<xsl:choose>
				<!-- Datatype型simpleType -->
				<xsl:when
					test="$currentName and $currentType and fcn:isDatatypeDefinition($currentType)">

					<owl:DatatypeProperty rdf:about="{fcn:getFullName($currentName)}">
						<rdfs:range rdf:resource="{fcn:getFullName($currentType)}" />
					</owl:DatatypeProperty>

				</xsl:when>

				<!-- 枚举型simpleType -->
				<xsl:when
					test="$currentName and $currentType and fcn:isEnumClassDefinition($currentType)">

					<owl:ObjectProperty
						rdf:about="{fcn:getFullName(fcn:getPredicate($currentName))}">
						<rdfs:range rdf:resource="{fcn:getFullName($currentType)}" />
					</owl:ObjectProperty>

				</xsl:when>

				<!-- 显式complexType -->
				<xsl:when
					test="$currentName and $currentType and fcn:isClassDefinition($currentType) ">

					<owl:ObjectProperty rdf:about="{fcn:getFullName(concat('has',$currentName))}">
						<rdfs:range rdf:resource="{fcn:getFullName($currentType)}" />
					</owl:ObjectProperty>

				</xsl:when>

				<!-- 隐式complexType -->
				<xsl:when test="$currentName and ./xsd:complexType">
					<xsl:choose>
						<xsl:when test="./xsd:complexType/xsd:sequence/xsd:element/@ref">

							<owl:ObjectProperty
								rdf:about="{fcn:getFullName(concat('has',$currentName))}">
								<rdfs:range
									rdf:resource="{fcn:getFullName(./xsd:complexType/xsd:sequence/xsd:element/@ref)}" />
							</owl:ObjectProperty>

						</xsl:when>

						<xsl:when test="./xsd:complexType/xsd:group/@ref">

							<owl:ObjectProperty
								rdf:about="{fcn:getFullName(concat('has',$currentName))}">
								<rdfs:range
									rdf:resource="{fcn:getFullName(./xsd:complexType/xsd:group/@ref)}" />
							</owl:ObjectProperty>

						</xsl:when>

						<xsl:otherwise>
							<!-- CHECK -->
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>

				<!-- 隐式simpleType -->
				<xsl:when test="$currentName and ./xsd:simpleType">
					<xsl:variable name="currentItemType"
						select="./xsd:simpleType/xsd:restriction/xsd:simpleType/xsd:list/@itemType" />
					<xsl:choose>
						<xsl:when
							test="$currentItemType and fcn:isDatatypeDefinition($currentItemType)">

							<owl:DatatypeProperty rdf:about="{fcn:getFullName($currentName)}" />

						</xsl:when>
						<xsl:when
							test="
								$currentItemType and 
								(fcn:isEnumClassDefinition($currentItemType) or 
								fcn:isClassDefinition($currentItemType))">

							<owl:ObjectProperty
								rdf:about="{fcn:getFullName(fcn:getPredicate($currentName))}" />

						</xsl:when>
						<xsl:otherwise>
							<!-- CHECK -->
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>

				<xsl:otherwise>
					<!-- CHECK -->
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>


	<xsl:template match="//xsd:simpleType">

		<xsl:variable name="currentName" select="@name" />

		<xsl:choose>

			<!-- 转换枚举型simpleType，将simpleType本身转换为class，其枚举值转换为它的namedIndividual -->
			<xsl:when
				test="
					$currentName and 
					fcn:isNameIgnored(@name) = false() and
					fcn:isEnumClassDefinition($currentName)">

				<owl:Class rdf:about="{fcn:getFullName($currentName)}" />

				<xsl:for-each select="./xsd:restriction/child::*">

					<owl:NamedIndividual rdf:about="{fcn:getFullName(./@value)}">
						<rdf:type rdf:resource="{fcn:getFullName($currentName)}" />
					</owl:NamedIndividual>

				</xsl:for-each>
			</xsl:when>

			<!-- 转换显式定义的列表类simpleType -->
			<xsl:when
				test="$currentName and fcn:isNameIgnored(@name) = false() and
			 		 ./xsd:restriction/xsd:simpleType/xsd:list">

				<xsl:variable name="minLength"
					select="./xsd:restriction/xsd:minLength/@value" />
				<xsl:variable name="maxLength"
					select="./xsd:restriction/xsd:maxLength/@value" />
				<xsl:variable name="itemType"
					select="fcn:getFullName(./xsd:restriction/xsd:simpleType/xsd:list/@itemType)" />

				<xsl:call-template name="IfcListTemplate">
					<xsl:with-param name="classNamePrefix" select="$currentName" />
					<xsl:with-param name="minLength" select="$minLength" />
					<xsl:with-param name="maxLength" select="$maxLength" />
					<xsl:with-param name="itemType" select="$itemType" />
				</xsl:call-template>

			</xsl:when>

			<xsl:otherwise>
				<!-- CHECK -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- complexType匹配模板 -->
	<xsl:template match="//xsd:complexType">
		<xsl:choose>
			<!-- 匹配显式的complexType定义 -->
			<xsl:when
				test="
				@name and not(../@name) and 
				fcn:isNameIgnored(@name) = false()">
				<owl:Class rdf:about="{fcn:getFullName(@name)}">
					<xsl:call-template name="explicitComplexTypePropertyTranslationTemplate">
						<xsl:with-param name="complexType" select="." />
					</xsl:call-template>
				</owl:Class>
			</xsl:when>
			<!-- 匹配隐式的complexType定义，他们通常都被包围在一个element里面 -->
			<xsl:when
				test="
				not(@name) and ../@name and 
				fcn:isNameIgnored(../@name) = false()">
				<owl:Class rdf:about="{fcn:getFullName(../@name)}">
					<!-- TODO -->
				</owl:Class>
			</xsl:when>
			<xsl:otherwise>
				<!-- CHECK -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="explicitComplexTypePropertyTranslationTemplate">
		<xsl:param name="complexType" />
		<xsl:variable name="base"
			select="
				$complexType/xsd:complexContent/xsd:extension/@base |
				$complexType/xsd:complexContent/xsd:restriction/@base" />
		<xsl:if test="$base">
			<rdfs:subClassOf rdf:resource="{fcn:getFullName($base)}" />
			<xsl:call-template name="propertyTranslationTemplate">
				<xsl:with-param name="properties"
					select="
						$complexType/xsd:complexContent/xsd:extension/* |
						$complexType/xsd:complexContent/xsd:restriction/*" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<!-- 属性转换模板 -->
	<xsl:template name="propertyTranslationTemplate">
		<xsl:param name="properties" />
		<xsl:param name="isArrayMode" required="no" select="false()" />
		<xsl:choose>
			<xsl:when test="count($properties) > 0">
				<xsl:for-each select="$properties">

					<xsl:variable name="currentName">
						<xsl:value-of select="@name" />
					</xsl:variable>

					<xsl:variable name="currentType">
						<xsl:value-of select="@type" />
					</xsl:variable>

					<xsl:variable name="minOccurs">
						<xsl:value-of select="fcn:getMinOccurs(@minOccurs,@use,@nillable)" />
					</xsl:variable>

					<xsl:variable name="maxOccurs">
						<xsl:value-of select="fcn:getMaxOccurs(@maxOccurs)" />
					</xsl:variable>

					<xsl:choose>
						<!-- 解释element/attribute -->
						<xsl:when
							test="
								$currentName and
								(fcn:getQName(./name()) = 'xsd:element' or 
								fcn:getQName(./name()) = 'xsd:attribute')">
							<xsl:if test="$isArrayMode = false()">
								<xsl:choose>
									<!-- 指向xsd类型 -->
									<xsl:when test="$currentType and fcn:isXsdURI($currentType)">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty rdf:resource="{fcn:getFullName($currentName)}" />
												<xsl:call-template name="cardinalityTemplate">
													<xsl:with-param name="type" select="@type" />
													<xsl:with-param name="isDatatypeProperty"
														select="true()" />
													<xsl:with-param name="minOccurs" select="$minOccurs" />
													<xsl:with-param name="maxOccurs" select="$maxOccurs" />
												</xsl:call-template>
											</owl:Restriction>
										</rdfs:subClassOf>
									</xsl:when>

									<!-- 指向Datatype类型 -->
									<xsl:when
										test="$currentType and fcn:isDatatypeDefinition($currentType)">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty rdf:resource="{fcn:getFullName($currentName)}" />
												<xsl:call-template name="cardinalityTemplate">
													<xsl:with-param name="type" select="@type" />
													<xsl:with-param name="isDatatypeProperty"
														select="true()" />
													<xsl:with-param name="minOccurs" select="$minOccurs" />
													<xsl:with-param name="maxOccurs" select="$maxOccurs" />
												</xsl:call-template>
											</owl:Restriction>
										</rdfs:subClassOf>
									</xsl:when>

									<!-- 指向简单类型(枚举类型) -->
									<xsl:when
										test="$currentType and fcn:isEnumClassDefinition($currentType)">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty
													rdf:resource="{fcn:getFullName(fcn:getPredicate($currentName))}" />
												<xsl:call-template name="cardinalityTemplate">
													<xsl:with-param name="type" select="@type" />
													<xsl:with-param name="isDatatypeProperty"
														select="false()" />
													<xsl:with-param name="minOccurs" select="$minOccurs" />
													<xsl:with-param name="maxOccurs" select="$maxOccurs" />
												</xsl:call-template>
											</owl:Restriction>
										</rdfs:subClassOf>
									</xsl:when>

									<!-- 指向复杂类型 -->
									<xsl:when test="fcn:isClassDefinition($currentType)">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty
													rdf:resource="{fcn:getFullName(fcn:getPredicate($currentName))}" />
												<xsl:call-template name="cardinalityTemplate">
													<xsl:with-param name="type" select="@type" />
													<xsl:with-param name="isDatatypeProperty"
														select="false()" />
													<xsl:with-param name="minOccurs" select="$minOccurs" />
													<xsl:with-param name="maxOccurs" select="$maxOccurs" />
												</xsl:call-template>
											</owl:Restriction>
										</rdfs:subClassOf>
									</xsl:when>

									<!-- 匿名ComplexType -->
									<xsl:when
										test="
											./xsd:complexType and 
											./xsd:complexType/xsd:group/@ref">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty
													rdf:resource="{fcn:getFullName(fcn:getPredicate($currentName))}" />
												<xsl:call-template name="cardinalityTemplate">
													<xsl:with-param name="type"
														select="./xsd:complexType/xsd:group/@ref" />
													<xsl:with-param name="isDatatypeProperty"
														select="false()" />
													<xsl:with-param name="minOccurs" select="$minOccurs" />
													<xsl:with-param name="maxOccurs" select="$maxOccurs" />
												</xsl:call-template>
											</owl:Restriction>
										</rdfs:subClassOf>
									</xsl:when>

									<!-- 匿名SimpleType，类型为list -->
									<xsl:when
										test="
											./xsd:simpleType and 
											./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType and
											fcn:isDatatypeDefinition(./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType)">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty rdf:resource="{fcn:getFullName($currentName)}" />
												<xsl:call-template name="cardinalityTemplate">
													<xsl:with-param name="type"
														select="./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType" />
													<xsl:with-param name="isDatatypeProperty"
														select="true()" />
													<xsl:with-param name="minOccurs" select="$minOccurs" />
													<xsl:with-param name="maxOccurs" select="$maxOccurs" />
												</xsl:call-template>
											</owl:Restriction>
										</rdfs:subClassOf>
									</xsl:when>

									<xsl:when
										test="
											./xsd:simpleType and 
											./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType and
											(fcn:isEnumClassDefinition(./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType) or
											fcn:isClassDefinition(./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType))">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty
													rdf:resource="{fcn:getFullName(fcn:getPredicate($currentName))}" />
												<xsl:call-template name="cardinalityTemplate">
													<xsl:with-param name="type"
														select="./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType" />
													<xsl:with-param name="isDatatypeProperty"
														select="false()" />
													<xsl:with-param name="minOccurs" select="$minOccurs" />
													<xsl:with-param name="maxOccurs" select="$maxOccurs" />
												</xsl:call-template>
											</owl:Restriction>
										</rdfs:subClassOf>
									</xsl:when>

									<!-- complexType，类型为sequence -->
									<xsl:when
										test="
										$currentName and ./xsd:complexType and 
										./xsd:complexType/xsd:sequence/xsd:element/@ref">

										<!-- NEED TO FIX : property generation -->

										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty
													rdf:resource="{fcn:getFullName(fcn:getPredicate($currentName))}" />
												<xsl:call-template name="cardinalityTemplate">
													<xsl:with-param name="type"
														select="./xsd:complexType/xsd:sequence/xsd:element/@ref" />
													<xsl:with-param name="isDatatypeProperty"
														select="false()" />
													<xsl:with-param name="minOccurs"
														select="fcn:getMinOccurs(./xsd:complexType/xsd:sequence/xsd:element/@minOccurs,@use,@nillable)" />
													<xsl:with-param name="maxOccurs"
														select="fcn:getMaxOccurs(./xsd:complexType/xsd:sequence/xsd:element/@maxOccurs)" />
												</xsl:call-template>
											</owl:Restriction>
										</rdfs:subClassOf>
									</xsl:when>

									<xsl:otherwise>
										<!-- CHECK -->
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>

							<xsl:if test="$isArrayMode = true()">
								<xsl:choose>
									<!-- 指向xsd类型 -->
									<xsl:when test="$currentType and fcn:isXsdURI($currentType)">
										<owl:Restriction>
											<owl:onProperty rdf:resource="{fcn:getFullName($currentName)}" />
											<xsl:call-template name="cardinalityTemplate">
												<xsl:with-param name="type" select="@type" />
												<xsl:with-param name="isDatatypeProperty"
													select="true()" />
												<xsl:with-param name="minOccurs" select="$minOccurs" />
												<xsl:with-param name="maxOccurs" select="$maxOccurs" />
											</xsl:call-template>
										</owl:Restriction>
									</xsl:when>

									<!-- 指向Datatype类型 -->
									<xsl:when
										test="$currentType and fcn:isDatatypeDefinition($currentType)">
										<owl:Restriction>
											<owl:onProperty rdf:resource="{fcn:getFullName($currentName)}" />
											<xsl:call-template name="cardinalityTemplate">
												<xsl:with-param name="type" select="@type" />
												<xsl:with-param name="isDatatypeProperty"
													select="true()" />
												<xsl:with-param name="minOccurs" select="$minOccurs" />
												<xsl:with-param name="maxOccurs" select="$maxOccurs" />
											</xsl:call-template>
										</owl:Restriction>
									</xsl:when>

									<!-- 指向简单类型(枚举类型) -->
									<xsl:when
										test="$currentType and fcn:isEnumClassDefinition($currentType)">
										<owl:Restriction>
											<owl:onProperty
												rdf:resource="{fcn:getFullName(fcn:getPredicate($currentName))}" />
											<xsl:call-template name="cardinalityTemplate">
												<xsl:with-param name="type" select="@type" />
												<xsl:with-param name="isDatatypeProperty"
													select="false()" />
												<xsl:with-param name="minOccurs" select="$minOccurs" />
												<xsl:with-param name="maxOccurs" select="$maxOccurs" />
											</xsl:call-template>
										</owl:Restriction>
									</xsl:when>

									<!-- 指向复杂类型 -->
									<xsl:when test="fcn:isClassDefinition($currentType)">
										<owl:Restriction>
											<owl:onProperty
												rdf:resource="{fcn:getFullName(fcn:getPredicate($currentName))}" />
											<xsl:call-template name="cardinalityTemplate">
												<xsl:with-param name="type" select="@type" />
												<xsl:with-param name="isDatatypeProperty"
													select="false()" />
												<xsl:with-param name="minOccurs" select="$minOccurs" />
												<xsl:with-param name="maxOccurs" select="$maxOccurs" />
											</xsl:call-template>
										</owl:Restriction>
									</xsl:when>

									<!-- 匿名ComplexType -->
									<xsl:when
										test="
											./xsd:complexType and 
											./xsd:complexType/xsd:group/@ref">
										<owl:Restriction>
											<!-- TODO -->
											<owl:onProperty
												rdf:resource="{fcn:getFullName(fcn:getPredicate($currentName))}" />
											<xsl:call-template name="cardinalityTemplate">
												<xsl:with-param name="type"
													select="./xsd:complexType/xsd:group/@ref" />
												<xsl:with-param name="isDatatypeProperty"
													select="false()" />
												<xsl:with-param name="minOccurs" select="$minOccurs" />
												<xsl:with-param name="maxOccurs" select="$maxOccurs" />
											</xsl:call-template>
										</owl:Restriction>
									</xsl:when>

									<!-- 匿名SimpleType，类型为list -->
									<xsl:when
										test="
											./xsd:simpleType and 
											./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType and
											fcn:isDatatypeDefinition(./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType)">
										<owl:Restriction>
											<owl:onProperty rdf:resource="{fcn:getFullName($currentName)}" />
											<xsl:call-template name="cardinalityTemplate">
												<xsl:with-param name="type"
													select="./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType" />
												<xsl:with-param name="isDatatypeProperty"
													select="true()" />
												<xsl:with-param name="minOccurs" select="$minOccurs" />
												<xsl:with-param name="maxOccurs" select="$maxOccurs" />
											</xsl:call-template>
										</owl:Restriction>
									</xsl:when>

									<xsl:when
										test="
											./xsd:simpleType and 
											./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType and
											(fcn:isEnumClassDefinition(./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType) or
											fcn:isClassDefinition(./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType))">
										<owl:Restriction>
											<owl:onProperty
												rdf:resource="{fcn:getFullName(fcn:getPredicate($currentName))}" />
											<xsl:call-template name="cardinalityTemplate">
												<xsl:with-param name="type"
													select="./descendant::*[fcn:getQName(name()) = 'xsd:list']/@itemType" />
												<xsl:with-param name="isDatatypeProperty"
													select="false()" />
												<xsl:with-param name="minOccurs" select="$minOccurs" />
												<xsl:with-param name="maxOccurs" select="$maxOccurs" />
											</xsl:call-template>
										</owl:Restriction>
									</xsl:when>

									<!-- complexType，类型为sequence -->
									<xsl:when
										test="
										$currentName and ./xsd:complexType and 
										./xsd:complexType/xsd:sequence/xsd:element/@ref">

										<!-- NEED TO FIX : property generation -->

										<owl:Restriction>
											<owl:onProperty
												rdf:resource="{fcn:getFullName(fcn:getPredicate($currentName))}" />
											<xsl:call-template name="cardinalityTemplate">
												<xsl:with-param name="type"
													select="./xsd:complexType/xsd:sequence/xsd:element/@ref" />
												<xsl:with-param name="isDatatypeProperty"
													select="false()" />
												<xsl:with-param name="minOccurs"
													select="fcn:getMinOccurs(./xsd:complexType/xsd:sequence/xsd:element/@minOccurs,@use,@nillable)" />
												<xsl:with-param name="maxOccurs"
													select="fcn:getMaxOccurs(./xsd:complexType/xsd:sequence/xsd:element/@maxOccurs)" />
											</xsl:call-template>
										</owl:Restriction>
									</xsl:when>

									<xsl:otherwise>
										<!-- CHECK -->
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>

						</xsl:when>

						<!-- 解释sequence -->
						<xsl:when test="fcn:getQName(./name()) = 'xsd:sequence'">
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
						<xsl:when test="fcn:getQName(./name()) = 'xsd:choice'">
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
									<!-- CHECK -->
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<!-- CHECK -->
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<!-- CHECK -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="cardinalityTemplate">
		<xsl:param name="type" />
		<xsl:param name="isDatatypeProperty" />
		<xsl:param name="minOccurs" />
		<xsl:param name="maxOccurs" />
		<xsl:choose>
			<xsl:when test="$minOccurs = 0 and $maxOccurs = 'unbounded'">
				<owl:allValuesFrom rdf:resource="{fcn:getFullName($type)}" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="$isDatatypeProperty = true()">
					<owl:onDataRange rdf:resource="{fcn:getFullName($type)}" />
				</xsl:if>
				<xsl:if test="$isDatatypeProperty = false()">
					<owl:onClass rdf:resource="{fcn:getFullName($type)}" />
				</xsl:if>
				<xsl:if test="not($minOccurs = 0)">
					<owl:minQualifiedCardinality
						rdf:datatype="&amp;xsd;nonNegativeInteger">
						<xsl:value-of select="$minOccurs" />
					</owl:minQualifiedCardinality>
				</xsl:if>
				<xsl:if test="not($maxOccurs = 'unbounded')">
					<owl:maxQualifiedCardinality
						rdf:datatype="&amp;xsd;nonNegativeInteger">
						<xsl:value-of select="$maxOccurs" />
					</owl:maxQualifiedCardinality>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="wrapperTranslationTemplate">
		<xsl:for-each select="//xsd:element[contains(@name,'-wrapper')]">
			<xsl:variable name="base"
				select="descendant::*[fcn:getQName(name())='xsd:extension']/@base" />
			<xsl:choose>

				<xsl:when test="fcn:isDatatypeDefinition($base)">
					<owl:DatatypeProperty rdf:about="{fcn:getFullName(fcn:getPredicate($base))}" />
				</xsl:when>
				<xsl:when
					test="fcn:isEnumClassDefinition($base) or fcn:isClassDefinition($base)">
					<owl:ObjectProperty rdf:about="{fcn:getFullName(fcn:getPredicate($base))}" />
				</xsl:when>
				<xsl:otherwise>
					<!-- CHECK -->
				</xsl:otherwise>
			</xsl:choose>

			<owl:Class rdf:about="{fcn:getFullName(@name)}">
				<rdfs:subClassOf>
					<owl:Restriction>
						<owl:onProperty rdf:resource="{fcn:getFullName(fcn:getPredicate($base))}" />
						<owl:allValuesFrom rdf:resource="{fcn:getFullName($base)}" />
					</owl:Restriction>
				</rdfs:subClassOf>
			</owl:Class>

		</xsl:for-each>
	</xsl:template>

	<xsl:template name="groupTranslationTemplate">
		<xsl:for-each select="./xsd:group">
			<xsl:if test="./xsd:choice and count(./xsd:choice/child::*) > 0">

				<owl:Class rdf:about="{fcn:getFullName(@name)}">
					<rdfs:subClassOf>
						<owl:Class>
							<owl:unionOf rdf:parseType="Collection">
								<xsl:for-each select="./xsd:choice/child::*">
									<rdf:Description rdf:about="{fcn:getFullName(@ref)}" />
								</xsl:for-each>
							</owl:unionOf>
						</owl:Class>
					</rdfs:subClassOf>
				</owl:Class>

			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<!-- 集合的一种折衷方案，可以让区间确定的集合具备一定的推理能力 -->
	<xsl:template name="IfcListTemplate">
		<xsl:param name="classNamePrefix" />
		<xsl:param name="minLength" />
		<xsl:param name="maxLength" />
		<xsl:param name="itemType" />

		<xsl:choose>
			<!-- minLength与maxLength相等的时候 -->
			<xsl:when test="$minLength = $maxLength">

				<!-- 一个包装类，为了不改变名称 -->
				<owl:Class rdf:about="{fcn:getFullName($classNamePrefix)}">
					<owl:equivalentClass
						rdf:resource="{fcn:getFullName(concat($classNamePrefix,'1'))}" />
				</owl:Class>

				<xsl:for-each select="1 to $minLength">
					<xsl:choose>
						<!-- 列表尾部元素处理，hasNext为EmptyList -->
						<xsl:when test=". = $minLength">

							<xsl:call-template name="IfcListItemGenerateTemplate">
								<xsl:with-param name="className" select="concat($classNamePrefix,.)" />
								<xsl:with-param name="nextClassName" select="'EmptyList'" />
								<xsl:with-param name="itemType" select="$itemType" />
								<xsl:with-param name="isNextItemFixed" select="true()" />
							</xsl:call-template>

						</xsl:when>

						<xsl:otherwise>

							<!-- 列表对象处理 -->
							<xsl:call-template name="IfcListItemGenerateTemplate">
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

				<!-- 包装列表的首个元素 -->
				<owl:Class rdf:about="{fcn:getFullName($classNamePrefix)}">
					<owl:equivalentClass
						rdf:resource="{fcn:getFullName(concat($classNamePrefix,'1'))}" />
				</owl:Class>

				<!-- 区间：1 <= i <= minLength -->
				<xsl:for-each select="1 to $minLength">
					<xsl:choose>
						<!-- 区间尾部元素，hasNext为非必须项 -->
						<xsl:when test=". = $minLength">
							<xsl:call-template name="IfcListItemGenerateTemplate">
								<xsl:with-param name="className" select="concat($classNamePrefix,.)" />
								<xsl:with-param name="nextClassName"
									select="concat($classNamePrefix,(. + 1))" />
								<xsl:with-param name="itemType" select="$itemType" />
								<xsl:with-param name="isNextItemFixed" select="false()" />
							</xsl:call-template>
						</xsl:when>
						<!-- 区间元素，hasNext为必须项 -->
						<xsl:otherwise>
							<xsl:call-template name="IfcListItemGenerateTemplate">
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
								<xsl:call-template name="IfcListItemGenerateTemplate">
									<xsl:with-param name="className"
										select="concat($classNamePrefix,.)" />
									<xsl:with-param name="nextClassName" select="'EmptyList'" />
									<xsl:with-param name="itemType" select="$itemType" />
									<xsl:with-param name="isNextItemFixed" select="true()" />
								</xsl:call-template>
							</xsl:when>
							<!-- 区间元素 hasNext为非必须项 -->
							<xsl:otherwise>
								<xsl:call-template name="IfcListItemGenerateTemplate">
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
	<xsl:template name="IfcListSuperClassGenerateTemplate">

		<owl:ObjectProperty rdf:about="{fcn:getFullName('hasNext')}">
			<rdfs:subPropertyOf rdf:resource="{fcn:getFullName('isFollowedBy')}" />
		</owl:ObjectProperty>

		<owl:ObjectProperty rdf:about="{fcn:getFullName('isFollowedBy')}">
			<!-- <rdf:type rdf:resource="&amp;owl;TransitiveProperty" /> -->
			<rdfs:range rdf:resource="{fcn:getFullName('IfcList')}" />
			<rdfs:domain rdf:resource="{fcn:getFullName('IfcList')}" />
		</owl:ObjectProperty>

		<owl:ObjectProperty rdf:about="{fcn:getFullName('hasContent')}" />
		<owl:DatatypeProperty rdf:about="{fcn:getFullName('hasValue')}" />

		<owl:Class rdf:about="{fcn:getFullName('EmptyList')}">
			<rdfs:subClassOf rdf:resource="{fcn:getFullName('IfcList')}" />
			<rdfs:subClassOf>
				<owl:Class>
					<owl:intersectionOf rdf:parseType="Collection">
						<owl:Restriction>
							<owl:onProperty rdf:resource="{fcn:getFullName('hasContent')}" />
							<owl:maxCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">0
							</owl:maxCardinality>
						</owl:Restriction>
						<owl:Restriction>
							<owl:onProperty rdf:resource="{fcn:getFullName('hasValue')}" />
							<owl:maxQualifiedCardinality
								rdf:datatype="&amp;xsd;nonNegativeInteger">0</owl:maxQualifiedCardinality>
							<owl:onDataRange rdf:resource="&amp;xsd;anySimpleType" />
						</owl:Restriction>
					</owl:intersectionOf>
				</owl:Class>
			</rdfs:subClassOf>
		</owl:Class>

		<owl:Class rdf:about="{fcn:getFullName('LoopList')}">
			<rdfs:subClassOf rdf:resource="{fcn:getFullName('IfcList')}" />
			<rdfs:subClassOf>
				<owl:Class>
					<owl:intersectionOf rdf:parseType="Collection">
						<owl:Restriction>
							<owl:onProperty rdf:resource="{fcn:getFullName('hasContent')}" />
							<owl:allValuesFrom rdf:resource="&amp;owl;Thing" />
						</owl:Restriction>
						<owl:Restriction>
							<owl:onProperty rdf:resource="{fcn:getFullName('hasValue')}" />
							<owl:allValuesFrom rdf:resource="&amp;xsd;anySimpleType" />
						</owl:Restriction>
					</owl:intersectionOf>
				</owl:Class>
			</rdfs:subClassOf>
		</owl:Class>

		<owl:Class rdf:about="{fcn:getFullName('IfcList')}">
			<rdfs:subClassOf>
				<owl:Restriction>
					<owl:onProperty rdf:resource="{fcn:getFullName('isFollowedBy')}" />
					<owl:onClass rdf:resource="{fcn:getFullName('IfcList')}" />
					<owl:qualifiedCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">1
					</owl:qualifiedCardinality>
				</owl:Restriction>
			</rdfs:subClassOf>
		</owl:Class>

	</xsl:template>

	<xsl:template name="IfcListItemGenerateTemplate">

		<xsl:param name="className" />
		<xsl:param name="nextClassName" />
		<xsl:param name="itemType" />
		<xsl:param name="isNextItemFixed" select="true()" />

		<owl:Class rdf:about="{fcn:getFullName($className)}">
			<rdfs:subClassOf rdf:resource="{fcn:getFullName('IfcList')}" />
			<rdfs:subClassOf>
				<owl:Restriction>
					<owl:onProperty rdf:resource="{fcn:getFullName('hasValue')}" />
					<owl:qualifiedCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">1
					</owl:qualifiedCardinality>
					<owl:onDataRange rdf:resource="{fcn:getFullName($itemType)}" />
				</owl:Restriction>
			</rdfs:subClassOf>
			<xsl:if test="$isNextItemFixed = true()">
				<rdfs:subClassOf>
					<owl:Restriction>
						<owl:onProperty rdf:resource="{fcn:getFullName('hasNext')}" />
						<owl:onClass rdf:resource="{fcn:getFullName($nextClassName)}" />
						<owl:qualifiedCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">1
						</owl:qualifiedCardinality>
					</owl:Restriction>
				</rdfs:subClassOf>
			</xsl:if>
			<xsl:if test="$isNextItemFixed = false()">
				<rdfs:subClassOf>
					<owl:Restriction>
						<owl:onProperty rdf:resource="{fcn:getFullName('hasNext')}" />
						<owl:onClass rdf:resource="{fcn:getFullName($nextClassName)}" />
						<owl:maxQualifiedCardinality
							rdf:datatype="&amp;xsd;nonNegativeInteger">1</owl:maxQualifiedCardinality>
					</owl:Restriction>
				</rdfs:subClassOf>
			</xsl:if>
		</owl:Class>
	</xsl:template>

</xsl:stylesheet>
