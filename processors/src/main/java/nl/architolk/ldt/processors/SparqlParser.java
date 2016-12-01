/**
 * NAME     SparqlParser.java
 * VERSION  1.10.0
 * DATE     2016-09-27
 *
 * Copyright 2012-2016
 *
 * This file is part of the Linked Data Theatre.
 *
 * The Linked Data Theatre is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Linked Data Theatre is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.
 */
/**
 * DESCRIPTION
 * Orbeon processor to perform a REST call to a http REST API
 *
 */
package nl.architolk.ldt.processors;

import org.orbeon.oxf.pipeline.api.PipelineContext;
import org.orbeon.oxf.processor.ProcessorInputOutputInfo;
import org.orbeon.oxf.processor.SimpleProcessor;
import org.xml.sax.ContentHandler;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.AttributesImpl;
import org.dom4j.Document;
//import org.dom4j.Node;

import org.apache.jena.query.QueryFactory;
import org.apache.jena.query.Query;
import org.apache.jena.sparql.syntax.Element;
import org.apache.jena.sparql.syntax.ElementGroup;
import org.apache.jena.sparql.syntax.ElementNamedGraph;
import org.apache.jena.sparql.syntax.ElementPathBlock;
import org.apache.jena.sparql.core.TriplePath;
import org.apache.jena.graph.Node;
import java.util.List;
import java.util.Iterator;

import org.apache.log4j.Logger;
import org.orbeon.oxf.util.LoggerFactory;

public class SparqlParser extends SimpleProcessor {

	private ContentHandler myContent;
    private static final Logger logger = LoggerFactory.createLogger(HttpClientProcessor.class);

	private static String queryType(int qType) {
		switch (qType) {
			case 444: return "ASK";
			case 222: return "CONSTRUCT";
			case 333: return "DESCRIBE";
			case 111: return "SELECT";
			default: return "UNKNOWN";
		}
	}

	private void parseElement(Element e) throws SAXException {
		if (e instanceof ElementGroup) parseElement((ElementGroup) e);
		if (e instanceof ElementNamedGraph) parseElement((ElementNamedGraph) e);
		if (e instanceof ElementPathBlock) parseElement((ElementPathBlock) e);
	}
	private void parseElement(ElementGroup e) throws SAXException {
		this.myContent.startElement("","group","group",new AttributesImpl());
		List<Element> elems = e.getElements();
		for (int i = 0; i<elems.size(); i++) {
			parseElement(elems.get(i));
		}
		this.myContent.endElement("","group","group");
	}
	private void parseElement(ElementNamedGraph e) throws SAXException {
		Node graph = e.getGraphNameNode();
		AttributesImpl uriAttr = new AttributesImpl();
		uriAttr.addAttribute("", "uri", "uri", "CDATA", graph.toString());
		this.myContent.startElement("","graph","graph",uriAttr);
		parseElement(e.getElement());
		this.myContent.endElement("","graph","graph");
	}
	private void parseElement(ElementPathBlock e) throws SAXException {
		Iterator<TriplePath> triples = e.patternElts();
		while (triples.hasNext()) {
			TriplePath triple = triples.next();
			AttributesImpl tripleAttrs = new AttributesImpl();
			tripleAttrs.addAttribute("", "subject", "subject", "CDATA", triple.getSubject().toString());
			if (triple.isTriple()) {
				tripleAttrs.addAttribute("", "predicate", "predicate", "CDATA", triple.getPredicate().toString());
				tripleAttrs.addAttribute("", "object", "object", "CDATA", triple.getObject().toString());
				this.myContent.startElement("","triple","triple",tripleAttrs);
				this.myContent.endElement("","triple","triple");
			} else {
				this.myContent.startElement("","path","path",tripleAttrs);
				this.myContent.endElement("","path","path");
			}
		}
	}

    public SparqlParser() {
        addInputInfo(new ProcessorInputOutputInfo(INPUT_DATA));
        addOutputInfo(new ProcessorInputOutputInfo(OUTPUT_DATA));
    }

    public void generateData(PipelineContext context, ContentHandler contentHandler) throws SAXException {

		this.myContent = contentHandler;
		Document dataDocument = readInputAsDOM4J(context, INPUT_DATA);
		org.dom4j.Node sparqlNode = dataDocument.selectSingleNode("//sparql");
		Query query = QueryFactory.create(sparqlNode.getText());
		this.myContent.startDocument();
		AttributesImpl typeAttr = new AttributesImpl();
		typeAttr.addAttribute("", "type", "type", "CDATA", queryType(query.getQueryType()));
		this.myContent.startElement("", "query", "query", typeAttr);
		parseElement(query.getQueryPattern());
		this.myContent.endElement("","query","query");
		this.myContent.endDocument();
	}
    
}