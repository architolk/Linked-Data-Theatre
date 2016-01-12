/**
 * NAME     RDB2RDFProcessor.java
 * VERSION  1.5.0
 * DATE     2016-01-03
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
 * Orbeon processor to convert RDB dataset to RDF file
 * The serializer used libraries from MorphRDB
 *
 * Usage:
 * - The config input contains the configuration, including the file that is used and the file that is created
 * - There is no data input
 * - The data output contains an errorMessage in case of an error, otherwise a successMessage.
 *
 */
package nl.architolk.ldt.processors;

import org.orbeon.oxf.pipeline.api.PipelineContext;
import org.orbeon.oxf.processor.ProcessorInputOutputInfo;
import org.orbeon.oxf.processor.SimpleProcessor;
import org.orbeon.oxf.processor.CacheableInputReader;
import org.orbeon.oxf.processor.ProcessorInput;
import org.orbeon.oxf.xml.XPathUtils;
import org.xml.sax.ContentHandler;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.AttributesImpl;
import org.dom4j.Document;
import java.io.IOException;

import es.upm.fi.dia.oeg.morph.r2rml.rdb.engine.MorphRDBRunner;
import es.upm.fi.dia.oeg.morph.r2rml.rdb.engine.MorphRDBRunnerFactory;
import es.upm.fi.dia.oeg.morph.base.MorphProperties;
import es.upm.fi.dia.oeg.morph.base.engine.MorphBaseRunner;

public class RDB2RDFProcessor extends SimpleProcessor {

	//In the orbeon processors, a xsd is used, but haven't figured out how this works, so commented-out for now.
	//public static final String RDB2RDF_PROCESSOR_CONFIG_NAMESPACE_URI = "http://orbeon.org/oxf/xml/rdb2rdf-processor-config";
	public static final String MSG_SUCCESS = "Converted";

    public RDB2RDFProcessor() {
        //addInputInfo(new ProcessorInputOutputInfo(INPUT_CONFIG, RDB2RDF_PROCESSOR_CONFIG_NAMESPACE_URI));
        addInputInfo(new ProcessorInputOutputInfo(INPUT_CONFIG));
        addOutputInfo(new ProcessorInputOutputInfo(OUTPUT_DATA));
    }

    private static class Config {

        private String mappingDocument;
		private String outputFile;
		private String database;
		private String driver;
		private String url;
		private String user;
		private String password;
		private String type;
		private String uriEncode;
		private String uriTransform;

        public Config(Document document) {
            // mappingDocument (mappingdocument.file.path)
            mappingDocument = XPathUtils.selectStringValueNormalize(document, "/config/mappingDocument");
			// outputFile (output.file.path)
			outputFile = XPathUtils.selectStringValueNormalize(document, "/config/outputFile");
			// database (database[0].name)
			database = XPathUtils.selectStringValueNormalize(document, "/config/database");
			// driver (database[0].driver)
			driver = XPathUtils.selectStringValueNormalize(document, "/config/driver");
			// url (database[0].url)
			url = XPathUtils.selectStringValueNormalize(document, "/config/url");
			// user (database[0].user)
			user = XPathUtils.selectStringValueNormalize(document, "/config/user");
			// password (database[0].pwd)
			password = XPathUtils.selectStringValueNormalize(document, "/config/password");
			// type (database[0].type)
			type = XPathUtils.selectStringValueNormalize(document, "/config/type");
			// uriEncode (uri.encode)
			uriEncode = XPathUtils.selectStringValueNormalize(document, "/config/uriEncode");
			// uriTransform (uri.transform)
			uriTransform = XPathUtils.selectStringValueNormalize(document, "/config/uriTransform");
        }
		
		public String getMappingDocument() {
			return mappingDocument;
		}
		public String getOutputFile() {
			return outputFile;
		}
		public String getDatabase() {
			return database;
		}
		public String getDriver() {
			return driver;
		}
		public String getUrl() {
			return url;
		}
		public String getUser() {
			return user;
		}
		public String getPassword() {
			return password;
		}
		public String getType() {
			return type;
		}
		public String getUriEncode() {
			return uriEncode;
		}
		public String getUriTransform() {
			return uriTransform;
		}
	}
		
    public void generateData(PipelineContext context, ContentHandler contentHandler) throws SAXException, IOException {

		// Read config
		final Config config = readCacheInputAsObject(context, getInputByName(INPUT_CONFIG), new CacheableInputReader<Config>() {
			public Config read(PipelineContext context, ProcessorInput input) {
				return new Config(readInputAsDOM4J(context, input));
			}
		});

		final MorphProperties properties = new MorphProperties();

		properties.setProperty("mappingdocument.file.path",config.getMappingDocument());
		properties.setProperty("output.file.path",config.getOutputFile());
		properties.setProperty("output.rdflanguage","TURTLE");
		properties.setProperty("no_of_database","1");
		properties.setProperty("database.name[0]",config.getDatabase());
		properties.setProperty("database.driver[0]",config.getDriver());
		properties.setProperty("database.url[0]",config.getUrl());
		properties.setProperty("database.user[0]",config.getUser());
		properties.setProperty("database.pwd[0]",config.getPassword());
		properties.setProperty("database.type[0]",config.getType());
		properties.setProperty("uri.encode",config.getUriEncode());
		properties.setProperty("uri.transform",config.getUriTransform());

		// Properties uit key-value tabel omzetten naar Morph property-structuur
		properties.readConfigurationFile();
		
		// Runner aanmaken op basis van properties en uitvoeren

		String resultMessage = MSG_SUCCESS;
		try {
			MorphRDBRunnerFactory runnerFactory = new MorphRDBRunnerFactory();
			MorphBaseRunner runner = runnerFactory.createRunner(properties);
			try {
				runner.run();
			}
			finally {
				// Closing the outputFile (bug in MorphRDB??)
				runner.outputStream().close();
			}
		}
		catch (Exception e) {
			resultMessage = e.getMessage();
		}
		
		// Create output (returns the mapping document and the output file)
		String mappingDocument = config.getMappingDocument();
		String outputFile = config.getOutputFile();
        contentHandler.startDocument();
		contentHandler.startElement("", "result", "result", new AttributesImpl());
		
        contentHandler.startElement("", "mappingDocument", "mappingDocument", new AttributesImpl());
        contentHandler.characters(mappingDocument.toCharArray(), 0, mappingDocument.length());
        contentHandler.endElement("", "mappingDocument", "mappingDocument");

        contentHandler.startElement("", "outputFile", "outputFile", new AttributesImpl());
        contentHandler.characters(outputFile.toCharArray(), 0, outputFile.length());
        contentHandler.endElement("", "outputFile", "outputFile");
		
		if (resultMessage == MSG_SUCCESS) {
			contentHandler.startElement("", "successMessage", "successMessage", new AttributesImpl());
			contentHandler.characters(resultMessage.toCharArray(), 0, resultMessage.length());
			contentHandler.endElement("", "successMessage", "successMessage");
		}
		else {
			contentHandler.startElement("", "errorMessage", "errorMessage", new AttributesImpl());
			contentHandler.characters(resultMessage.toCharArray(), 0, resultMessage.length());
			contentHandler.endElement("", "errorMessage", "errorMessage");
		}
		
		contentHandler.endElement("", "result", "result");
        contentHandler.endDocument();
    }
}
