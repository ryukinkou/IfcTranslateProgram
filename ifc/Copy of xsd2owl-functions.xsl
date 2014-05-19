<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
	xmlns:fcn="http://www.liujinhang.cn/paper/ifc/xsd2owl-functions.xsl"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fo="http://www.w3.org/1999/XSL/Format">

	<!-- 常量 -->
	<xsl:variable name="standardXsdPrefix" select="'xsd'" />
	<xsl:variable name="standardXsdNamespace" select="'http://www.w3.org/2001/XMLSchema'" />

	<!-- 变量引用 -->
	<xsl:variable name="fcnNamespaces" select="$namespaces" />
	<xsl:variable name="fcnTargetNamespacePrefix" select="$targetNamespacePrefix" />
	<xsl:variable name="fcnLocalXsdPrefix" select="$localXsdPrefix" />
	<xsl:variable name="fcnLocalSimpleTypes" select="$localSimpleTypes" />
	<xsl:variable name="fcnLocalComplexTypes" select="$localComplexTypes" />

	<!-- 获取input的QName -->
	<xsl:function name="fcn:getQName" as="xsd:string">
		<xsl:param name="input" />
		<xsl:choose>
			<xsl:when test="contains($input,':') and not(contains($input,'#'))">
				<xsl:choose>
					<xsl:when
						test="
							$fcnNamespaces[name()=substring-before($input,':')] and 
							$fcnNamespaces[name()=substring-before($input,':')] = $standardXsdNamespace">
						<xsl:sequence
							select="concat($standardXsdPrefix,':',substring-after($input,':'))" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="$input" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when
				test="contains($input,'#') and $fcnNamespaces[.=substring-before($input,'#')]">
				<xsl:sequence
					select="concat($fcnNamespaces[.=substring-before($input,'#')]/name(),':',substring-after($input,'#'))" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="concat($fcnTargetNamespacePrefix,':',$input)" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 获取input的全名 -->
	<xsl:function name="fcn:getFullName" as="xsd:string">
		<xsl:param name="input" />
		<xsl:variable name="QName" select="fcn:getQName($input)" />
		<xsl:choose>
			<xsl:when test="substring-before($QName,':') = $standardXsdPrefix">
				<xsl:sequence
					select="concat($standardXsdNamespace,'#',substring-after($QName,':'))" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence
					select="concat($fcnNamespaces[name()=substring-before($QName,':')],'#',substring-after($QName,':'))" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 获取input的本地名称 -->
	<xsl:function name="fcn:getLocalName" as="xsd:string">
		<xsl:param name="input" />
		<xsl:variable name="QName" select="fcn:getQName($input)" />
		<xsl:sequence select="substring-after($QName,':')" />
	</xsl:function>

	<!-- 获取input的命名空间URI -->
	<xsl:function name="fcn:getNamespaceURI" as="xsd:string">
		<xsl:param name="input" />
		<xsl:variable name="fullName" select="fcn:getFullName($input)" />
		<xsl:sequence select="substring-before($fullName,'#')" />
	</xsl:function>

	<!-- 获取input的命名空间前缀 -->
	<xsl:function name="fcn:getNamespacePrefix" as="xsd:string">
		<xsl:param name="input" />
		<xsl:variable name="QName" select="fcn:getQName($input)" />
		<xsl:sequence select="substring-before($QName,':')" />
	</xsl:function>

	<!-- 在上下文的子节点里面寻找名称为name的元素，存在返回true，不存在返回false -->
	<xsl:function name="fcn:containsElement" as="xsd:boolean">
		<!-- 上下文 -->
		<xsl:param name="context" />
		<!-- 元素/属性的名称 -->
		<xsl:param name="name" as="xsd:string" />
		<xsl:sequence select="count($context/xsd:element[@name=$name])>0" />
	</xsl:function>

	<!-- 在上下文的子节点里面寻找名称为name的属性，存在返回true，不存在返回false -->
	<xsl:function name="fcn:containsAttribute" as="xsd:boolean">
		<!-- 上下文 -->
		<xsl:param name="context" />
		<!-- 元素/属性的名称 -->
		<xsl:param name="name" as="xsd:string" />
		<xsl:sequence select="count($context/xsd:attribute[@name=$name])>0" />
	</xsl:function>

	<!-- 在上下文的子节点里面寻找名称为name的元素/属性，存在返回true，不存在返回false -->
	<xsl:function name="fcn:containsElementOrAttribute" as="xsd:boolean">
		<!-- 上下文 -->
		<xsl:param name="context" />
		<!-- 元素/属性的名称 -->
		<xsl:param name="name" as="xsd:string" />
		<xsl:sequence
			select="fcn:containsElement($context,$name) or fcn:containsAttribute($context,$name)" />
	</xsl:function>

	<!-- 获取该uriRef的绝对URI定义，形式为 namespace#name -->
	<xsl:function name="fcn:getAbsoluteURI" as="xsd:string">
		<!-- uriRef，形式为 prefix:name -->
		<xsl:param name="uriRef" as="xsd:string" />
		<!-- 命名空间 -->
		<xsl:param name="namespaces" />
		<xsl:choose>
			<xsl:when test="contains($uriRef,':')">
				<xsl:sequence
					select="
					if
						(contains($namespaces[name()=substring-before($uriRef,':')],'#'))
					then
						concat($namespaces[name()=substring-before($uriRef,':')],substring-after($uriRef,':'))
					else
						concat($namespaces[name()=substring-before($uriRef,':')],'#',substring-after($uriRef,':'))" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="fcn:getLocalAbsoluteURIByName($uriRef)" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 获得该uriRef的RdfUri -->
	<xsl:function name="fcn:getRdfURI" as="xsd:string">
		<xsl:param name="uriRef" as="xsd:string" />
		<xsl:param name="namespaces" />
		<xsl:choose>
			<xsl:when test="contains($uriRef,':')">
				<xsl:choose>
					<xsl:when test="contains(substring-before($uriRef,':'),$localXsdPrefix)">
						<xsl:sequence
							select="
							concat
							( 
								'&amp;',
								'xsd;',
								substring-after($uriRef,':')
							)" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence
							select="
							concat
							( 
								'&amp;',
								substring-before($uriRef,':'),
								';',
								substring-after($uriRef,':')
							)" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$namespaces[name()='']=''">
						<xsl:sequence select="
							concat('#',$uriRef)" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence
							select="
							if (contains( $namespaces[name()=''], '#')) then
								concat( $namespaces[name()=''] , $uriRef)
							else
								concat( $namespaces[name()=''], '#',$uriRef )" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 检查该uriRef是否属于XMLSchema命名空间 -->
	<xsl:function name="fcn:isXsdURI" as="xsd:boolean">
		<xsl:param name="input" as="xsd:string" />
		<xsl:variable name="QName" select="fcn:getQName($input)" />
		<xsl:sequence select="substring-before($QName,':') = $standardXsdPrefix" />
	</xsl:function>

	<!-- 检查该input是不是一个Datatype定义 -->
	<xsl:function name="fcn:isDatatypeDefinition" as="xsd:boolean">
		<xsl:param name="input" as="xsd:string" />
		<xsl:choose>
			<xsl:when
				test="
				fcn:isXsdURI($input) or
				($fcnLocalSimpleTypes[@name=fcn:getLocalName($input)]/xsd:restriction/@base and
				count($fcnLocalSimpleTypes[@name=fcn:getLocalName($input)]/xsd:restriction/xsd:enumeration) = 0 )">
				<xsl:sequence select="true()" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="false()" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:function name="fcn:isEnumClassDefinition" as="xsd:boolean">
		<xsl:param name="input" as="xsd:string" />
		<xsl:choose>
			<xsl:when
				test="
				$fcnLocalSimpleTypes[@name=fcn:getLocalName($input)]/xsd:restriction/@base and
				count($fcnLocalSimpleTypes[@name=fcn:getLocalName($input)]/xsd:restriction/xsd:enumeration) > 0">
				<xsl:sequence select="true()" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="false()" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:function name="fcn:isClassDefinition" as="xsd:boolean">
		<xsl:param name="input" as="xsd:string" />
		<xsl:choose>
			<xsl:when test="$fcnLocalComplexTypes[@name=fcn:getLocalName($input)]">
				<xsl:sequence select="true()" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="false()" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:function name="fcn:isChildrenAllDatatypeDefinition">
		<xsl:param name="children" />
		<xsl:param name="localSimpleTypes" />
		<xsl:param name="namespaces" />
		<xsl:sequence
			select="
			sum(
				for $child in $children return 
					(
						(
							fcn:isDatatypeDefinition(replace($child/@ref,'-wrapper',''),$localSimpleTypes,$namespaces)
						) cast as xsd:integer
					)
				) = count($children)" />
	</xsl:function>

	<xsl:function name="fcn:isChildrenAllNotDatatypeDefinition">
		<xsl:param name="children" />
		<xsl:param name="localSimpleTypes" />
		<xsl:param name="namespaces" />
		<xsl:sequence
			select="
			sum(
				for $child in $children return 
					(
						(
							not(fcn:isDatatypeDefinition(replace($child/@ref,'-wrapper',''),$localSimpleTypes,$namespaces))
						) cast as xsd:integer
					)
				) = count($children)" />
	</xsl:function>

	<!-- 检查该uriRef是否属于本地命名空间 -->
	<xsl:function name="fcn:isLocalURI" as="xsd:boolean">
		<xsl:param name="uriRef" as="xsd:string" />
		<!-- 命名空间 -->
		<xsl:param name="namespaces" />
		<xsl:sequence
			select=" 
			contains(
				fcn:getAbsoluteURI($uriRef,$namespaces),
				$targetNamespace
			)" />
	</xsl:function>

	<!-- 废弃，下列对象将会转换为DatatypeProperty： 1，对象的类型属于XML Schema范畴 2，匿名SimpleType 
		3，对象的类型是xsd包装类 -->
	<xsl:function name="fcn:isConvertToDatatypeProperty" as="xsd:boolean">
		<xsl:param name="object" />
		<xsl:param name="localSimpleTypes" />
		<xsl:param name="namespaces" />
		<xsl:sequence
			select="
			(
				$object/@type 
				and fcn:isXsdURI($object/@type,$namespaces)
			)
			or
			(
				$object and
				count($object/xsd:simpleType) > 0 
			)
			or 
			( 
				$object/@type
				and fcn:isLocalURI($object/@type,$namespaces)
				and count($localSimpleTypes[substring-after($object/@type,':')]) = 1
				and fcn:isXsdURI($localSimpleTypes[substring-after($object/@type,':')]/xsd:restriction/@base,$namespaces)
			) " />
	</xsl:function>

	<!-- 废弃，下列对象将会转换为ObjectProperty： 1，匿名ComplexType 2，对象的类型属于本地的ComplexType范畴 -->
	<xsl:function name="fcn:isConvertToObjectProperty" as="xsd:boolean">
		<xsl:param name="object" />
		<xsl:param name="localComplexTypes" />
		<xsl:param name="namespaces" />
		<xsl:sequence
			select="
			(
				$object
				and count( $object/xsd:complexType ) > 0
			)
			or
			(
				$object/@type
				and fcn:isLocalURI($object/@type,$namespaces)
				and count
				(
					$localComplexTypes[
						fcn:getAbsoluteURI(@name, $namespaces) = fcn:getAbsoluteURI($object/@type, $namespaces)
				]) > 0
			)
		" />
	</xsl:function>

	<!-- 废弃，element为SimpleType的时候，进行数据类型进行转换，element为ComplexType的时候，其数据类型为RdfURI -->
	<xsl:function name="fcn:getDatatypeDefinition" as="xsd:string">
		<xsl:param name="element" />
		<xsl:param name="localSimpleTypes" />
		<xsl:param name="namespaces" />
		<xsl:choose>
			<xsl:when
				test="fcn:isConvertToDatatypeProperty($element, $localSimpleTypes, $namespaces)">
				<xsl:sequence select="fcn:getXsdURI($element/@type, $namespaces)" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="fcn:getRdfURI($element/@type, $namespaces)" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Datatype的数据预处理 -->
	<xsl:function name="fcn:getXsdURI" as="xsd:string">
		<xsl:param name="uriRef" />
		<xsl:param name="namespaces" />
		<xsl:choose>
			<xsl:when test="fcn:isXsdURI($uriRef, $namespaces)">
				<xsl:choose>
					<xsl:when test="contains($uriRef,'ID')">
						<xsl:sequence select="'&amp;xsd;string'" />
					</xsl:when>
					<xsl:when test="contains($uriRef,'base64Binary')">
						<xsl:sequence select="'&amp;xsd;string'" />
					</xsl:when>
					<xsl:when test="contains($uriRef,'QName')">
						<xsl:sequence select="'&amp;xsd;string'" />
					</xsl:when>
					<xsl:when test="contains($uriRef,'hexBinary')">
						<xsl:sequence select="'&amp;xsd;string'" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="fcn:getRdfURI($uriRef, $namespaces)" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="'&amp;xsd;string'" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 获取Rdf:Resource定义 -->
	<xsl:function name="fcn:getResourceDefinition" as="xsd:string">
		<xsl:param name="uriRef" />
		<xsl:choose>
			<xsl:when test="contains($uriRef,':')">
				<xsl:sequence select="concat('#',substring-after($uriRef,':'))" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="concat('#',$uriRef)" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 检查元素的名称是否存在于被忽略列表中 -->
	<xsl:function name="fcn:isNameListIgnored" as="xsd:boolean">
		<xsl:param name="name" />
		<xsl:sequence
			select="sum(for $ignoreName in $ignoreNameList return (($ignoreName = $name) cast as xsd:integer)) != 0" />
	</xsl:function>

	<!-- 检查元素的名称是否属于被忽略的模式 -->
	<xsl:function name="fcn:isNamePatternIgnored" as="xsd:boolean">
		<xsl:param name="name" />
		<xsl:sequence
			select="sum(for $ignoreNamePattern in $ignoreNamePatternList return (contains($name,$ignoreNamePattern) cast as xsd:integer)) != 0" />
	</xsl:function>

	<!-- 检查元素的名称是否属于需要被忽略 -->
	<xsl:function name="fcn:isNameIgnored" as="xsd:boolean">
		<xsl:param name="name" />
		<xsl:sequence
			select="fcn:isNameListIgnored($name) or fcn:isNamePatternIgnored($name)" />
	</xsl:function>

	<!-- 检查元素是否属于SimpleType -->
	<xsl:function name="fcn:isSimpleType" as="xsd:boolean">
		<xsl:param name="object" />
		<xsl:sequence
			select=" $object/name() = concat($localXsdPrefix,':simpleType') " />
	</xsl:function>

	<!-- 检查元素是否属于ComplexType -->
	<xsl:function name="fcn:isComplexType" as="xsd:boolean">
		<xsl:param name="object" />
		<xsl:sequence
			select=" $object/name() = concat($localXsdPrefix,':complexType') " />
	</xsl:function>

	<!-- 获得元素的绝对URI引用 -->
	<xsl:function name="fcn:getAbsoluteURIRef" as="xsd:string">
		<xsl:param name="name" />
		<xsl:choose>
			<xsl:when test="contains($name,':')">
				<xsl:if
					test="substring-before($name,':') = 'xsd' or substring-before($name,':') = $localXsdPrefix ">
					<xsl:sequence select="concat('&amp;xsd;',substring-after($name,':'))" />
				</xsl:if>
				<xsl:if test="substring-before($name,':') = $targetNamespacePrefix">
					<xsl:sequence
						select="concat($ontologyBase,'#',substring-after($name,':'))" />
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="concat($ontologyBase,'#',$name)" />
			</xsl:otherwise>
		</xsl:choose>

	</xsl:function>

</xsl:stylesheet>
