<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
	xmlns:fcn="http://www.liujinhang.cn/ifc/xsd2owl-functions.xsl"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fo="http://www.w3.org/1999/XSL/Format">

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
				<xsl:sequence select=" fcn:getLocalAbsoluteURIByName($uriRef) " />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 使用元素的name属性进行 -->
	<xsl:function name="fcn:getLocalAbsoluteURIByName" as="xsd:string">
		<xsl:param name="name" as="xsd:string" />
		<xsl:sequence
			select="
			if
				(contains($targetNamespace,'#'))
			then
				concat($targetNamespace,$name)
			else
				concat($targetNamespace,'#',$name) " />
	</xsl:function>

	<!-- 检查该uriRef是否属于XMLSchema命名空间 -->
	<xsl:function name="fcn:isXsdURI" as="xsd:boolean">
		<xsl:param name="uriRef" as="xsd:string" />
		<!-- 命名空间 -->
		<xsl:param name="namespaces" />
		<xsl:sequence
			select=" 
			contains
			(
				fcn:getAbsoluteURI($uriRef,$namespaces),
				'http://www.w3.org/2001/XMLSchema#'
			)" />
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

	<!--
		下列对象将会转换为DatatypeProperty 
		1，对象的类型属于XML Schema范畴
		2，匿名SimpleType
		3，对象的类型属于本地的SimpleType范畴
	-->
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
				and count
				(
					$localSimpleTypes[
						 fcn:getAbsoluteURI(@name, $namespaces) = fcn:getAbsoluteURI($object/@type, $namespaces)
				]) > 0
			) " />
	</xsl:function>

	<!-- 
		下列对象将会转换为ObjectProperty 
		1，匿名ComplexType
		2，对象的类型属于本地的ComplexType范畴
	-->
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

</xsl:stylesheet>