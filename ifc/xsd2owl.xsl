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
		match="
			xsd:schema/xsd:element[@name] 
			| 
			xsd:schema/xsd:attribute[@name]">
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
						<xsl:apply-templates />
					</rdfs:range>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

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
				<!-- 为匿名的ComplexType命名，规则为 内包含的element[@name] + Type -->
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

	<!-- complexContent只能出现在complexType之下，且子元素只能是extension或者restriction两者之一，代表着对complexType的扩展或者约束 -->
	<xsl:template
		match="
			xsd:extension[@base and parent::xsd:complexContent] 
			| 
			xsd:restriction[@base and parent::xsd:complexContent]">
		<xsl:if test="not(fcn:isXsdURI(@base, namespace::*))">
			<rdfs:subClassOf rdf:resource="{fcn:getRdfURI(@base, namespace::*)}" />
		</xsl:if>
		<xsl:apply-templates />
	</xsl:template>

	<!-- 匹配非内嵌于sequence与choice的sequence -->
	<xsl:template
		match="
			xsd:sequence[
				not(parent::xsd:sequence) and 
				not(parent::xsd:choice)
			]">
		<rdfs:subClassOf>
			<xsl:call-template name="sequenceTranslationTemplate" />
		</rdfs:subClassOf>
	</xsl:template>

	<!-- 匹配非内嵌于sequence与choice的sequence -->
	<xsl:template
		match="
			xsd:choice[
				not(parent::xsd:sequence) and 
				not(parent::xsd:choice)]">
		<rdfs:subClassOf>
			<xsl:call-template name="choiceTranslationTemplate" />
		</rdfs:subClassOf>
	</xsl:template>

	<!-- 匹配all标签 -->
	<xsl:template match="xsd:all">
		<rdfs:subClassOf>
			<xsl:call-template name="sequenceTranslationTemplate" />
		</rdfs:subClassOf>
	</xsl:template>

	<!-- intersectionOf 交集 sequence元素以指定的顺序被包含，的确是一个限定 -->
	<xsl:template name="sequenceTranslationTemplate" match="xsd:sequence">
		<xsl:choose>
			<xsl:when test="count(child::*)>0">
				<owl:Class>
					<owl:intersectionOf rdf:parseType="Collection">
						<xsl:apply-templates />
					</owl:intersectionOf>
				</owl:Class>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- unionOf 并集 choice只允许选出一个元素 -->
	<xsl:template name="choiceTranslationTemplate" match="xsd:choice">
		<xsl:choose>
			<xsl:when test="count(child::*)>0">
				<owl:Class>
					<owl:unionOf rdf:parseType="Collection">
						<xsl:apply-templates />
					</owl:unionOf>
				</owl:Class>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- 转换complexType中的element，将他们转换为property -->
	<xsl:template
		match="
			xsd:element[
				@name and 
				@type and 
				(ancestor::xsd:complexType or ancestor::xsd:group)
		]">
		<owl:Restriction>
			<owl:onProperty rdf:resource="#{@name}" />
			<owl:allValuesFrom
				rdf:resource="{fcn:getDatatypeDefinition(., //xsd:simpleType[@name], namespace::*)}" />
				
				<xsl:message>aaa | <xsl:value-of select="fcn:getDatatypeDefinition(., //xsd:simpleType[@name], namespace::*)" /></xsl:message>
				
		</owl:Restriction>
		<!-- 基数转换 -->
		<xsl:call-template name="cardinalityTranslationTemplate">
			<xsl:with-param name="min"
				select="(@minOccurs | parent::*/@minOccurs)[1]" />
			<xsl:with-param name="max"
				select="(@maxOccurs | parent::*/@maxOccurs)[1]" />
			<xsl:with-param name="property" select="@name" />
			<xsl:with-param name="forceRestriction" select="false()" />
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="cardinalityTranslationTemplate">
		<xsl:param name="min" />
		<xsl:param name="max" />
		<xsl:param name="property" />
		<xsl:param name="forceRestriction" />

		<xsl:variable name="minOccurs">
			<xsl:choose>
				<xsl:when test="$min">
					<xsl:value-of select="$min" />
				</xsl:when>
				<xsl:otherwise>
					1
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="maxOccurs">
			<xsl:choose>
				<xsl:when test="$max">
					<xsl:value-of select="$max" />
				</xsl:when>
				<xsl:otherwise>
					1
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- <xsl:message select="$property" /> -->

		<xsl:if test="$minOccurs!='0' and contains($property,'&amp;ifc;')">
			<owl:Restriction>
				<owl:onProperty rdf:resource="{$property}" />
				<owl:minCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">
					<xsl:value-of select="$minOccurs" />
				</owl:minCardinality>
			</owl:Restriction>
		</xsl:if>

		<xsl:if test="$minOccurs!='0' and not(contains($property,'&amp;ifc;'))">
			<owl:Restriction>
				<owl:onProperty rdf:resource="#{$property}" />
				<owl:minCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">
					<xsl:value-of select="$minOccurs" />
				</owl:minCardinality>
			</owl:Restriction>

			<xsl:message><xsl:value-of select="$property" /></xsl:message>

		</xsl:if>

		<xsl:if test="$maxOccurs!='unbounded' and contains($property,'&amp;ifc;')">
			<owl:Restriction>
				<owl:onProperty rdf:resource="{$property}" />
				<owl:maxCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">
					<xsl:value-of select="$maxOccurs" />
				</owl:maxCardinality>
			</owl:Restriction>
		</xsl:if>

		<xsl:if
			test="$maxOccurs!='unbounded' and not(contains($property,'&amp;ifc;'))">
			<owl:Restriction>
				<owl:onProperty rdf:resource="#{$property}" />
				<owl:maxCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">
					<xsl:value-of select="$maxOccurs" />
				</owl:maxCardinality>
			</owl:Restriction>
		</xsl:if>

		If restriction not needed because min=0 and max="unbounded", generate 
			it if forceRestriction="true" because there is not any other restriction 
			on the property

		<xsl:if
			test="$minOccurs='0' and $maxOccurs='unbounded' and $forceRestriction  and contains($property,'&amp;ifc;')">
			<owl:Restriction>
				<owl:onProperty rdf:resource="{$property}" />
				<owl:minCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">
					<xsl:value-of select="$minOccurs" />
				</owl:minCardinality>
			</owl:Restriction>
		</xsl:if>

		<xsl:if
			test="$minOccurs='0' and $maxOccurs='unbounded' and $forceRestriction and not(contains($property,'&amp;ifc;'))">
			<owl:Restriction>
				<owl:onProperty rdf:resource="#{$property}" />
				<owl:minCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">
					<xsl:value-of select="$minOccurs" />
				</owl:minCardinality>
			</owl:Restriction>
		</xsl:if>

	</xsl:template>

</xsl:stylesheet>
