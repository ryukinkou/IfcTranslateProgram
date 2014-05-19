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

			<!-- <xsl:call-template name="IfcListSuperClassTemplate" /> <xsl:call-template 
				name="groupTranslationTemplate" /> <xsl:call-template name="wrapperTranslationTemplate" 
				/> -->

			<!-- Datatype转换模板 -->
			<xsl:call-template name="datatypeTranslationTemplate" />

			<!-- datatypeProperty与ObjectProperty的转换模板 -->
			<xsl:call-template
				name="datatypePropertyAndObjectPropertyTranslationTemplate" />

			<!-- 模板输出占位符 -->
			<!-- <xsl:apply-templates /> -->

		</rdf:RDF>

	</xsl:template>

	<!-- Datatype的转换模板 -->
	<xsl:template name="datatypeTranslationTemplate">
		<xsl:for-each
			select="/xsd:schema/xsd:simpleType[@name and fcn:isNameIgnored(@name) = false()]">
			<xsl:choose>
				<xsl:when test=" fcn:isDatatypeDefinition(./@name)">

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

					<owl:ObjectProperty rdf:about="{fcn:getFullName(concat('has',$currentName))}">
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
							<!-- KEEP it -->
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
								rdf:about="{fcn:getFullName(concat('has',$currentName))}" />

						</xsl:when>
						<xsl:otherwise>
							<!-- KEEP it -->
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>

				<xsl:otherwise>
					<!-- KEEP it -->
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
				<!-- KEEP it -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- 尚未检查 尚未应用新API -->
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
