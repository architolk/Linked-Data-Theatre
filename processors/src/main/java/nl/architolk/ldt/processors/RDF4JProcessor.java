/**
 * NAME     RDF4JProcessor.java
 * VERSION  1.15.0
 * DATE     2017-05-08
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
 * Orbeon processor to use RDF4J to perform upload of RDF
 *
 * It uses statically defined properties:
 * - database: type of database to connect to (possible values: virtuoso or rdf4j)
 * - connect-string: the url to connect to the database
 * - username: the username to use when connecting to the database (mandatory for virtuoso, optional for rdf4j)
 * - password: the password to use when connecting to the database (mandatory for virtuoso, optional for rdf4j)
 * 
 * The data input should contain a list of files to upload, using the structure:
 * <filelist>
 *   <file name="{original name of the file}">{location of the file}</file>
 * </filelist>
 *
 * The config input should contain the following elements:
 * <action>{part|replace|insert|update|create}</action>: The action to perform (defaults to 'create')
 * <cgraph>{uri}</cgraph>: The container graph that receives the data
 * <pgraph>{uri}</pgraph>: The parent graph to receive version information, if not equal to the container graph
 * <tgraph>{uri}</tgraph>: Optional, some target graph that (also) receives the data
 * <postquery>{sparql}</postquery>: Optional, some sparql query that should be performed after uploading the data
 *
 * The output will be an XML node containing the term "succes" or an error message
 *
 * Actions are defined as:
 * - create: remove all previous content and insert triples into container
 * - insert: insert triples into container without deleting previous content
 * - replace: remove all previous content and insert triple into container and into target graph
 * - update: remove all properties from subjects of target graph that are present in new container and insert new triples into target graph
 * - part: remove old triples from target graph, clear container, insert triples into container and new triples from container into target graph
 */
package nl.architolk.ldt.processors;

import org.orbeon.oxf.pipeline.api.PipelineContext;
import org.orbeon.oxf.processor.ProcessorInputOutputInfo;
import org.orbeon.oxf.processor.SimpleProcessor;
import org.xml.sax.ContentHandler;
import org.xml.sax.SAXException;

import org.xml.sax.helpers.AttributesImpl;
import org.dom4j.Document;
import org.dom4j.Node;
import java.util.Iterator;
import java.util.List;

import org.apache.log4j.Logger;
import org.orbeon.oxf.util.LoggerFactory;

import virtuoso.rdf4j.driver.VirtuosoRepository;
import org.eclipse.rdf4j.repository.http.HTTPRepository;
import org.eclipse.rdf4j.repository.Repository;
import org.eclipse.rdf4j.repository.RepositoryConnection;
import org.eclipse.rdf4j.model.IRI;
import org.eclipse.rdf4j.rio.RDFFormat;
import org.eclipse.rdf4j.rio.Rio;
import java.io.File;

public class RDF4JProcessor extends SimpleProcessor {

    private static final Logger logger = LoggerFactory.createLogger(RDF4JProcessor.class);

	private Repository db;
	private RepositoryConnection conn;

    public RDF4JProcessor() {
        addInputInfo(new ProcessorInputOutputInfo(INPUT_DATA));
		addInputInfo(new ProcessorInputOutputInfo(INPUT_CONFIG));
        addOutputInfo(new ProcessorInputOutputInfo(OUTPUT_DATA));
    }

