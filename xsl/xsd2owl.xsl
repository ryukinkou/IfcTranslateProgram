<?xml version="1.0" encoding="UTF-8"?>

<!-- XSLT 2.0版本 引入外部文档xsd2owl-functions.xsl的命名空间,使用自定义前缀xo -->
<xsl:stylesheet version="2.0"
	xmlns:xo="http://rhizomik.net/redefer/xsl/xsd2owl-functions.xsl"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:owl="http://www.w3.org/2002/07/owl#">

	<!-- 导入文档 -->
	<xsl:import href="xsd2owl-functions.xsl" />

	<!-- 定义结果输出文档的格式 使用character maps进行特殊字符的转换，该过程处于文档的序列化阶段，也就是在文档生成完毕之后执行，indent：是否进行缩进排列 -->
	<xsl:output media-type="text/xml" version="1.0" encoding="UTF-8"
		indent="yes" use-character-maps="owl" />

	<!-- 删除所有元素的空格 -->
	<xsl:strip-space elements="*" />

	<!-- character map定义,里面定义了'&amp;'的序列化方式，'&amp;'是符号'&'的转义 -->
	<xsl:character-map name="owl">
		<xsl:output-character character="&amp;" string="&amp;" />
	</xsl:character-map>

	<!-- TEST -->
	<!-- Used to avoid repeated creation of the properties implicitly created 
		as elements or attributes inside complexTypes, groups and attribute groups 
		declarations and contains(xo:makeRDFAbsoluteRefFunc(@name),'http://www.w3.org/2001/XMLSchema#')
		
		<xsl:key name="distinctElements" match="//xsd:element[@name and (ancestor::xsd:complexType 
		or ancestor::xsd:group) and not(xo:existsElemOrAtt(/xsd:schema, @name))]" 
		use="@name"/> <xsl:key name="distinctAttributes" match="//xsd:attribute[@name 
		and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup) and not(xo:existsElemOrAtt(/xsd:schema, 
		@name))]" use="@name"/ -->

	<!-- Used to avoid repeated creation of the properties implicitly created 
		as elements or attributes inside complexTypes, groups and attribute groups 
		declarations -->

	<!-- 
		key类似函数，最终将生产一个map<string,element>。name为健的值。
	    
	    XPATH：
		//xsd:element //类型为element，不论位置的选取所有的element 
		[ @name //name = @name
		and (ancestor::xsd:complexType or ancestor::xsd:group) //他的父级节点中有complexType与group，也就是说该元素是complexType或者group的子元素 
		and not(xo:existsElemOrAtt(/xsd:schema, @name)) //名称为name的element不应是xsd:schema的直系子节点 
		] 
		| 
		//xsd:attribute //类型为attribute，不论位置的选取所有的attribute 
		[ @name 
		and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup) 
		and not(xo:existsElemOrAtt(/xsd:schema, @name)) ]
		
		返回name属性为@name的，处于complexType和group/attributeGroup内部的且不能位于根节点之下的（其实若是处于元素的内部，那么自然就不会直接位于根节点之下）的element/attribute
		
	-->
	<xsl:key name="distinctProperties"
	
		match="
		//xsd:element[
		@name 
		and (ancestor::xsd:complexType or ancestor::xsd:group) 
		and not(xo:existsElemOrAtt(/xsd:schema, @name))
		] |
		//xsd:attribute[
		@name 
		and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup) 
		and not(xo:existsElemOrAtt(/xsd:schema, @name))
		]"
		
		use="@name" />

	<!-- Get the default namespace and build a entity definition for it -->
	<!-- 全局变量 targetNamespace,获取xsd:schema节点的targetNamespace属性 targetNamespace属性类似于顶层包的概念 -->
	<xsl:variable name="targetNamespace">
		<xsl:value-of select="/xsd:schema/@targetNamespace" />
	</xsl:variable>

	<!-- 遍历所有的命名空间，当命名空间与targetNamespace相同的时候，抽取name作为baseEntity -->
	<xsl:variable name="baseEntity">

		<xsl:text disable-output-escaping="yes">&amp;</xsl:text> <!-- 前面加上'&amp;',以非转义的方式 -->
		<xsl:for-each select="/xsd:schema/namespace::*"> <!-- 找到targetNamespace的prefix -->
			<xsl:if test=". = $targetNamespace">
				<xsl:value-of select="name()" />
			</xsl:if>
		</xsl:for-each>
		<xsl:text disable-output-escaping="yes">;</xsl:text> <!-- 后面加上; -->

	</xsl:variable>

	<!-- Match the xsd:schema element to generate the entity definitions from 
		the used namespaces. Then, the rdf:RDF element and the the ontology subelement 
		are generated. Finally, the rest of the XML Schema is processed. -->

	<!-- 建立匹配xsd:schema的模板 TODO 但是文档是以xs:schema开头的，而非xsd:schema， -->
	<xsl:template match="/xsd:schema">

		<!-- DOCTYPE指令 START DOCTYPE指令类似告诉编译器如何解释执行该文档的编译器指令，类似于包引用 输出这段编译器指令类似于拼接字符串 -->
		<!-- Generate entity definitions for each namespace -->
		<!-- &#10; 换行符 &lt; '<'符号 -->
		<xsl:text disable-output-escaping="yes">&#10;&lt;!DOCTYPE rdf:RDF [&#10;</xsl:text>
		<!-- Allways include xsd entity and thus ignore if also defined in input 
			xsd -->
		<!-- &#09; 'tab'制表符 &gt; '>' 符号 输出 <!ENTITY xsd 'http://www.w3.org/2001/XMLSchema#'> -->
		<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY xsd 'http://www.w3.org/2001/XMLSchema#'&gt;&#10;</xsl:text>

		<!-- 取得XSD中定义的namespace并输出到DOCTYPE 排除namespace是空或xsd的命名空间定义 -->
		<xsl:for-each select="namespace::*[not(name()='' or name()='xsd')]">
			<!-- 输出 <!ENTITY name() '$namespace' > -->
			<xsl:text disable-output-escaping="yes">&#09;&lt;!ENTITY </xsl:text>
			<xsl:value-of select="name()" />
			<xsl:text disable-output-escaping="yes"> '</xsl:text>
			<xsl:choose>
				<!-- '.' 为namespace的实体，如果namespace的实体为targetNamespace的时候，仅输出'#'符号 -->
				<xsl:when test=". = $targetNamespace">
					<xsl:text disable-output-escaping="yes">#</xsl:text>
				</xsl:when>
				<xsl:otherwise>      
					<!-- 如果namespace不为targetNamespace，就需要输出namespace本身做为对外界的引用，如果namespace的结尾不是#,那么需要自行加上#符号 -->
					<xsl:value-of select="." />
					<xsl:if test="not(contains(.,'#'))">
						<xsl:text disable-output-escaping="yes">#</xsl:text>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
			<!-- 输出 '> -->
			<xsl:text disable-output-escaping="yes">'&gt;&#10;</xsl:text>
		</xsl:for-each>

		<!-- 输出 ]> -->
		<xsl:text disable-output-escaping="yes">]&gt;&#10;</xsl:text>
		<!-- DOCTYPE指令 END -->

		<!-- Build the rdf:RDF element with the namespace declarations for the 
			declared namespace entities -->

		<!-- 输出rdf:RDF标签 -->
		<rdf:RDF>

			<!-- Detect the namespaces used in the XMLSchema that must be copied to 
				the OWL ontology -->

			<!-- XPATH： 找出所有在本文档中使用过的命名空间，但是不包含 命名空间为空的与命名空间前缀为xsd和xml的 没有定义的namespace会引用DOCTYPE里面的命名空间 -->
			<xsl:variable name="used_namespaces">

				<!-- xml前缀的命名空间为'http://www.w3.org/XML/1998/namespace'不可变更 -->
				<xsl:for-each
					select="namespace::*[not(name()='' or name()='xsd' or name()='xml')]">

					<!-- TEST -->
					<xsl:message>
						used namespaces :
						<xsl:value-of select="name()" />
					</xsl:message>

					<xsl:element name="{name()}:x" namespace="&#38;{name()};" />
				</xsl:for-each>
			</xsl:variable>

			<!-- Copy the required namespaces collected in the "used_namespaces" variable 
				declaration, which acts as their temporal container -->
			<!--xsl:copy-of select="node-set($used_namespaces)/*/namespace::*"/ -->

			<!-- TEST 为啥有个x -->
			<xsl:message>
				used namespaces array name() :
				<xsl:value-of select="$used_namespaces/*/name()" />
			</xsl:message>

			<!-- 制作一个namespace副本 将used_namespaces中的*所有员的的namespace抽出来 -->
			<xsl:copy-of select="$used_namespaces/*/namespace::*" />

			<!-- TEST -->
			<xsl:message>
				used namespaces array namespaces :
				<xsl:value-of select="$used_namespaces/ */namespace::*" />
			</xsl:message>

			<!-- 处理owl:Ontology标记，主要是有xsd:import的时候如何处理的问题 -->
			<owl:Ontology rdf:about="">
				<rdfs:comment>OWL ontology generated by the xsd2owl XML Style Sheet
				</rdfs:comment>
				<!-- Create the owl:imports elements corresponding to the xsd:import 
					elements -->

				<!-- xsd:import xsd的外部引用 @选取属性 抽出子节点中 /.xsd:import中namespace不为'http://www.w3.org/2001/XMLSchema'的定义 
					这里主要是查看xsd:import属性 ifc文档中不存在外部引用，所有定义都是在同一个文档中完成 xsd:import属性需要绕开XMLSchema的定义 -->

				<xsl:for-each
					select="./xsd:import[@namespace!='http://www.w3.org/2001/XMLSchema']">

					<!-- TEST -->
					<xsl:message>
						namespace :
						<xsl:value-of select="@namespace" />
					</xsl:message>

					<!-- 获得这个节点的namespace定义，放入namespaceAtt变量中 -->
					<xsl:variable name="namespaceAtt">
						<xsl:value-of select="@namespace" />
					</xsl:variable>

					<!-- If there is an alias for the namespace, use it. Otherwise, use 
						the namespace URI -->

					<!-- 如果这个xsd:import没有定义namespace属性，在顶层定义的namespace中 -->
					<xsl:variable name="importRef">
						<xsl:for-each select="namespace::*">
							<xsl:if test=". = $namespaceAtt">
								<xsl:value-of select="name()" />
							</xsl:if>
						</xsl:for-each>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="not($importRef='')">
							<owl:imports rdf:resource="&amp;{$importRef};" />
						</xsl:when>
						<xsl:otherwise>
							<owl:imports rdf:resource="{$namespaceAtt}" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</owl:Ontology>
			<xsl:apply-templates />

			<!-- Generate the OWL class definitions for the complexTypes totally declared 
				inside other ones, in order to avoid repetitions: and generate-id()=generate-id(key('newClasses',@name)) -->

			<!-- XPATH //xsd:element [ not(@type or @ref) and 表示不含有type和ref标签 ( ancestor::xsd:complexType 
				并且父级节点中含有xsd:complexType或者xsd:group or ancestor::xsd:group ) ] /xsd:complexType -->

			<!-- <xsl:for-each select="//xsd:element[not(@type or @ref) and (ancestor::xsd:complexType 
				or ancestor::xsd:group)]/xsd:complexType"> <xsl:call-template name="processComplexType"/> 
				</xsl:for-each> -->

			<!-- Add the any ObjectProperty for xsd:any -->
			<owl:ObjectProperty rdf:ID="any" />

			<!-- Explicitly create the new properties defined inside complexTypes, 
				groups and attributGroups using the key to select only distinct ones -->
			
			<!-- XPATH
			//xsd:element
			[ 
				@name and //name属性不为空，若为空将会自动转换为false
				(ancestor::xsd:complexType or ancestor::xsd:group) and 上级标签中需要包含complexType与xsd:group，即需要被这些标签所包围
				generate-id()=generate-id(key('distinctProperties',@name)[1])
			] | 
			//xsd:attribute
			[
				@name and 
				(ancestor::xsd:complexType or ancestor::xsd:attributeGroup) and 
				generate-id()=generate-id(key('distinctProperties',@name)[1])
			] 
			
			抽出所有位于complexType和group/attributeGroup内部的element/attribute元素，并且去除重复的元素，这里应该是bug的所在
			 -->
				
			<xsl:for-each
			
				select="
				//xsd:element
				[ 
				@name and 
				(ancestor::xsd:complexType or ancestor::xsd:group) and 
				generate-id()=generate-id(key('distinctProperties',@name)[1])
				] | 
				//xsd:attribute
				[
				@name and 
				(ancestor::xsd:complexType or ancestor::xsd:attributeGroup) and 
				generate-id()=generate-id(key('distinctProperties',@name)[1])
				]
				">
				<xsl:sort select="@name" order="ascending" />
				<!-- If it can be determined to be an element or attribute associated 
					with datatype only values (i.e. simpleTypes) then map it to a owl:DatatypeProperty. 
					If it is associated with objectype only values (i.e. complexTypes) then map 
					it to owl:ObjectProperty. Otherwise, use rdf:Property to cope with both kinds 
					of values -->
				
				<!-- TEST -->
				<xsl:message>BUG</xsl:message>
				
				<!-- 
				<xsl:message>generate-id ：<xsl:value-of select="generate-id()" /></xsl:message>
				<xsl:message>@name ：<xsl:value-of select="@name" /></xsl:message>
				<xsl:message>name()：<xsl:value-of select="name()" /></xsl:message>
				<xsl:message>distinctProperties @name ：<xsl:value-of select="name(key('distinctProperties',@name)[1])" /></xsl:message>
				<xsl:message>xsd:complexType[@name] : <xsl:value-of select="//xsd:complexType[@name]/@name" /></xsl:message>
				 -->
				 
				<xsl:variable name="currentName">
					<xsl:value-of select="@name" />
				</xsl:variable>
				
				<xsl:choose>
					<!--xsl:when test="xo:isDatatype(.,//xsd:simpleType[@name],namespace::*) 
						and not(xo:isObjectype(.,//xsd:complexType[@name],namespace::*))" -->
					<!-- 
						XPATH:
						
						xo:allDatatype
						(
							//xsd:element /* 名称为$currentName并且位于complexType与group的内部的element */
							[
								@name = $currentName 
								and 
									(
									ancestor::xsd:complexType 
									or 
									ancestor::xsd:group
									)
							]
							|
							//xsd:attribute /* 名称为$currentName并且位于complexType与attributeGroup的内部的attribute */
							[
								@name = $currentName 
								and
									(
									ancestor::xsd:complexType 
									or 
									ancestor::xsd:attributeGroup
									)
							], 
							//xsd:complexType[@name], /* 应该是取得所有拥有name属性的complexType ? */
							namespace::*
						)
					 -->
					
					<xsl:when
						test="
						xo:allDatatype
						(
							//xsd:element
							[
								@name = $currentName 
								and 
									(
									ancestor::xsd:complexType 
									or 
									ancestor::xsd:group
									)
							]
							|
							//xsd:attribute
							[
								@name = $currentName 
								and
									(
									ancestor::xsd:complexType 
									or 
									ancestor::xsd:attributeGroup
									)
							], 
							//xsd:complexType[@name], 
							namespace::*
						)
						">
						
						<owl:DatatypeProperty rdf:ID="{@name}" />
					</xsl:when>
					<!--xsl:when test="xo:isObjectype(.,//xsd:complexType[@name],namespace::*) 
						and not(xo:isDatatype(.,//xsd:simpleType[@name],namespace::*))" -->
					<xsl:when
						test="xo:allObjectype(//xsd:element[@name=$currentName and (ancestor::xsd:complexType or ancestor::xsd:group)] | 
										 //xsd:attribute[@name=$currentName and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup)],
										 //xsd:simpleType[@name], namespace::*)">
						<owl:ObjectProperty rdf:ID="{@name}" />
					</xsl:when>
					<xsl:otherwise>
						<rdf:Property rdf:ID="{@name}" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</rdf:RDF>

		<!--Generate separated document with the datatype declarations for explicit 
			and implicit simpleTypes -->
		<!--xsl:result-document href="datatypes.xml"> <!- Generate the definitions 
			for the simpleTypes totally declared inside other ones -> <xsl:for-each select="//xsd:element[not(@type 
			or @ref) and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup or 
			ancestor::xsd:group) and generate-id()=generate-id(key('newClasses',@name))]/xsd:simpleType 
			| //xsd:attribute[not(@type or @ref) and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup 
			or ancestor::xsd:group) and generate-id()=generate-id(key('newClasses',@name))]/xsd:simpleType"> 
			<xsl:call-template name="processSimpleType"/> </xsl:for-each> <!- Match simpleType 
			definitions -> <xsl:for-each select="//xsd:simpleType"> <xsl:if test="@name"> 
			<owl:Class rdf:ID="{@name}"/> </xsl:if> <xsl:if test="not(@name)"> <xsl:choose> 
			<!- If it is an anonymous simpleType embeded in a element definition generate 
			a rdf:ID derived from the element definition name -> <xsl:when test="parent::xsd:element[@name]"> 
			<owl:Class rdf:ID="{parent::xsd:element/@name}Range"/> </xsl:when> <xsl:when 
			test="parent::xsd:attribute[@name]"> <owl:Class rdf:ID="{parent::xsd:attribute/@name}Range"/> 
			</xsl:when> <xsl:otherwise> <owl:Class/> </xsl:otherwise> </xsl:choose> </xsl:if> 
			</xsl:for-each> </xsl:result-document -->
	</xsl:template>

	<!-- Match XML Schema element definitions to generate OWL ObjectProperties 
		and DatatypeProperties: 1. Map substitutionGroup attribute to subPropertyOf 
		relation 2. Map type attribute or embeded complexType to range relation -->
	<xsl:template
		match="xsd:schema/xsd:element[@name]|xsd:schema/xsd:attribute[@name and not(xo:existsElem(/xsd:schema/xsd:element,@name))]">
		<!-- Use the same criteria than for elements and attributed defined inside 
			complexTypes, groups and attributGroups -->



		<xsl:choose>
			<xsl:when
				test="xo:isDatatype(.,//xsd:simpleType[@name],namespace::*) and 
							 not(xo:isObjectype(.,//xsd:complexType[@name],namespace::*))">
				<owl:DatatypeProperty rdf:ID="{@name}">
					<xsl:call-template name="processElemDef" />
				</owl:DatatypeProperty>

			</xsl:when>
			<xsl:when
				test="xo:isObjectype(.,//xsd:complexType[@name],namespace::*) and 
							not(xo:isDatatype(.,//xsd:simpleType[@name],namespace::*))">
				<owl:ObjectProperty rdf:ID="{@name}">
					<xsl:call-template name="processElemDef" />
				</owl:ObjectProperty>
			</xsl:when>
			<xsl:otherwise>
				<rdf:Property rdf:ID="{@name}">
					<xsl:call-template name="processElemDef" />
				</rdf:Property>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="processElemDef">
		<!-- The class hierarchy is defined by the substitutionGroup attribute -->
		<xsl:if test="@substitutionGroup">
			<rdfs:subPropertyOf rdf:resource="{xo:rdfUri(@substitutionGroup, namespace::*)}" />
		</xsl:if>
		<!-- The type attribute or the embeded complexType define equivalent classes -->
		<xsl:choose>
			<xsl:when test="@type">
				<rdfs:range
					rdf:resource="{xo:rangeUri(., //xsd:simpleType[@name], namespace::*)}" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="./xsd:complexType">
					<!-- Generate anonymous class definition from complexType -->
					<rdfs:range>
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
	<xsl:template name="processComplexType"
		match="xsd:complexType|xsd:group|xsd:attributeGroup">
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
					<owl:Class>	<!--rdf:ID="_:{generate-id()}" -->
						<xsl:apply-templates />
					</owl:Class>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<!-- Match extension or restriction base to generate subClassOf relation 
		for complexType definitions -->
	<!-- Avoid the creation of subclasses of XSD datatypes -->
	<xsl:template
		match="xsd:extension[@base and parent::xsd:complexContent] | xsd:restriction[@base and parent::xsd:complexContent]">
		<xsl:if test="not(xo:isXsdUri(@base, namespace::*))">
			<rdfs:subClassOf rdf:resource="{xo:rdfUri(@base, namespace::*)}" />
		</xsl:if>
		<xsl:apply-templates />
	</xsl:template>

	<!-- For xsd:sequence or xsd:choice that is not inside other sequences or 
		choices generate the initial rdfs:subClassOf relation that links it to the 
		class it defines -->
	<xsl:template
		match="xsd:sequence[not(parent::xsd:sequence) and not(parent::xsd:choice)]">
		<rdfs:subClassOf>
			<xsl:call-template name="processSequence" />
		</rdfs:subClassOf>
	</xsl:template>
	<xsl:template
		match="xsd:choice[not(parent::xsd:sequence) and not(parent::xsd:choice)]">
		<rdfs:subClassOf>
			<xsl:call-template name="processChoice" />
		</rdfs:subClassOf>
	</xsl:template>

	<!-- jmv: since order is not relevant in OWL, treat xsd:all as xsd:sequence 
		From schema-0 at W3C: All the elements in the group may appear once or not 
		at all, and they may appear in any order. The all group is limited to the 
		top-level of any content model. Moreover, the group's children must all be 
		individual elements (no groups), and no element in the content model may 
		appear more than once, i.e. the permissible values of minOccurs and maxOccurs 
		are 0 and 1. -->
	<xsl:template match="xsd:all">
		<rdfs:subClassOf>
			<xsl:call-template name="processSequence" />
		</rdfs:subClassOf>
	</xsl:template>

	<!-- Match xsd:sequence to generate a owl:intersectionOf if number of childs 
		> 0 -->
	<xsl:template name="processSequence" match="xsd:sequence">
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
	<!-- Match xsd:choice to generate a owl:unionOf (disjoint?) if number of 
		childs > 1 -->
	<xsl:template name="processChoice" match="xsd:choice">
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

	<!-- Match xsd:annotations to generate rdfs:comments -->
	<xsl:template match="xsd:annotation/xsd:documentation">
		<!--rdfs:comment><xsl:value-of select="."/></rdfs:comment> <xsl:if test="@source"> 
			<rdfs:seeAlso><xsl:value-of select="@source"/></rdfs:seeAlso> </xsl:if -->
	</xsl:template>
	<xsl:template match="xsd:annotation/xsd:appinfo">
		<!--rdfs:comment rdf:parseType="Literal"><xsl:value-of select="."/></rdfs:comment -->
	</xsl:template>

	<!-- Match elements inside complexType to generate owl:Restrictions over 
		the owl:Class defined by the complexType -->
	<!-- Match elements declared inside the complexType with a reference to 
		an external type -->
	<xsl:template
		match="xsd:element[@name and @type and (ancestor::xsd:complexType or ancestor::xsd:group)]">
		<owl:Restriction>
			<owl:onProperty rdf:resource="#{@name}" />
			<owl:allValuesFrom
				rdf:resource="{xo:rangeUri(., //xsd:simpleType[@name], namespace::*)}" />
		</owl:Restriction>
		<xsl:call-template name="cardinality">
			<xsl:with-param name="min"
				select="(@minOccurs | parent::*/@minOccurs)[1]" />
			<xsl:with-param name="max"
				select="(@maxOccurs | parent::*/@maxOccurs)[1]" />
			<xsl:with-param name="property" select="@name" />
			<xsl:with-param name="forceRestriction" select="false()" />
		</xsl:call-template>
	</xsl:template>

	<!-- Match elements declared outside the complexType and referenced from 
		it -->
	<xsl:template
		match="xsd:element[@ref and (ancestor::xsd:complexType or ancestor::xsd:group)]">
		<xsl:call-template name="cardinality">
			<xsl:with-param name="min"
				select="(@minOccurs | parent::*/@minOccurs)[1]" />
			<xsl:with-param name="max"
				select="(@maxOccurs | parent::*/@maxOccurs)[1]" />
			<xsl:with-param name="property" select="xo:rdfUri(@ref, namespace::*)" />
			<xsl:with-param name="forceRestriction" select="true()" />
		</xsl:call-template>
	</xsl:template>

	<!-- Match elements totally declared inside the complexType, if simpleType 
		generate URI, otherwise embed class declaration for complexType -->
	<xsl:template
		match="xsd:element[not(@type or @ref) and (ancestor::xsd:complexType or ancestor::xsd:group)]">
		<owl:Restriction>
			<owl:onProperty rdf:resource="#{@name}" />
			<xsl:choose>
				<xsl:when test="count(./xsd:simpleType)>0">
					<owl:allValuesFrom rdf:resource="{xo:newRangeUri(., $baseEntity)}" />
				</xsl:when>
				<xsl:otherwise>
					<owl:allValuesFrom>
						<xsl:apply-templates select="./*" />
					</owl:allValuesFrom>
				</xsl:otherwise>
			</xsl:choose>
		</owl:Restriction>
		<xsl:call-template name="cardinality">
			<xsl:with-param name="min"
				select="(@minOccurs | parent::*/@minOccurs)[1]" />
			<xsl:with-param name="max"
				select="(@maxOccurs | parent::*/@maxOccurs)[1]" />
			<xsl:with-param name="property" select="@name" />
			<xsl:with-param name="forceRestriction" select="false()" />
		</xsl:call-template>
	</xsl:template>

	<!-- Generate cardinality constraints. Default maxCardinality and minCardinality 
		equal to 1, if no maxOccurs or minOccurs specified -->
	<!-- 基数转换，默认为max与min都设为1 -->
	<xsl:template name="cardinality">
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

			<!-- <xsl:message><xsl:value-of select="$property" /></xsl:message> -->

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

		<!-- If restriction not needed because min=0 and max="unbounded", generate 
			it if forceRestriction="true" because there is not any other restriction 
			on the property -->

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

	<!-- Match attribute definitions inside complexType to generate owl:Restricitons -->
	<xsl:template
		match="xsd:attribute[@name and @type and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup)]">
		<rdfs:subClassOf>
			<owl:Restriction>
				<owl:onProperty rdf:resource="#{@name}" />
				<owl:allValuesFrom
					rdf:resource="{xo:rangeUri(., //xsd:simpleType[@name], namespace::*)}" />
			</owl:Restriction>
		</rdfs:subClassOf>
		<xsl:if test="@use='required'">
			<rdfs:subClassOf>
				<owl:Restriction>
					<owl:onProperty rdf:resource="#{@name}" />
					<owl:minCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">1
					</owl:minCardinality>
				</owl:Restriction>
			</rdfs:subClassOf>
		</xsl:if>
	</xsl:template>

	<!-- Match attributes declared outside the complexType and referenced from 
		it -->
	<xsl:template
		match="xsd:attribute[@ref and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup) and @ref!='xml:lang']">
		<xsl:variable name="minOccurs">
			<xsl:choose>
				<xsl:when test="@use='required'">
					1
				</xsl:when>
				<xsl:otherwise>
					0
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<rdfs:subClassOf>
			<owl:Restriction>
				<owl:onProperty rdf:resource="{xo:rdfUri(@ref, namespace::*)}" />
				<owl:minCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">
					<xsl:value-of select="$minOccurs" />
				</owl:minCardinality>
			</owl:Restriction>
		</rdfs:subClassOf>
	</xsl:template>

	<!-- Match attributes totally declared inside the complexType -->
	<xsl:template
		match="xsd:attribute[not(@type or @ref) and (ancestor::xsd:complexType or ancestor::xsd:attributeGroup)]">
		<xsl:if test="not(@use='required')">
			<rdfs:subClassOf>
				<owl:Restriction>
					<owl:onProperty rdf:resource="#{@name}" />
					<owl:minCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">0
					</owl:minCardinality>
				</owl:Restriction>
			</rdfs:subClassOf>
		</xsl:if>
		<!-- <rdfs:subClassOf> <owl:Restriction> <owl:onProperty rdf:resource="#{@name}"/> 
			<owl:allValuesFrom rdf:resource="{xo:newRangeUri(., $baseEntity)}"/> </owl:Restriction> 
			</rdfs:subClassOf> -->
		<xsl:if test="@use='required'">
			<rdfs:subClassOf>
				<owl:Restriction>
					<owl:onProperty rdf:resource="#{@name}" />
					<owl:minCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">1
					</owl:minCardinality>
				</owl:Restriction>
			</rdfs:subClassOf>
		</xsl:if>
	</xsl:template>

	<!-- Match group references as the corresponding class for the group -->
	<xsl:template match="xsd:group[@ref]">
		<xsl:choose>
			<xsl:when test="parent::xsd:complexType">
				<rdfs:subClassOf rdf:resource="{xo:rdfUri(@ref, namespace::*)}" />
			</xsl:when>
			<xsl:otherwise>
				<owl:Class rdf:about="{xo:rdfUri(@ref, namespace::*)}" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Match attributeGroup references as subClassOf references to the corresponding 
		attributeGroup class -->
	<xsl:template match="xsd:attributeGroup[@ref and ancestor::xsd:complexType]">
		<rdfs:subClassOf rdf:resource="{xo:rdfUri(@ref, namespace::*)}" />
	</xsl:template>

	<!-- Match any definitions inside complexType to generate owl:Restricitons -->
	<xsl:template match="xsd:any">
		<owl:Restriction>
			<owl:onProperty rdf:resource="#any" />
			<owl:minCardinality rdf:datatype="&amp;xsd;nonNegativeInteger">0
			</owl:minCardinality>
		</owl:Restriction>
	</xsl:template>

</xsl:stylesheet>
