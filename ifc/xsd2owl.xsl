<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
	xmlns:fcn="http://www.liujinhang.cn/ifc/xsd2owl-functions.xsl"
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
	<xsl:key name="propertiesExceptRoot"
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
					and generate-id()=generate-id(key('propertiesExceptRoot',@name)[1])
				]|
				//xsd:attribute [ 
					@name
					and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup) 
					and generate-id()=generate-id(key('propertiesExceptRoot',@name)[1])
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
						<owl:ObjectProperty rdf:ID="{@name}" />
					</xsl:when>

					<!-- 转换为Property -->
					<xsl:otherwise>
						<rdf:Property rdf:ID="{@name}" />
					</xsl:otherwise>

				</xsl:choose>

			</xsl:for-each>
		</rdf:RDF>

	</xsl:template>

	<!-- 针对在根节点之下定义的element与attribute -->
	<xsl:template
		match="xsd:schema/xsd:element[@name] | xsd:schema/xsd:attribute[@name]">

		<xsl:choose>
			<!-- DatatypeProperty -->
			<xsl:when
				test="
					fcn:isConvertToDatatypeProperty(.,//xsd:simpleType[@name],namespace::*) 
					and not(
					fcn:isConvertToObjectProperty(.,//xsd:complexType[@name],namespace::*)
					)">
				<owl:DatatypeProperty rdf:ID="{@name}">
					<xsl:call-template name="propertyTranslationTemplate" />
				</owl:DatatypeProperty>
			</xsl:when>
			<!-- ObjectProperty -->
			<xsl:when
				test="
					fcn:isConvertToObjectProperty(.,//xsd:complexType[@name],namespace::*)
					and not(
					fcn:isConvertToDatatypeProperty(.,//xsd:simpleType[@name],namespace::*)
					)">
				<owl:ObjectProperty rdf:ID="{@name}">
					<xsl:call-template name="propertyTranslationTemplate" />
				</owl:ObjectProperty>
			</xsl:when>
			<xsl:otherwise>
				<rdf:Property rdf:ID="{@name}">
					<xsl:call-template name="propertyTranslationTemplate" />
				</rdf:Property>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- element/attribute => property 转换模板 -->
	<xsl:template name="propertyTranslationTemplate">
		<!-- substitutionGroup => subPropertyOf -->
		<xsl:if test="@substitutionGroup">
			<rdfs:subPropertyOf
				rdf:resource="{fcn:getRdfURI(@substitutionGroup, namespace::*)}" />
		</xsl:if>
		<xsl:choose>
			<xsl:when test="@type">
				<!-- type => rdfs:range -->
				<rdfs:range
					rdf:resource="{fcn:getDatatypeDefinition(.,//xsd:simpleType[@name], namespace::*)}" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="./xsd:complexType">
					<rdfs:range>
						<xsl:message select="." />
						<xsl:apply-templates />
					</rdfs:range>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

		<!-- Match XML Schema complexType or group definitions to generate classes, 
		if the embededType has a value this is a complex type defined inside and 
		element, distinguish its name from the name of the element using the embededType 
		param value -->
	<!-- processComplexType complexType/group/attributeGroup => class 转换模板 -->
	<xsl:template name="classTransationTemplate"
		match="
			xsd:complexType|
			xsd:group|
			xsd:attributeGroup">
		<xsl:if test="@name">
			<owl:Class rdf:ID="{@name}">
				<xsl:apply-templates />
			</owl:Class>
		</xsl:if>
		<xsl:if test="not(@name)">
			<xsl:choose>
				<xsl:when test="parent::xsd:element[@name]">
					<owl:Class rdf:ID="{../@name}Type">
						<xsl:apply-templates />
					</owl:Class>
				</xsl:when>
				<xsl:otherwise>
					<owl:Class>
						<xsl:apply-templates />
					</owl:Class>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
