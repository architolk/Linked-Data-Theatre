/**
 * NAME     MarkDownConverter.java
 * VERSION  1.18.0
 * DATE     2017-06-18
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
 * Orbeon processor to convert a XML document containing a markdown string to a XML document containing a HTML string
 * Config should define the uri of the node(s) that contain the markdown string
 * The returned document is a copy of the original document, the content of every node with the defined uri will be transformed from markdown to html
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
import org.dom4j.Node;

import org.orbeon.oxf.cache.OutputCacheKey;
import org.orbeon.oxf.processor.ProcessorImpl;
import org.orbeon.oxf.processor.ProcessorOutput;
import org.orbeon.oxf.xml.SimpleForwardingXMLReceiver;
import org.orbeon.oxf.xml.XMLReceiver;
import org.xml.sax.ContentHandler;
import org.xml.sax.Attributes;

import com.github.rjeschke.txtmark.Processor;

public class MarkDownConverter extends ProcessorImpl {

	// NAMESPACE_URI should be added to the properties (as stated in http://wiki.orbeon.com/forms/doc/developer-guide/api-xpl-processor-api)
	// Won't do this time: no validation of CONFIG
	public static final String MARKDOWN_CONVERTER_CONFIG_NAMESPACE_URI = "http://ldt.architolk.nl/processors/markdown-converter-config";
	
	protected static class MarkDownXMLReceiver extends SimpleForwardingXMLReceiver {
	
		private ContentHandler myContentHandler;
		private boolean isMdElement;
		private String markdownUri;
	
		public MarkDownXMLReceiver(XMLReceiver xmlReceiver, String uri) {
			super(xmlReceiver);
			this.myContentHandler = xmlReceiver;
			this.isMdElement = false;
			this.markdownUri = uri;
		}
	
		@Override
		public void startElement(String uri, String localname, String qName, Attributes attributes) throws SAXException {
			myContentHandler.startElement(uri, localname, qName, attributes);
			isMdElement = (markdownUri.equals(uri.concat(localname)));
		}

		@Override
		public void endElement(String uri, String localname, String qName) throws SAXException {
			myContentHandler.endElement(uri, localname, qName);
			isMdElement = false;
		}

		@Override
		public void characters(char[] chars, int start, int length) throws SAXException {
			if (isMdElement) {
				// Convert to markdown
				String result = Processor.process(String.valueOf(chars));
				// Return result
				myContentHandler.characters(result.toCharArray(), 0, result.length());
			} else {
				myContentHandler.characters(chars, start, length);
			}
		}

	}

    public MarkDownConverter() {
        addInputInfo(new ProcessorInputOutputInfo(INPUT_DATA));
		addInputInfo(new ProcessorInputOutputInfo(INPUT_CONFIG));
        addOutputInfo(new ProcessorInputOutputInfo(OUTPUT_DATA));
    }

    public ProcessorOutput createOutput(String name) {
        final ProcessorOutput output = new ProcessorOutputImpl(MarkDownConverter.this, name) {
            public void readImpl(PipelineContext context, XMLReceiver xmlReceiver) {
				// Read content of config pipe
				Document configDocument = readInputAsDOM4J(context, INPUT_CONFIG);
				Node configNode = configDocument.selectSingleNode("//config");
				String uri = configNode.valueOf("uri");
				// Read en process content of input pipe
                readInputAsSAX(context, INPUT_DATA, new MarkDownXMLReceiver(xmlReceiver, uri));
            }

            @Override
            public OutputCacheKey getKeyImpl(PipelineContext pipelineContext) {
                return getInputKey(pipelineContext, getInputByName(INPUT_DATA));
            }

            @Override
            public Object getValidityImpl(PipelineContext pipelineContext) {
                return getInputValidity(pipelineContext, getInputByName(INPUT_DATA));
            }
        };
        addOutput(name, output);
        return output;
    }
}
