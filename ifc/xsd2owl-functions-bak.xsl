<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
	xmlns:fcn="http://www.liujinhang.cn/ifc/xsd2owl-functions.xsl"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
	<xsl:function name="fcn:getAbsoluteUri" as="xsd:string">
		<!-- uriRef，形式为 prefix:name -->
		<xsl:param name="uriRef" as="xsd:string" />
		<xsl:choose>
			<xsl:when test="contains($uriRef,':')">
				<xsl:sequence
					select="
					if
						(contains(namespace::*[name()=substring-before($uriRef,':')],'#'))
					then
						concat(namespace::*[name()=substring-before($uriRef,':')],substring-after($uriRef,':'))
					else
						concat(namespace::*[name()=substring-before($uriRef,':')],'#',substring-after($uriRef,':'))" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>getAbsoluteUri : <xsl:value-of select="$uriRef" /></xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- 获取该uriRef的本地绝对URI定义，形式为 targetNamespace#name -->
	<xsl:function name="fcn:getLocalAbsoluteUri" as="xsd:string">
		<xsl:param name="uriRef" as="xsd:string"/>
		<xsl:sequence select="
			if (contains($targetNamespace,'#')) then
				concat($targetNamespace ,$uriRef)
			else
				concat($targetNamespace ,'#',$uriRef)"/>
	</xsl:function>

	<!-- 生成该uriRef的RdfUri，形式为 &prefix;name -->
	<xsl:function name="fcn:generateRdfUri" as="xsd:string">
		<xsl:param name="uriRef" as="xsd:string" />
		<xsl:choose>
			<xsl:when test="contains($uriRef,':')">
				<xsl:sequence
					select="
					concat
					( 
						'&amp;',
						substring-before($uriRef,':'),
						';',
						substring-after($uriRef,':')
					) " />
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>generateRdfUri : <xsl:value-of select="$uriRef" /></xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- 检查该uriRef是否属于XML Schema命名空间 -->
	<xsl:function name="fcn:isXsdRefUri" as="xsd:boolean">
		<xsl:param name="uriRef" as="xsd:string" />
		<xsl:sequence
			select=" 
			contains
			(
				fcn:getAbsoluteUri($uriRef),
				'http://www.w3.org/2001/XMLSchema#'
			)" />
	</xsl:function>
	
	<!-- 检查该uriRef是否属于本地命名空间 -->
	<xsl:function name="fcn:isLocalRdfUri" as="xsd:boolean">
			<xsl:param name="uriRef" as="xsd:string" />
			<xsl:sequence
			select=" 
			contains
			(
				fcn:getAbsoluteUri($uriRef),
				$targetNamespace
			)" />
	</xsl:function>

	<xsl:function name="fcn:isConvertToDatatype" as="xsd:boolean">
		<!-- 检查的对象 -->
		<xsl:param name="object" />
		<!-- 本地SimpleType -->
		<xsl:param name="localSimpleTypes" />
		<!-- 命名空间 -->
		<xsl:param name="namespaces" />
		<xsl:sequence
			select="
			(
				$object/@type 
				and fcn:isXsdRefUri($object/@type)
			) 
			or 
			(
				$object/@type
				and fcn:isLocalRdfUri($object/@type)
				and count(localSimpleTypes[@name=$object/@name]) > 0
			) 
			or
			(
				count($object/xsd:simpleType) > 0 
			)
			" />
	</xsl:function>

</xsl:stylesheet>
