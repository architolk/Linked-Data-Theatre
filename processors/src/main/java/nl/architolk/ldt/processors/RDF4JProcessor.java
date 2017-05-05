/**
 * NAME     SparqlProcessor.java
 * VERSION  1.15.0
 * DATE     2017-01-30
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
 * <action>{part|replace|insert|update}</action>: The action to perform
 * <cgraph>{uri}</cgraph>: The container graph that receives the data
 * <pgraph>{uri}</pgraph>: The parent graph to receive version information, if not equal to the container graph
 * <tgraph>{uri}</tgraph>: Optional, some target graph that (also) receives the data
 * <postquery>{sparql}</postquery>: Optional, some sparql query that should be performed after uploading the data
 *
 * The output will be an XML node containing the term "succes" or an error message
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
import java.io.File;

public class RDF4JProcessor extends SimpleProcessor {

    private static final Logger logger = LoggerFactory.createLogger(RDF4JProcessor.class);

	//Voorlopig even als constanten
	private static final String database = "virtuoso";
	private static final String connectString = "jdbc:virtuoso://localhost:1111/log_enable=0";
	private static final String username = "dba";
	private static final String password = "dba";

	private static Repository db;
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

		if (database.equals("virtuoso")) {
			db = new VirtuosoRepository(connectString, username, password);
		} else if (database.equals("rdf4j")) {
			db = new HTTPRepository(connectString);
		} else {
			String msg = "Unknown database: ";
			msg.concat(database);
			contentHandler.characters(msg.toCharArray(),0,msg.length());
		}
		if (db!=null) {
			conn = db.getConnection();
			
			Document dataDocument = readInputAsDOM4J(context, INPUT_DATA);
			List filelist = dataDocument.selectNodes("//filelist//file");
			Iterator<?> elit = filelist.listIterator();
			while (elit.hasNext()) {
				Node child = (Node) elit.next();
				contentHandler.startElement("", "filex", "filex", new AttributesImpl());
				String value = child.valueOf("@name");
				uploadFile(RDFFormat.RDFXML,child.getText(),configNode.valueOf("cgraph"));
				contentHandler.characters(value.toCharArray(),0,value.length());
				contentHandler.endElement("", "filex", "filex");
			}
		}
		
		contentHandler.endElement("", "response", "response");
		contentHandler.endDocument();
	}

	public void uploadFile(RDFFormat dataFormat, String filePath, String cgraph) {

		try {
			IRI context = db.getValueFactory().createIRI(cgraph);
			conn.add(new File(filePath),"",dataFormat,context);
		}
		catch (Exception e) {
			//Something went wrong
		}
		
	}
    
}