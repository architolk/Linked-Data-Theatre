/**
 * NAME     SparqlProcessor.java
 * VERSION  1.15.0
 * DATE     2017-01-27
 *
 * Copyright 2012-2017
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
import org.orbeon.oxf.common.OXFException;
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

import org.orbeon.oxf.xml.ForwardingXMLReceiver;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdf.model.RDFNode;
import org.apache.jena.rdfxml.xmlinput.SAX2Model;

import org.apache.jena.query.QueryExecutionFactory;
import org.apache.jena.query.QueryExecution;
import org.apache.jena.query.ResultSet;
import org.apache.jena.query.QuerySolution;

import org.apache.log4j.Logger;
import org.orbeon.oxf.util.LoggerFactory;

public class SparqlProcessor extends SimpleProcessor {

    private static final Logger logger = LoggerFactory.createLogger(HttpClientProcessor.class);

    public SparqlProcessor() {
        addInputInfo(new ProcessorInputOutputInfo(INPUT_DATA));
		addInputInfo(new ProcessorInputOutputInfo(INPUT_CONFIG));
        addOutputInfo(new ProcessorInputOutputInfo(OUTPUT_DATA));
    }

    public void generateData(PipelineContext context, ContentHandler contentHandler) throws SAXException {

		//Fetch the sparql query
		Document sparqlDocument = readInputAsDOM4J(context, INPUT_CONFIG);
		org.dom4j.Node sparqlNode = sparqlDocument.selectSingleNode("//sparql");
		Query query = QueryFactory.create(sparqlNode.getText());
		
		//Fetch the data, and put it in a in-memory Jena triplestore
		Model m = ModelFactory.createDefaultModel();
		SAX2Model handler = SAX2Model.create("http://localhost/", m);
		readInputAsSAX(context, INPUT_DATA, new ForwardingXMLReceiver(handler));
    	logger.info("Model size " + Long.toString(m.size()));
		
		QueryExecution qExec = QueryExecutionFactory.create(query, m);
		try {
			ResultSet results = qExec.execSelect();
			//This might be done better, but for now it is OK
			try {
				contentHandler.startDocument();
				contentHandler.startPrefixMapping("sparql","http://www.w3.org/2005/sparql-results#");
				contentHandler.startElement("http://www.w3.org/2005/sparql-results#", "sparql", "sparql:sparql", new AttributesImpl());
				contentHandler.startElement("http://www.w3.org/2005/sparql-results#", "head", "sparql:head", new AttributesImpl());
				List<String> vars = results.getResultVars();
				for (int i = 0; i<vars.size(); i++) {
					vars.get(i);
					AttributesImpl varAttr = new AttributesImpl();
					varAttr.addAttribute("", "name", "name", "CDATA", vars.get(i));
					contentHandler.startElement("http://www.w3.org/2005/sparql-results#", "variable", "sparql:variable", varAttr);
					contentHandler.endElement("http://www.w3.org/2005/sparql-results#", "variable", "sparql:variable");
				}
				contentHandler.endElement("http://www.w3.org/2005/sparql-results#", "head", "sparql:head");
				contentHandler.startElement("http://www.w3.org/2005/sparql-results#", "results", "sparql:results", new AttributesImpl());
				while (results.hasNext()) {
					QuerySolution row = results.nextSolution();
					contentHandler.startElement("http://www.w3.org/2005/sparql-results#", "result", "sparql:result", new AttributesImpl());
					Iterator<String> varnames = row.varNames();
					while (varnames.hasNext()) {
						String varname = varnames.next();
						RDFNode valueNode = row.get(varname);
						AttributesImpl varAttr = new AttributesImpl();
						varAttr.addAttribute("", "name", "name", "CDATA", varname);
						contentHandler.startElement("http://www.w3.org/2005/sparql-results#", "binding", "sparql:binding", varAttr);
						if (valueNode.isLiteral()) {
							String value = valueNode.toString();
							contentHandler.startElement("http://www.w3.org/2005/sparql-results#", "literal", "sparql:literal", new AttributesImpl());
							contentHandler.characters(value.toCharArray(),0,value.length());
							contentHandler.endElement("http://www.w3.org/2005/sparql-results#", "literal", "sparql:literal");
						}
						if (valueNode.isAnon()) {
							String value = "urn:bnode:" + valueNode.toString();
							contentHandler.startElement("http://www.w3.org/2005/sparql-results#", "uri", "sparql:uri", new AttributesImpl());
							contentHandler.characters(value.toCharArray(),0,value.length());
							contentHandler.endElement("http://www.w3.org/2005/sparql-results#", "uri", "sparql:uri");
						}
						if (valueNode.isURIResource()) {
							String value = valueNode.toString();
							contentHandler.startElement("http://www.w3.org/2005/sparql-results#", "uri", "sparql:uri", new AttributesImpl());
							contentHandler.characters(value.toCharArray(),0,value.length());
							contentHandler.endElement("http://www.w3.org/2005/sparql-results#", "uri", "sparql:uri");
						}
						contentHandler.endElement("http://www.w3.org/2005/sparql-results#", "binding", "sparql:binding");
					}
					contentHandler.endElement("http://www.w3.org/2005/sparql-results#", "result", "sparql:result");
				}
				contentHandler.endElement("http://www.w3.org/2005/sparql-results#", "results", "sparql:results");
				contentHandler.endElement("http://www.w3.org/2005/sparql-results#", "sparql", "sparql:sparql");
				contentHandler.endPrefixMapping("sparql");
				contentHandler.endDocument();
			} catch (Exception e) {
				throw new OXFException(e);
			}
		}
		finally { 
			qExec.close(); 
		}
	}
    
}