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
	<xsl:variable name="ontologyBase">
		<xsl:value-of select="'http://liujinhang.cn/paper/ifc/ifcOWL.owl'" />
	</xsl:variable>

	<xsl:variable name="targetNamespace">
		<xsl:value-of select="/xsd:schema/@targetNamespace" />
	</xsl:variable>

	<xsl:variable name="targetNamespacePrefix">
		<xsl:for-each select="/xsd:schema/namespace::*">
			<xsl:if test=". = $targetNamespace">
				<xsl:value-of select="name()" />
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>

	<xsl:variable name="targetDTDEntity">
		<!-- 输出 '&' -->
		<xsl:text disable-output-escaping="yes">&amp;</xsl:text>
		<!-- 输出 targetPrefix -->
		<xsl:value-of select="$targetNamespacePrefix" />
		<!-- 输出 ';' -->
		<xsl:text disable-output-escaping="yes">;</xsl:text>
	</xsl:variable>

	<!-- 忽略列表 -->
	<xsl:variable name="ignoreNameList"
		select="'ifcXML','uos','Seq-anyURI','instanceAttributes','pos','arraySize','itemType','cType',nil" />

	<!-- 忽略模式列表 -->
	<xsl:variable name="ignoreNamePatternList" select="'-wrapper',nil" />

	<xsl:variable name="localSimpleTypes" select="/xsd:schema/xsd:simpleType" />

	<xsl:variable name="localComplexTypes" select="/xsd:schema/xsd:complexType" />

	<xsl:variable name="localXsdPrefix">
		<xsl:for-each select="/xsd:schema/namespace::*">
			<xsl:if test=". = 'http://www.w3.org/2001/XMLSchema'">
				<xsl:value-of select="name()" />
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>

	<xsl:variable name="namespaces" select="/xsd:schema/namespace::*" />

	<xsl:variable name="localNamespaces"
		select="namespaces[
			not(name() = '' or 
				name() = 'xsd' or 
				name() = 'xml' or 
				name() = 'xlink' or
				name() = $localXsdPrefix)]" />

	<!-- 属性 -->
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

	<xsl:template match="/xsd:schema">

		<!-- DTD START -->
		<!-- 输出 '<!DOCTYPE rdf:RDF [' -->
		<xsl:text disable-output-escaping="yes">&#10;&lt;!DOCTYPE rdf:RDF [&#10;</xsl:text>
		<!-- 输出常用的命名空间DTD -->
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xsd 'http://www.w3.org/2001/XMLSchema#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xml 'http://www.w3.org/XML/1998/namespace#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xlink 'http://www.w3.org/1999/xlink#' &gt;&#10;</xsl:text>
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY owl 'http://www.w3.org/2002/07/owl#' &gt;&#10;</xsl:text>

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

			<!-- 本体的顶级信息定义 -->
			<owl:Ontology rdf:about="{$ontologyBase}">
				<rdfs:comment>IFC</rdfs:comment>
			</owl:Ontology>

			<owl:ObjectProperty rdf:ID="any" />

			<!-- 列表基类生成模板 -->
			<xsl:call-template name="IfcListSuperClassTemplate" />

			<!-- 组生成模板(SELECT类型) -->
			<xsl:call-template name="groupTranslationTemplate" />

			<!-- 包装类生成模板 -->
			<xsl:call-template name="wrapperTranslationTemplate" />

			<!-- Datatype转换模板 -->
			<xsl:call-template name="simpleTypeToDatatypeTranslationTemplate" />

			<!-- datatypeProperty与ObjectProperty的转换模板 -->
			<xsl:call-template
				name="datatypePropertyAndObjectPropertyTranslationTemplate" />

			<!-- 模板输出占位符 -->
			<xsl:apply-templates />

		</rdf:RDF>

	</xsl:template>

	<!-- Datatype的转换模板 -->
	<xsl:template name="simpleTypeToDatatypeTranslationTemplate">
		<xsl:for-each
			select="
				/xsd:schema/xsd:simpleType/@name and 
				/xsd:schema/xsd:simpleType[fcn:isNameIgnored(@name) = false()]">
			<xsl:choose>
				<xsl:when test="fcn:isDatatypeDefinition(./@name)">

					<rdfs:Datatype rdf:about="{fcn:getFullName(./@name)}">
						<owl:equivalentClass rdf:resource="{fcn:getFullName(./xsd:restriction/@base)}" />
					</rdfs:Datatype>

				</xsl:when>
				<xsl:otherwise>
					<!-- KEEP it -->
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

				<!-- simpleType(非枚举型) -->
				<xsl:when test="$currentName and $currentType and fcn:isDatatypeDefinition($currentType)">

					<owl:DatatypeProperty rdf:about="{fcn:getFullName($currentName)}">
						<rdfs:range rdf:resource="{fcn:getFullName($currentType)}" />
					</owl:DatatypeProperty>

				</xsl:when>

				<!-- simpleType(枚举型) -->
				<xsl:when
					test="$currentType and and fcn:isEnumClassDefinition($currentType)">

					<owl:ObjectProperty rdf:about="{fcn:getFullName(concat('has',@name))}">
						<rdfs:range rdf:resource="{fcn:getFullName(@type)}" />
					</owl:ObjectProperty>

				</xsl:when>

				<!-- 显式complexType -->
				<xsl:when test="$currentType and fcn:isClassDefinition($currentType) ">
				
					<owl:ObjectProperty rdf:about="{fcn:getFullName(concat('has',@name))}">
						<rdfs:range rdf:resource="{fcn:getFullName(@type)}" />
					</owl:ObjectProperty>
					
				</xsl:when>

				<!-- 匿名complexType -->
				<xsl:when test="fcn:isComplexType(./*)">

					<xsl:choose>

						<!-- sequence -->
						<xsl:when test="./xsd:complexType/xsd:sequence/xsd:element/@ref">
							<owl:ObjectProperty
								rdf:about="{fcn:getAbsoluteURIRef(concat('has',@name))}">
								<rdfs:range
									rdf:resource="{fcn:getAbsoluteURIRef(./xsd:complexType/xsd:sequence/xsd:element/@ref)}" />
							</owl:ObjectProperty>
						</xsl:when>

						<!-- group -->
						<xsl:when test="./xsd:complexType/xsd:group/@ref">
							<owl:ObjectProperty
								rdf:about="{fcn:getAbsoluteURIRef(concat('has',@name))}">
								<rdfs:range
									rdf:resource="{fcn:getAbsoluteURIRef(./xsd:complexType/xsd:group/@ref)}" />
							</owl:ObjectProperty>
						</xsl:when>

						<xsl:otherwise>
							<!-- nothing but ignored things -->
						</xsl:otherwise>

					</xsl:choose>

				</xsl:when>

				<!-- 匿名simpleType -->
				<xsl:when test="fcn:isSimpleType(./*)">
					<xsl:choose>

						<xsl:when
							test="./xsd:simpleType/xsd:restriction/xsd:simpleType/xsd:list/@itemType and 
								fcn:isDatatypeDefinition(./xsd:simpleType/xsd:restriction/xsd:simpleType/xsd:list/@itemType,//xsd:simpleType,namespace::*)">
							<owl:DatatypeProperty rdf:about="{fcn:getAbsoluteURIRef(@name)}" />
						</xsl:when>

						<xsl:when
							test="./xsd:simpleType/xsd:restriction/xsd:simpleType/xsd:list/@itemType and 
								not(fcn:isDatatypeDefinition(./xsd:simpleType/xsd:restriction/xsd:simpleType/xsd:list/@itemType,//xsd:simpleType,namespace::*))">
							<owl:ObjectProperty
								rdf:about="{fcn:getAbsoluteURIRef(concat('has',@name))}" />
						</xsl:when>

						<xsl:otherwise>
							<!-- nothing -->
						</xsl:otherwise>

					</xsl:choose>

				</xsl:when>

				<xsl:otherwise>
					<!-- nothing -->
				</xsl:otherwise>

			</xsl:choose>

		</xsl:for-each>

	</xsl:template>

	<!-- 转换simpleType -->
	<xsl:template match="xsd:simpleType">

		<xsl:choose>
			<!-- 转换显式定义的语法糖级simpleType为datatype -->
			<!-- 为了调整输出顺序，将datatype的定义提到文档输出的头部 -->
			<!-- <xsl:when test=" @name and fcn:isNameIgnored(@name) = false() and 
				./xsd:restriction/@base and count(./xsd:restriction/xsd:enumeration) = 0 
				"> <rdfs:Datatype rdf:about="{fcn:getAbsoluteURIRef(@name)}"> <owl:equivalentClass 
				rdf:resource="{fcn:getAbsoluteURIRef(./xsd:restriction/@base)}" /> </rdfs:Datatype> 
				</xsl:when> -->

			<!-- 转换显式定义的枚举型simpleType，将simpleType本身转换为class，其枚举值转换为它的个体 -->
			<xsl:when
				test="
					@name and fcn:isNameIgnored(@name) = false() and
					./xsd:restriction/@base and
					count(./xsd:restriction/xsd:enumeration) > 0 ">
				<xsl:variable name="className" select="@name" />
				<owl:Class rdf:about="{fcn:getAbsoluteURIRef($className)}" />
				<xsl:for-each select="./xsd:restriction/child::*">
					<owl:NamedIndividual rdf:about="{fcn:getAbsoluteURIRef(./@value)}">
						<rdf:type rdf:resource="{fcn:getAbsoluteURIRef($className)}" />
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
				<!-- noting but ignored things -->
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- complexType匹配模板 -->
	<xsl:template match="xsd:complexType">

		<xsl:choose>

			<!-- 匹配显式的complexType定义 -->
			<xsl:when test="@name and fcn:isNameIgnored(@name) = false()">
				<owl:Class rdf:about="{fcn:getAbsoluteURIRef(@name)}">
					<xsl:call-template name="explicitComplexTypePropertyTranslationTemplate">
						<xsl:with-param name="complexType" select="." />
					</xsl:call-template>
				</owl:Class>
			</xsl:when>

			<!-- 匹配隐式的complexType定义，他们通常都被包围在一个element里面 -->
			<xsl:when test="not(@name)">
				<!-- TODO CHECK -->
				<xsl:choose>
					<xsl:when test="../@name and fcn:isNameIgnored(../@name) = false()">
						<owl:Class rdf:about="{fcn:getAbsoluteURIRef(../@name)}">
						</owl:Class>
					</xsl:when>

					<xsl:otherwise>
						<!-- nothing but ignored things -->
					</xsl:otherwise>

				</xsl:choose>

			</xsl:when>

			<xsl:otherwise>
				<!-- nothing but ignored things -->
			</xsl:otherwise>

		</xsl:choose>

	</xsl:template>

	<!-- 属性组匹配模板 -->
	<xsl:template
		match="xsd:attributeGroup[@name and fcn:isNameIgnored(@name) = false()]">
		<!-- nothing but ignored things -->
		<owl:Class rdf:about="{fcn:getAbsoluteURIRef(@name)}">
		</owl:Class>
	</xsl:template>

	<!-- 显式定义的complexType的property转换模板 -->
	<xsl:template name="explicitComplexTypePropertyTranslationTemplate">
		<xsl:param name="complexType" />
		<xsl:variable name="base"
			select="
				$complexType/xsd:complexContent/xsd:extension/@base |
				$complexType/xsd:complexContent/xsd:restriction/@base" />
		<xsl:if test="$base">
			<rdfs:subClassOf rdf:resource="{fcn:getAbsoluteURIRef($base)}" />
			<xsl:call-template name="propertyTranslationTemplate">
				<xsl:with-param name="properties"
					select="
						$complexType/xsd:complexContent/xsd:extension/* |
						$complexType/xsd:complexContent/xsd:restriction/*" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="cardinalityTemplate">
		<xsl:param name="type" />
		<xsl:param name="isDatatypeProperty" />
		<xsl:param name="minOccurs" />
		<xsl:param name="maxOccurs" />

		<xsl:choose>
			<xsl:when test="$minOccurs = 0 and $maxOccurs = 'unbounded'">
				<owl:allValuesFrom rdf:resource="{fcn:getAbsoluteURIRef($type)}" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="$isDatatypeProperty = true()">
					<owl:onDataRange rdf:resource="{fcn:getAbsoluteURIRef($type)}" />
				</xsl:if>
				<xsl:if test="$isDatatypeProperty = false()">
					<owl:onClass rdf:resource="{fcn:getAbsoluteURIRef($type)}" />
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
						<xsl:choose>
							<xsl:when test="@minOccurs">
								<xsl:value-of select="@minOccurs" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="@use='required'">
										<xsl:value-of select="1" />
									</xsl:when>
									<xsl:when test="@use='optional' or nillable='true'">
										<xsl:value-of select="0" />
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="0" />
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>

					<xsl:variable name="maxOccurs">
						<xsl:choose>
							<xsl:when test="@maxOccurs">
								<xsl:value-of select="@maxOccurs" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'unbounded'" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>

					<xsl:choose>
						<!-- 解释element/attribute -->
						<xsl:when
							test="
								$currentName and $currentType and
								(./name() = concat($localXsdPrefix,':element') or 
								./name() = concat($localXsdPrefix,':attribute'))">

							<xsl:if test="$isArrayMode = false()">

								<xsl:choose>

									<!-- 指向xsd类型 -->
									<xsl:when test="fcn:isXsdURI($currentType,namespace::*)">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef($currentName)}" />
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

									<!-- 指向简单类型(非枚举类型) -->
									<xsl:when
										test="//xsd:simpleType[@name = substring-after($currentType,':')] and
											count(//xsd:simpleType[@name = substring-after($currentType,':')]/xsd:restriction/xsd:enumeration) = 0">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef($currentName)}" />
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
										test="//xsd:simpleType[@name = substring-after($currentType,':')] and 
										  //xsd:simpleType[@name = substring-after($currentType,':')]/xsd:restriction/@base and
										  count(//xsd:simpleType[@name = substring-after($currentType,':')]/xsd:restriction/xsd:enumeration) > 0">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty
													rdf:resource="{fcn:getAbsoluteURIRef(concat('has',$currentName))}" />
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
									<xsl:when
										test="//xsd:complexType[@name = substring-after($currentType,':')]">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty
													rdf:resource="{fcn:getAbsoluteURIRef(concat('has',$currentName))}" />
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
										test="./xsd:complexType and ./xsd:complexType/xsd:group/@ref">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty
													rdf:resource="{fcn:getAbsoluteURIRef(concat('has',$currentName))}" />
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
											./descendant::*[name() = concat($localXsdPrefix,':list')]/@itemType and
											fcn:isDatatypeDefinition(./descendant::*[name() = concat($localXsdPrefix,':list')]/@itemType,//xsd:simpleType,namespace::*)">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef($currentName)}" />
												<xsl:call-template name="cardinalityTemplate">
													<xsl:with-param name="type"
														select="./descendant::*[name() = concat($localXsdPrefix,':list')]/@itemType" />
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
											./descendant::*[name() = concat($localXsdPrefix,':list')]/@itemType and
											not(fcn:isDatatypeDefinition(./descendant::*[name() = concat($localXsdPrefix,':list')]/@itemType,//xsd:simpleType,namespace::*))">
										<rdfs:subClassOf>
											<owl:Restriction>
												<owl:onProperty
													rdf:resource="{fcn:getAbsoluteURIRef(concat('has',$currentName))}" />
												<xsl:call-template name="cardinalityTemplate">
													<xsl:with-param name="type"
														select="./descendant::*[name() = concat($localXsdPrefix,':list')]/@itemType" />
													<xsl:with-param name="isDatatypeProperty"
														select="false()" />
													<xsl:with-param name="minOccurs" select="$minOccurs" />
													<xsl:with-param name="maxOccurs" select="$maxOccurs" />
												</xsl:call-template>
											</owl:Restriction>
										</rdfs:subClassOf>
									</xsl:when>

									<xsl:otherwise>
										<!-- nothing -->
									</xsl:otherwise>

								</xsl:choose>
							</xsl:if>

							<xsl:if test="$isArrayMode = true()">
								<xsl:choose>

									<!-- 指向xsd类型 -->
									<xsl:when test="fcn:isXsdURI($currentType,namespace::*)">
										<owl:Restriction>
											<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef($currentName)}" />
											<xsl:call-template name="cardinalityTemplate">
												<xsl:with-param name="type" select="@type" />
												<xsl:with-param name="isDatatypeProperty"
													select="true()" />
												<xsl:with-param name="minOccurs" select="$minOccurs" />
												<xsl:with-param name="maxOccurs" select="$maxOccurs" />
											</xsl:call-template>
										</owl:Restriction>
									</xsl:when>

									<!-- 指向简单类型(非枚举类型) -->
									<xsl:when
										test="//xsd:simpleType[@name = substring-after($currentType,':')] and
											count(//xsd:simpleType[@name = substring-after($currentType,':')]/xsd:restriction/xsd:enumeration) = 0">
										<owl:Restriction>
											<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef($currentName)}" />
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
										test="//xsd:simpleType[@name = substring-after($currentType,':')] and 
										  //xsd:simpleType[@name = substring-after($currentType,':')]/xsd:restriction/@base and
										  count(//xsd:simpleType[@name = substring-after($currentType,':')]/xsd:restriction/xsd:enumeration) > 0">
										<owl:Restriction>
											<owl:onProperty
												rdf:resource="{fcn:getAbsoluteURIRef(concat('has',$currentName))}" />
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
									<xsl:when
										test="//xsd:complexType[@name = substring-after($currentType,':')]">

										<owl:Restriction>
											<owl:onProperty
												rdf:resource="{fcn:getAbsoluteURIRef(concat('has',$currentName))}" />
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
										test="./xsd:complexType and ./xsd:complexType/xsd:group/@ref">



										<owl:Restriction>
											<owl:onProperty
												rdf:resource="{fcn:getAbsoluteURIRef(concat('has',$currentName))}" />
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
										test="./xsd:simpleType and ./descendant::*[name() = concat($localXsdPrefix,':list')]/@itemType">
										<owl:Restriction>
											<owl:onProperty
												rdf:resource="{fcn:getAbsoluteURIRef(concat('has',$currentName))}" />
											<xsl:call-template name="cardinalityTemplate">
												<xsl:with-param name="type"
													select="./descendant::*[name() = concat($localXsdPrefix,':list')]/@itemType" />
												<xsl:with-param name="isDatatypeProperty"
													select="false()" />
												<xsl:with-param name="minOccurs" select="$minOccurs" />
												<xsl:with-param name="maxOccurs" select="$maxOccurs" />
											</xsl:call-template>
										</owl:Restriction>
									</xsl:when>

									<xsl:otherwise>
										<!-- nothing -->
									</xsl:otherwise>

								</xsl:choose>
							</xsl:if>

						</xsl:when>

						<!-- 解释sequence -->
						<xsl:when test="./name() = concat($localXsdPrefix,':sequence')">
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
						<xsl:when test="./name() = concat($localXsdPrefix,':choice')">
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

						<xsl:otherwise>
						</xsl:otherwise>

					</xsl:choose>
				</xsl:for-each>
			</xsl:when>

			<xsl:otherwise>
			</xsl:otherwise>

		</xsl:choose>
	</xsl:template>

	<xsl:template name="wrapperTranslationTemplate">

		<xsl:for-each select="//xsd:element[contains(@name,'-wrapper')]">

			<xsl:variable name="base" select="descendant::*[@base]/@base" />
			<xsl:choose>

				<xsl:when
					test="fcn:isDatatypeDefinition($base,//xsd:schema/xsd:simpleType,namespace::*)">
					<owl:DatatypeProperty
						rdf:about="{fcn:getAbsoluteURIRef(concat('has',substring-after($base,':')))}" />
				</xsl:when>
				<xsl:otherwise>
					<owl:ObjectProperty
						rdf:about="{fcn:getAbsoluteURIRef(concat('has',substring-after($base,':')))}" />
				</xsl:otherwise>
			</xsl:choose>

			<owl:Class rdf:about="{fcn:getAbsoluteURIRef(@name)}">
				<rdfs:subClassOf>
					<owl:Restriction>
						<owl:onProperty
							rdf:resource="{fcn:getAbsoluteURIRef(concat('has',substring-after($base,':')))}" />
						<owl:allValuesFrom rdf:resource="{fcn:getAbsoluteURIRef($base)}" />
					</owl:Restriction>
				</rdfs:subClassOf>
			</owl:Class>

		</xsl:for-each>

	</xsl:template>

	<xsl:template name="groupTranslationTemplate">

		<xsl:for-each select="./xsd:group">
			<xsl:if test="./xsd:choice and count(./xsd:choice/child::*) > 0">

				<owl:Class rdf:about="{fcn:getAbsoluteURIRef(@name)}">
					<rdfs:subClassOf>
						<owl:Class>
							<owl:unionOf rdf:parseType="Collection">
								<xsl:for-each select="./xsd:choice/child::*">
									<rdf:Description rdf:about="{fcn:getAbsoluteURIRef(@ref)}" />
								</xsl:for-each>
							</owl:unionOf>
						</owl:Class>
					</rdfs:subClassOf>
				</owl:Class>
			</xsl:if>
		</xsl:for-each>

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
				<owl:Class rdf:about="{fcn:getAbsoluteURIRef($classNamePrefix)}">
					<owl:equivalentClass
						rdf:resource="{fcn:getAbsoluteURIRef(concat($classNamePrefix,'1'))}" />
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

				<!-- 包装列表的首个元素 -->
				<owl:Class rdf:about="{fcn:getAbsoluteURIRef($classNamePrefix)}">
					<owl:equivalentClass
						rdf:resource="{fcn:getAbsoluteURIRef(concat($classNamePrefix,'1'))}" />
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

		<owl:ObjectProperty rdf:about="{fcn:getAbsoluteURIRef('hasNext')}">
			<rdfs:subPropertyOf rdf:resource="{fcn:getAbsoluteURIRef('isFollowedBy')}" />
		</owl:ObjectProperty>

		<owl:ObjectProperty rdf:about="{fcn:getAbsoluteURIRef('isFollowedBy')}">
			<rdf:type rdf:resource="&amp;owl;TransitiveProperty" />
			<rdfs:range rdf:resource="{fcn:getAbsoluteURIRef('IfcList')}" />
			<rdfs:domain rdf:resource="{fcn:getAbsoluteURIRef('IfcList')}" />
		</owl:ObjectProperty>

		<owl:ObjectProperty rdf:about="{fcn:getAbsoluteURIRef('hasContent')}" />
		<owl:DatatypeProperty rdf:about="{fcn:getAbsoluteURIRef('hasValue')}" />

		<owl:Class rdf:about="{fcn:getAbsoluteURIRef('EmptyList')}">
			<rdfs:subClassOf rdf:resource="{fcn:getAbsoluteURIRef('IfcList')}" />
			<rdfs:subClassOf>
				<owl:Class>
					<owl:intersectionOf rdf:parseType="Collection">
						<owl:Restriction>
							<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef('hasContent')}" />
							<owl:maxCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">0
							</owl:maxCardinality>
						</owl:Restriction>
						<owl:Restriction>
							<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef('hasValue')}" />
							<owl:maxQualifiedCardinality
								rdf:datatype="&amp;xsd;nonNegativeInteger">0</owl:maxQualifiedCardinality>
							<owl:onDataRange rdf:resource="&amp;xsd;anySimpleType" />
						</owl:Restriction>
					</owl:intersectionOf>
				</owl:Class>
			</rdfs:subClassOf>
		</owl:Class>

		<owl:Class rdf:about="{fcn:getAbsoluteURIRef('LoopList')}">
			<rdfs:subClassOf rdf:resource="{fcn:getAbsoluteURIRef('IfcList')}" />
			<rdfs:subClassOf>
				<owl:Class>
					<owl:intersectionOf rdf:parseType="Collection">
						<owl:Restriction>
							<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef('hasContent')}" />
							<owl:allValuesFrom rdf:resource="&amp;owl;Thing" />
						</owl:Restriction>
						<owl:Restriction>
							<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef('hasValue')}" />
							<owl:allValuesFrom rdf:resource="&amp;xsd;anySimpleType" />
						</owl:Restriction>
					</owl:intersectionOf>
				</owl:Class>
			</rdfs:subClassOf>
		</owl:Class>

		<owl:Class rdf:about="{fcn:getAbsoluteURIRef('IfcList')}">
			<rdfs:subClassOf>
				<owl:Restriction>
					<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef('isFollowedBy')}" />
					<owl:onClass rdf:resource="{fcn:getAbsoluteURIRef('IfcList')}" />
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

		<owl:Class rdf:about="{fcn:getAbsoluteURIRef($className)}">
			<rdfs:subClassOf rdf:resource="{fcn:getAbsoluteURIRef('IfcList')}" />
			<rdfs:subClassOf>
				<owl:Restriction>
					<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef('hasValue')}" />
					<owl:qualifiedCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">1
					</owl:qualifiedCardinality>
					<owl:onDataRange rdf:resource="{$itemType}" />
				</owl:Restriction>
			</rdfs:subClassOf>
			<xsl:if test="$isNextItemFixed = true()">
				<rdfs:subClassOf>
					<owl:Restriction>
						<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef('hasNext')}" />
						<owl:onClass rdf:resource="{fcn:getAbsoluteURIRef($nextClassName)}" />
						<owl:qualifiedCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">1
						</owl:qualifiedCardinality>
					</owl:Restriction>
				</rdfs:subClassOf>
			</xsl:if>
			<xsl:if test="$isNextItemFixed = false()">
				<rdfs:subClassOf>
					<owl:Restriction>
						<owl:onProperty rdf:resource="{fcn:getAbsoluteURIRef('hasNext')}" />
						<owl:onClass rdf:resource="{fcn:getAbsoluteURIRef($nextClassName)}" />
						<owl:maxQualifiedCardinality
							rdf:datatype="&amp;xsd;nonNegativeInteger">1</owl:maxQualifiedCardinality>
					</owl:Restriction>
				</rdfs:subClassOf>
			</xsl:if>
		</owl:Class>
	</xsl:template>

</xsl:stylesheet>
