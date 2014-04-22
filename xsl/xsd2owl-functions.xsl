<?xml version="1.0" encoding="UTF-8"?>
<!-- 
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike License. 
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/1.0/ 
or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
License: http://rhizomik.upf.edu/redefer/xsd2owl.xsl.rdf
-->
<xsl:stylesheet 
	version="2.0" 
	xmlns:xo="http://rhizomik.net/redefer/xsl/xsd2owl-functions.xsl" 
	xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:fo="http://www.w3.org/1999/XSL/Format" >

	<!-- 
		Generates URI reference from element namespace and local name using entity
		获得该元素的rdf定义，不包含namespace，形式为 &prefix;name
	-->
	<xsl:function name="xo:rdfUri" as="xsd:string">
		<xsl:param name="uriRef" as="xsd:string"/>
		<xsl:param name="namespaces"/>
		<xsl:choose>
			<xsl:when test="contains($uriRef,':')">
				<!--
					XQUERY: 
					( 
						'&amp;', /* 符号& */
						substring-before($uriRef,':'),
						';',
						substring-after($uriRef,':')
					) /* 最后的样式为 '&prefix;name' */
				 -->
				<xsl:sequence select="
					concat
					( 
						'&amp;',
						substring-before($uriRef,':'),
						';',
						substring-after($uriRef,':')
					)
					"/>
			</xsl:when>
			<xsl:otherwise>
			<!-- When there isn't namespace declaration use dafault namespace if it exists or leave empty -->
				<xsl:choose>
					<!-- 如果默认的命名空间都是空的，那就直接在uriRef前面价格#了事 -->
					<xsl:when test="$namespaces[name()='']=''">
						<xsl:sequence select="
							concat('#',$uriRef)"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- 否则就给uriRef加上name()为空的命名空间，并且有自动添加'#'号的逻辑 -->
						<xsl:sequence select="
							if (contains( $namespaces[name()=''], '#')) then
								concat( $namespaces[name()=''] , $uriRef)
							else
								concat( $namespaces[name()=''], '#',$uriRef )"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- 
		Generate absolute URI, i.e. without namespace alias
		或者该元素的绝对URI，格式为 namespace#name，具备自动补齐'#'符号的功能
	-->
	<xsl:function name="xo:absoluteUri" as="xsd:string">
		<xsl:param name="uriRef" as="xsd:string"/>
		<xsl:param name="namespaces"/>
		<xsl:choose>
			<!-- 检查uriRef是否有':'符号 -->
			<xsl:when test="contains($uriRef,':')">
				<!-- 检查uriRef指向的命名空间中是否有'#'符号，没有的情况下需要手动添加该符号，构成 namespace#name 的形式 -->
				<xsl:sequence select="
					if
						(contains($namespaces[name()=substring-before($uriRef,':')],'#'))
					then
						concat($namespaces[name()=substring-before($uriRef,':')],substring-after($uriRef,':'))
					else
						concat($namespaces[name()=substring-before($uriRef,':')],'#',substring-after($uriRef,':'))" 
				/>
			</xsl:when>
			<!-- 如果uriRef中不包含':'符号 -->
			<xsl:otherwise>
			<!-- When there isn't namespace declaration use dafault namespace if it exists or leave empty -->
			<!-- 一般来说不存在没有':'符号的uriRef，也不会存在全部置空的namespace，但是还是准备了处理逻辑 -->
				<xsl:choose>
					<!-- 根本不会存在这种情况了 -->
					<xsl:when test="$namespaces[name()='']=''">
						<xsl:sequence select="
							concat('#',$uriRef)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="
							if 
								(contains($namespaces[name()=''],'#'))
							then
								concat($namespaces[name()=''],$uriRef)
							else
								concat($namespaces[name()=''],'#',$uriRef)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- 
		Generate absolute URI for locally declared entities using targetNamespace 
		在假设uriRef是属于本地定义的元素的前提下，获取其绝对URI，形式为 namespace#uriRef
	-->		
	<xsl:function name="xo:localAbsoluteUri" as="xsd:string">
		<xsl:param name="uriRef" as="xsd:string"/>
		<xsl:param name="namespaces"/><!-- 不需要namespaces参数 -->
		<xsl:sequence select="
			if (contains($targetNamespace,'#')) then
				concat($targetNamespace ,$uriRef)
			else
				concat($targetNamespace ,'#',$uriRef)"/>
	</xsl:function>
	
	<!-- 
		Test if the provided URI makes reference to the XMLSchema namespace 
		检测uriRef是不是指向XMLSchema的命名空间（即该uriRef是否是XSD的别名） 
	-->
	<xsl:function name="xo:isXsdUri" as="xsd:boolean">
		<xsl:param name="uriRef" as="xsd:string"/>
		<xsl:param name="namespaces"/>
		<xsl:sequence select=" 
			contains
			(
				xo:absoluteUri($uriRef, $namespaces),
				'http://www.w3.org/2001/XMLSchema#'
			)"
		/>
	</xsl:function>
	

	
	<xsl:function name="xo:allDatatype" as="xsd:boolean">
		<xsl:param name="elements"/>
		<xsl:param name="localComplexTypes"/>
		<xsl:param name="namespaces"/>
		<!-- 
		XQUERY:
			sum
				(
				for $e in $elements 
					return
						(
							xo:isObjectype($e, $localComplexTypes, $namespaces) /* 依次检查element是否符合被转换为object type */
					   	) cast as xsd:integer
			   ) = 0 /* 需要所有的元素没有一个属于object type */
		 -->
		<xsl:sequence select="
			sum
				(
					for $e in $elements 
					return
						(
							xo:isObjectype($e, $localComplexTypes, $namespaces)
					   	) cast as xsd:integer
			   ) = 0 
		"/>
	</xsl:function>
	
	<!-- 
		Determine if XSD element or attribute corresponds to a object type property:
		1.- there is a local complexType named like the defined type
		2.- the element defines an implicit complexType
		哪些元素适合被转换为Object type：
		1，自身就是ComplexType元素
		2，自身是潜在的ComplexType元素
	 -->
	<xsl:function name="xo:isObjectype" as="xsd:boolean">
		<xsl:param name="element"/>
		<xsl:param name="localComplexTypes"/>
		<xsl:param name="namespaces"/>
		<!--
			XQUERY:
			(
			$element/@type /* 该元素的type属性不为空 */
				and 
				count
				(
					$localComplexTypes[
						xo:absoluteUri($element/@type, $namespaces) = xo:localAbsoluteUri(@name, $namespaces)
					] 
				) > 0 /* 最少拥有一个本地定义 */ 
			) 
			or 
			count( $element/xsd:complexType ) > 0 /* 内部含有ComplexType */
		 -->
		<xsl:sequence select="
			(
			$element/@type 
				and 
				count
				(
					$localComplexTypes[
						xo:absoluteUri($element/@type, $namespaces) = xo:localAbsoluteUri(@name, $namespaces)
					] 
				) > 0 
			) 
			or 
			count( $element/xsd:complexType ) > 0
		"/>
	</xsl:function>
	
	<xsl:function name="xo:allObjectype" as="xsd:boolean">
		<xsl:param name="elements"/>
		<xsl:param name="localSimpleTypes"/>
		<xsl:param name="namespaces"/>
		<!--
			XQUERY:
			sum(
				for $e in $elements 
				return 
					(
						xo:isDatatype($e, $localSimpleTypes, $namespaces) /* 挨个检查element是否属于被转换为Datatype的类型 */
					) cast as xsd:integer
				) = 0 /* 所有的元素都不属于被转换为Datatype的类型 */
		 -->
		<xsl:sequence select="
			sum(
				for $e in $elements 
				return 
					(
						xo:isDatatype($e, $localSimpleTypes, $namespaces)
					) cast as xsd:integer
				) = 0
		"/>
	</xsl:function>
	
	<!-- For element and attributes with values defined using a type reference -->
	<!-- If value simpleType, map it to a OWL supported datatype -->
	<!-- If value complexType, generate range uri from type reference -->
	<!-- TODO: manage simpleTypes in a separate file an generate corresponding references here -->
	<xsl:function name="xo:rangeUri" as="xsd:string">
		<xsl:param name="element"/>
		<xsl:param name="localSimpleTypes"/>
		<xsl:param name="namespaces"/>
		<xsl:choose>
			<xsl:when test="xo:isDatatype($element, $localSimpleTypes, $namespaces)">
				<xsl:sequence select="xo:supportedDatatype($element/@type, $namespaces)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="xo:rdfUri($element/@type, $namespaces)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- For element and attributes with values defined completely inside -->
	<!-- If value simpleType, map it to an xsd:string because it is new and thus unsupported by OWL -->
	<!-- If value complexType, do nothing because the corresponding anonymous class is generated by 
		the complexType template -->
	<!-- TODO: manage simpleTypes in a separate file an generate corresponding references here -->
	<xsl:function name="xo:newRangeUri">
		<xsl:param name="element"/>
		<xsl:param name="baseEntity" as="xsd:string"/>
		<xsl:if test="count($element/xsd:simpleType)>0">
			<xsl:sequence select="'&amp;xsd;string'"/>
		</xsl:if>
	</xsl:function>
	
	<!-- If datatype in the XSD namespace use it directly or map it if not OWL supported -->
	<!-- For datatypes outside XSD, map them to xsd:string -->
	<xsl:function name="xo:supportedDatatype" as="xsd:string">
		<xsl:param name="datatype"/>
		<xsl:param name="namespaces"/>
		<xsl:choose>
			<xsl:when test="xo:isXsdUri($datatype, $namespaces)">
				<xsl:choose>
					<xsl:when test="contains($datatype,'ID')">
						<xsl:sequence select="'&amp;xsd;string'"/>
					</xsl:when>
					<xsl:when test="contains($datatype,'base64Binary')">
						<xsl:sequence select="'&amp;xsd;string'"/>
					</xsl:when>
					<xsl:when test="contains($datatype,'QName')">
						<xsl:sequence select="'&amp;xsd;string'"/>
					</xsl:when>
					<xsl:when test="contains($datatype,'hexBinary')">
						<xsl:sequence select="'&amp;xsd;string'"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="xo:rdfUri($datatype, $namespaces)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="'&amp;xsd;string'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- anyURI duration dateTime float -->

    <!-- 
    XPATH:
    count( 
    $elements/xsd:element[@name=$name] | //获取 参数elements 节点集合中 name值 与 参数name 相等的element节点
    $elements/xsd:attribute[@name=$name] //获取 参数elements 节点集合中 name值 与 参数name 相等的attribute节点
    ) > 0 //如果有，则返回true()，如果没有，则返回false()
     -->
	<xsl:function name="xo:existsElemOrAtt" as="xsd:boolean">
		<xsl:param name="elements"/>
		<xsl:param name="name" as="xsd:string"/>
		<xsl:sequence select="count($elements/xsd:element[@name=$name] | $elements/xsd:attribute[@name=$name])>0"/>
	</xsl:function>
	
	<xsl:function name="xo:existsElem" as="xsd:boolean">
		<xsl:param name="elements"/>
		<xsl:param name="name" as="xsd:string"/>
		<xsl:sequence select="count($elements[@name=$name])>0"/>
	</xsl:function>
	
</xsl:stylesheet>
