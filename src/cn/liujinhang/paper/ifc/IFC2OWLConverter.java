package cn.liujinhang.paper.ifc;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.StringWriter;
import java.net.URL;

import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

public class IFC2OWLConverter {

	public static void main(String[] args) throws Throwable {

		System.out.println("read xsl start");
//		InputStreamReader xslFileReader = new InputStreamReader(
//				new URL(
//						"http://rhizomik.net/redefer-services/xsl/xsd2owl.xsl")
//						.openStream());
		
		Source xslSource = new StreamSource(new File("/Users/RYU/Documents/workspace/IfcTranslateProgram/xsl/xsd2owl.xsl"));
		System.out.println("read xsl end");
		
		System.out.println("read xsd start");
		InputStreamReader xsdFileReader = new InputStreamReader(
				new URL(
						"http://www.buildingsmart-tech.org/ifcXML/IFC4/final/ifcXML4.xsd")
						.openStream());

		Source xsdSource = new StreamSource(xsdFileReader);
		System.out.println("read xsd end");
		
		TransformerFactory factory = TransformerFactory.newInstance(
				"net.sf.saxon.TransformerFactoryImpl", null);
		Transformer transformer = factory.newTransformer(xslSource);
		StringWriter writer = new StringWriter();

		System.out.println("transform start");
		transformer.transform(xsdSource, new StreamResult(writer));
		System.out.println("transform end");

		System.out.println("write file start");
		String result = new String(writer.getBuffer());
		result = result.replaceAll("&amp;", "&");

		File file = new File(
				"/Users/RYU/Documents/workspace/IfcTranslateProgram/xsl/ifcXML4.xml");

		BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(file));
		bufferedWriter.write(result);
		bufferedWriter.flush();
		bufferedWriter.close();
		System.out.println("write file end");

	}

}