    public void generateData(PipelineContext context, ContentHandler contentHandler) throws SAXException {

		Document configDocument = readInputAsDOM4J(context, INPUT_CONFIG);
		Node configNode = configDocument.selectSingleNode("//config");
		
		contentHandler.startDocument();
		contentHandler.startElement("", "response", "response", new AttributesImpl());

		String action = configNode.valueOf("action"); // The action to perform
		String cgraph = configNode.valueOf("cgraph"); // Container graph, the main graph
		String tgraph = configNode.valueOf("tgraph"); // The target graph
		String pgraph = configNode.valueOf("pgraph"); // The parent graph, for version information
		String postQuery = configNode.valueOf("postquery"); // Some post query, optional
		
		db = RDF4JProperties.createRepository();
		if (db==null) {
			String msg = "Unknown database: ";
			contentHandler.characters(msg.toCharArray(),0,msg.length());
		} else {
			conn = db.getConnection();

			// Clear target graph, partially (all triples in original container) or completely
			if (action.equals("replace")) {
				String msg = "Target graph cleared";
				try {
					IRI tgraphResource = db.getValueFactory().createIRI(tgraph);
					conn.clear(tgraphResource);
				}
				catch (Exception e) {
					// In case of an error, put the errormessage in the result, but don't throw the exception
					msg = e.getMessage();
				}
				contentHandler.startElement("", "scene", "scene", new AttributesImpl());
				contentHandler.characters(msg.toCharArray(),0,msg.length());
				contentHandler.endElement("", "scene", "scene");
			} else if (action.equals("part")) {
				String msg ="Target graph partially cleared";
				try {
					conn.prepareUpdate("delete from <" + tgraph + "> {?s?p?o} where { graph <" + cgraph + "> {?s?p?o}}").execute();
				}
				catch (Exception e) {
					// In case of an error, put the errormessage in the result, but don't throw the exception
					msg = e.getMessage();
				}
				contentHandler.startElement("", "scene", "scene", new AttributesImpl());
				contentHandler.characters(msg.toCharArray(),0,msg.length());
				contentHandler.endElement("", "scene", "scene");
			}

			// Clear container, except when action = insert
			if (!action.equals("insert")) {
				String msg = "Container cleared";
				try {
					IRI cgraphResource = db.getValueFactory().createIRI(cgraph);
					conn.clear(cgraphResource);
				}
				catch (Exception e) {
					// In case of an error, put the errormessage in the result, but don't throw the exception
					msg = e.getMessage();
				}
				contentHandler.startElement("", "scene", "scene", new AttributesImpl());
				contentHandler.characters(msg.toCharArray(),0,msg.length());
				contentHandler.endElement("", "scene", "scene");
			}

			// Insert documents into container graph
			Document dataDocument = readInputAsDOM4J(context, INPUT_DATA);
			List filelist = dataDocument.selectNodes("//filelist//file");
			Iterator<?> elit = filelist.listIterator();
			while (elit.hasNext()) {
				Node child = (Node) elit.next();
				String msg = "file uploaded";
				try {
					uploadFile(child.valueOf("@name"),child.getText(),cgraph);
				}
				catch (Exception e) {
					// In case of an error, put the errormessage in the result, but don't throw the exception
					msg = e.getMessage();
				}
				contentHandler.startElement("", "scene", "scene", new AttributesImpl());
				contentHandler.characters(msg.toCharArray(),0,msg.length());
				contentHandler.endElement("", "scene", "scene");
			}
			
			// Remove existing properties in case of action = update
			if (action.equals("update")) {
				String msg ="Target graph cleared for update";
				try {
					conn.prepareUpdate("delete from <" + tgraph + "> {?s?x?y} where { graph <" + cgraph + "> {?s?p?o}}").execute();
					// Remove orphant blank nodes (to third degree, beter option could be to count the number of deleted nodes and repeat when not equal to zero)
					conn.prepareUpdate("delete from <" + tgraph + "> {?bs?bp?bo} where { graph <" + tgraph + "> {?bs?bp?bo FILTER(isblank(?bs)) FILTER NOT EXISTS {?s?p?bs}}}").execute();
					conn.prepareUpdate("delete from <" + tgraph + "> {?bs?bp?bo} where { graph <" + tgraph + "> {?bs?bp?bo FILTER(isblank(?bs)) FILTER NOT EXISTS {?s?p?bs}}}").execute();
					conn.prepareUpdate("delete from <" + tgraph + "> {?bs?bp?bo} where { graph <" + tgraph + "> {?bs?bp?bo FILTER(isblank(?bs)) FILTER NOT EXISTS {?s?p?bs}}}").execute();
				}
				catch (Exception e) {
					// In case of an error, put the errormessage in the result, but don't throw the exception
					msg = e.getMessage();
				}
				contentHandler.startElement("", "scene", "scene", new AttributesImpl());
				contentHandler.characters(msg.toCharArray(),0,msg.length());
				contentHandler.endElement("", "scene", "scene");
			}
			
			// Populate target graph with content of the container-graph
			if (action.equals("part") || action.equals("replace") || action.equals("update")) {
				String msg ="Target graph populated";
				try {
					conn.prepareUpdate("insert into <" + tgraph + "> {?s?p?o} where { graph <" + cgraph + "> {?s?p?o}}").execute();
				}
				catch (Exception e) {
					// In case of an error, put the errormessage in the result, but don't throw the exception
					msg = e.getMessage();
				}
				contentHandler.startElement("", "scene", "scene", new AttributesImpl());
				contentHandler.characters(msg.toCharArray(),0,msg.length());
				contentHandler.endElement("", "scene", "scene");
			}
			
			// Insert version-info into parent graph, if applicable
			if (!(cgraph.equals(pgraph) || pgraph.isEmpty())) {
				String msg ="Version metadata inserted into parent graph";
				try {
					conn.prepareUpdate("insert into <" + pgraph + "> {<" + pgraph + "> <http://purl.org/dc/terms/hasVersion> <" + cgraph + ">}").execute();
				}
				catch (Exception e) {
					// In case of an error, put the errormessage in the result, but don't throw the exception
					msg = e.getMessage();
				}
				contentHandler.startElement("", "scene", "scene", new AttributesImpl());
				contentHandler.characters(msg.toCharArray(),0,msg.length());
				contentHandler.endElement("", "scene", "scene");
			}
			
			// Execute post query
			if (!postQuery.isEmpty()) {
				String msg ="Post query executed";
				try {
					conn.prepareUpdate(postQuery).execute();
				}
				catch (Exception e) {
					// In case of an error, put the errormessage in the result, but don't throw the exception
					msg = e.getMessage();
				}
				contentHandler.startElement("", "scene", "scene", new AttributesImpl());
				contentHandler.characters(msg.toCharArray(),0,msg.length());
				contentHandler.endElement("", "scene", "scene");
			}
			
		}
		
		contentHandler.endElement("", "response", "response");
		contentHandler.endDocument();
	}

	public void uploadFile(String filename, String filePath, String cgraph) throws Exception {
	/*	Possible exceptions are:
		- IOException: file not found, or error reading file
		- UnsupportedRDFormatException: format not supported by library (possibly because the jar is missing)
		- RDFParseException: file possible not correct
		- RepositoryException: for example, unable to write to the repository
	*/
	
		IRI context = db.getValueFactory().createIRI(cgraph);
		//Infer parser from filename, or else assume RDF-XML
		conn.add(new File(filePath),"",Rio.getParserFormatForFileName(filename).orElse(RDFFormat.RDFXML),context);
		
	}
    
}