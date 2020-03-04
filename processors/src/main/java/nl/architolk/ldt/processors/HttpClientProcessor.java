/**
 * NAME     HttpClientProcessor.java
 * VERSION  1.22.0
 * DATE     2018-06-16
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
import org.orbeon.oxf.common.OXFException;
import org.xml.sax.helpers.AttributesImpl;
import org.dom4j.Document;
import org.dom4j.Node;
import org.dom4j.Element;
import org.dom4j.Attribute;

import java.io.IOException;
import java.util.Iterator;

import org.apache.http.HttpEntity;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.client.methods.HttpRequestBase;
import org.apache.http.client.methods.HttpDelete;
import org.apache.http.client.methods.HttpHead;
import org.apache.http.client.methods.HttpOptions;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpEntityEnclosingRequestBase;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.util.EntityUtils;
import org.apache.http.entity.StringEntity;
import org.apache.http.Header;
import org.apache.http.HttpHeaders;

import org.apache.http.client.protocol.HttpClientContext;
import org.apache.http.client.CredentialsProvider;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.AuthCache;
import org.apache.http.impl.client.BasicAuthCache;
import org.apache.http.impl.auth.BasicScheme;
import org.apache.http.HttpHost;
import java.net.URL;

import org.apache.http.client.entity.UrlEncodedFormEntity;
import java.util.List;
import org.apache.http.NameValuePair;
import java.util.ArrayList;
import org.apache.http.message.BasicNameValuePair;

import org.apache.log4j.Logger;
import org.orbeon.oxf.util.LoggerFactory;

import net.sf.json.JSONObject;
import net.sf.json.JSONArray;

import org.apache.any23.Any23;
import org.apache.any23.writer.RDFXMLWriter;
import org.apache.any23.writer.TripleHandler;
import org.apache.any23.source.DocumentSource;
import org.apache.any23.source.StringDocumentSource;
import org.apache.any23.source.ByteArrayDocumentSource;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;

import java.io.CharArrayWriter;
import java.io.StringWriter;
import org.apache.commons.io.IOUtils;

import java.io.ByteArrayInputStream;
import org.xml.sax.Attributes;
import org.xml.sax.XMLReader;
import org.xml.sax.InputSource;
import org.xml.sax.helpers.DefaultHandler;
import org.orbeon.oxf.xml.XMLParsing;
import org.xml.sax.Locator;

import com.github.jsonldjava.utils.JsonUtils;
import com.github.jsonldjava.core.JsonLdProcessor;
import com.github.jsonldjava.impl.NQuadTripleCallback;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Entities;

public class HttpClientProcessor extends SimpleProcessor {

	//The ParseHandler is a ContentHandler that doesn't forward the startDocument and endDocument events.
	//This means that it can be used to insert a parsed document into an existing XML element
	protected static class ParseHandler implements ContentHandler {

		private ContentHandler myContentHandler;
		private Logger myLogger;

		public ParseHandler(ContentHandler contentHandler) {
			super();
			this.myContentHandler = contentHandler;
		}

		//Ignore startDocument and endDocument
		public void startDocument() throws SAXException {};
		public void endDocument() throws SAXException {};

		//Forward all other events to the real ContentHandler
		public void startElement(String uri, String localname, String qName, Attributes attributes) throws SAXException {
			myContentHandler.startElement(uri, localname, qName, attributes);
		}
		public void endElement(String uri, String localname, String qName) throws SAXException {
			myContentHandler.endElement(uri, localname, qName);
		}
		public void characters(char[] chars, int start, int length) throws SAXException {
			myContentHandler.characters(chars, start, length);
		}
		public void setDocumentLocator(Locator locator) {
			myContentHandler.setDocumentLocator(locator);
		}
		public void startPrefixMapping(java.lang.String prefix, java.lang.String uri) throws SAXException {
			myContentHandler.startPrefixMapping(prefix,uri);
		}
		public void endPrefixMapping(java.lang.String prefix) throws SAXException {
			myContentHandler.endPrefixMapping(prefix);
		}
		public void ignorableWhitespace(char[] ch,int start,int length) throws SAXException {
			myContentHandler.ignorableWhitespace(ch,start,length);
		}
		public void processingInstruction(java.lang.String target,java.lang.String data) throws SAXException {
			myContentHandler.processingInstruction(target,data);
		}
		public void skippedEntity(java.lang.String name) throws SAXException {
			myContentHandler.skippedEntity(name);
		}

	}

    private static final Logger logger = LoggerFactory.createLogger(HttpClientProcessor.class);

	private HttpClientContext httpContext = null;

	// NAMESPACE_URI should be added to the properties (as stated in http://wiki.orbeon.com/forms/doc/developer-guide/api-xpl-processor-api)
	// Won't do this time: no validation of CONFIG
	public static final String HTTP_CLIENT_PROCESSOR_CONFIG_NAMESPACE_URI = "http://ldt.architolk.nl/processors/http-client-processor-config";

    public HttpClientProcessor() {
        addInputInfo(new ProcessorInputOutputInfo(INPUT_CONFIG));
        addInputInfo(new ProcessorInputOutputInfo(INPUT_DATA));
        addOutputInfo(new ProcessorInputOutputInfo(OUTPUT_DATA));
    }

    public void generateData(PipelineContext context, ContentHandler contentHandler) throws SAXException {

		try {
			CloseableHttpClient httpclient = HttpClientProperties.createHttpClient();

			try {
				// Read content of config pipe
				Document configDocument = readInputAsDOM4J(context, INPUT_CONFIG);
				Node configNode = configDocument.selectSingleNode("//config");

				URL theURL = new URL(configNode.valueOf("url"));

				if (configNode.valueOf("auth-method").equals("basic")) {
					HttpHost targetHost = new HttpHost(theURL.getHost(),theURL.getPort(),theURL.getProtocol());
					//Authentication support
					CredentialsProvider credsProvider = new BasicCredentialsProvider();
					credsProvider.setCredentials(
						AuthScope.ANY,
						new UsernamePasswordCredentials(configNode.valueOf("username"), configNode.valueOf("password"))
					);
					// logger.info("Credentials: "+configNode.valueOf("username")+"/"+configNode.valueOf("password"));
					// Create AuthCache instance
					AuthCache authCache = new BasicAuthCache();
					authCache.put(targetHost,new BasicScheme());

					// Add AuthCache to the execution context
					httpContext = HttpClientContext.create();
					httpContext.setCredentialsProvider(credsProvider);
					httpContext.setAuthCache(authCache);
				} else if (configNode.valueOf("auth-method").equals("form")) {
					//Sign in. Cookie will be remembered bij httpclient
					HttpPost authpost = new HttpPost(configNode.valueOf("auth-url"));
					List<NameValuePair> nameValuePairs = new ArrayList<NameValuePair>();
					nameValuePairs.add(new BasicNameValuePair("userName", configNode.valueOf("username")));
					nameValuePairs.add(new BasicNameValuePair("password", configNode.valueOf("password")));
					authpost.setEntity(new UrlEncodedFormEntity(nameValuePairs));
					CloseableHttpResponse httpResponse = httpclient.execute(authpost);
					// logger.info("Signin response:"+Integer.toString(httpResponse.getStatusLine().getStatusCode()));
				}

				CloseableHttpResponse response;
				if (configNode.valueOf("method").equals("post")) {
					// POST
					HttpPost httpRequest = new HttpPost(configNode.valueOf("url"));
					String acceptHeader = configNode.valueOf("accept");
					if (!acceptHeader.isEmpty()) {
						httpRequest.addHeader(HttpHeaders.ACCEPT,acceptHeader);
						logger.info("Accept: " + acceptHeader);
					}
					String contentHeader = configNode.valueOf("content");
					if (!contentHeader.isEmpty()) {
						httpRequest.addHeader(HttpHeaders.CONTENT_TYPE,contentHeader);
						logger.info("Content: " + contentHeader);
					}
					setBody(httpRequest,context,configNode);
					response = executeRequest(httpRequest, httpclient);
				} else if (configNode.valueOf("method").equals("put")) {
					// PUT
					HttpPut httpRequest = new HttpPut(configNode.valueOf("url"));
					setBody(httpRequest,context,configNode);
					response = executeRequest(httpRequest, httpclient);
				} else if (configNode.valueOf("method").equals("delete")) {
					//DELETE
					HttpDelete httpRequest = new HttpDelete(configNode.valueOf("url"));
					response = executeRequest(httpRequest, httpclient);
				} else if (configNode.valueOf("method").equals("head")) {
					//HEAD
					HttpHead httpRequest = new HttpHead(configNode.valueOf("url"));
					response = executeRequest(httpRequest, httpclient);
				} else if (configNode.valueOf("method").equals("options")) {
					//OPTIONS
					HttpOptions httpRequest = new HttpOptions(configNode.valueOf("url"));
					response = executeRequest(httpRequest, httpclient);
				} else {
					//Default = GET
					HttpGet httpRequest = new HttpGet(configNode.valueOf("url"));
					String acceptHeader = configNode.valueOf("accept");
					if (!acceptHeader.isEmpty()) {
						httpRequest.addHeader(HttpHeaders.ACCEPT,acceptHeader);
					}
					//Add proxy route if needed
					HttpClientProperties.setProxy(httpRequest,theURL.getHost());
					response = executeRequest(httpRequest, httpclient);
				}

				try {
					contentHandler.startDocument();

					int status = response.getStatusLine().getStatusCode();
					AttributesImpl statusAttr = new AttributesImpl();
					statusAttr.addAttribute("", "status", "status", "CDATA", Integer.toString(status));
					contentHandler.startElement("", "response", "response", statusAttr);
					if (status >= 200 && status < 300) {
						HttpEntity entity = response.getEntity();
						Header contentType = response.getFirstHeader("Content-Type");
						if (entity!=null && contentType!=null) {
							//logger.info("Contenttype: " + contentType.getValue());
							//Read content into inputstream
							InputStream inStream = entity.getContent();

							// output-type = json means: response is json, convert to xml
							if (configNode.valueOf("output-type").equals("json")) {
								//TODO: net.sf.json.JSONObject might nog be the correct JSONObject. javax.json.JsonObject might be better!!!
								//javax.json contains readers to read from an inputstream
								StringWriter writer = new StringWriter();
								IOUtils.copy(inStream,writer,"UTF-8");
								JSONObject json = JSONObject.fromObject(writer.toString());
								parseJSONObject(contentHandler,json);
							// output-type = xml means: response is xml, keep it
							} else if (configNode.valueOf("output-type").equals("xml")) {
								try {
									XMLReader saxParser = XMLParsing.newXMLReader(new XMLParsing.ParserConfiguration(false,false,false));
									saxParser.setContentHandler(new ParseHandler(contentHandler));
									saxParser.parse(new InputSource(inStream));
								} catch (Exception e) {
									throw new OXFException(e);
								}
							// output-type = jsonld means: reponse is json-ld, (a) convert to nquads; (b) convert to xml
							} else if (configNode.valueOf("output-type").equals("jsonld")) {
								try {
									Object jsonObject = JsonUtils.fromInputStream(inStream,"UTF-8"); //TODO: UTF-8 should be read from response!
									Object nquads = JsonLdProcessor.toRDF(jsonObject,new NQuadTripleCallback());

									Any23 runner = new Any23();
									DocumentSource source = new StringDocumentSource((String)nquads,configNode.valueOf("url"));
									ByteArrayOutputStream out = new ByteArrayOutputStream();
									TripleHandler handler = new RDFXMLWriter(out);
									try {
										runner.extract(source,handler);
									} finally {
										handler.close();
									}
									ByteArrayInputStream inJsonStream = new ByteArrayInputStream(out.toByteArray());
									XMLReader saxParser = XMLParsing.newXMLReader(new XMLParsing.ParserConfiguration(false,false,false));
									saxParser.setContentHandler(new ParseHandler(contentHandler));
									saxParser.parse(new InputSource(inJsonStream));
								} catch (Exception e) {
									throw new OXFException(e);
								}
							// output-type = rdf means: response is some kind of rdf (except json-ld...), convert to xml
							} else if (configNode.valueOf("output-type").equals("rdf")) {
								try {
									Any23 runner = new Any23();

									DocumentSource source;
									//If contentType = text/html than convert from html to xhtml to handle non-xml style html!
									logger.info("Contenttype: " + contentType.getValue());
									if (configNode.valueOf("tidy").equals("yes") && contentType.getValue().startsWith("text/html")) {
										org.jsoup.nodes.Document doc = Jsoup.parse(inStream,"UTF-8",configNode.valueOf("url")); //TODO UTF-8 should be read from response!

										RDFCleaner cleaner = new RDFCleaner();
										org.jsoup.nodes.Document cleandoc = cleaner.clean(doc);
										cleandoc.outputSettings().escapeMode(Entities.EscapeMode.xhtml);
										cleandoc.outputSettings().syntax(org.jsoup.nodes.Document.OutputSettings.Syntax.xml);
										cleandoc.outputSettings().charset("UTF-8");

										source = new StringDocumentSource(cleandoc.html(),configNode.valueOf("url"),contentType.getValue());
									} else {
										source = new ByteArrayDocumentSource(inStream,configNode.valueOf("url"),contentType.getValue());
									}

									ByteArrayOutputStream out = new ByteArrayOutputStream();
									TripleHandler handler = new RDFXMLWriter(out);
									try {
										runner.extract(source,handler);
									} finally {
										handler.close();
									}
									ByteArrayInputStream inAnyStream = new ByteArrayInputStream(out.toByteArray());
									XMLReader saxParser = XMLParsing.newXMLReader(new XMLParsing.ParserConfiguration(false,false,false));
									saxParser.setContentHandler(new ParseHandler(contentHandler));
									saxParser.parse(new InputSource(inAnyStream));

								} catch (Exception e) {
									throw new OXFException(e);
								}
							} else {
								CharArrayWriter writer = new CharArrayWriter();
								IOUtils.copy(inStream,writer,"UTF-8");
								contentHandler.characters(writer.toCharArray(), 0, writer.size());
							}
						}
					}
					contentHandler.endElement("", "response", "response");

					contentHandler.endDocument();
				} finally {
					response.close();
				}
			} finally {
				httpclient.close();
			}
		} catch (Exception e) {
			throw new OXFException(e);
		}

	}

    private CloseableHttpResponse executeRequest(HttpRequestBase httpRequest, CloseableHttpClient httpclient) throws ClientProtocolException, IOException {
    	logger.info("Executing request " + httpRequest.getRequestLine());
		if (httpContext!=null) {
			logger.info("With httpContext" + httpContext.toString());
			return httpclient.execute(httpRequest,httpContext);
		} else {
			return httpclient.execute(httpRequest);
		}
    }

	private void setBody(HttpEntityEnclosingRequestBase httpRequest, PipelineContext context, Node configNode) throws IOException {
		Document dataDocument = readInputAsDOM4J(context, INPUT_DATA);
		if (configNode.valueOf("input-type").equals("form")) {
			List<NameValuePair> nameValuePairs = new ArrayList<NameValuePair>();
			Element rootElement = dataDocument.getRootElement();
			Iterator<?> elit = rootElement.elementIterator();
			while (elit.hasNext()) {
				Element child = (Element) elit.next();
				nameValuePairs.add(new BasicNameValuePair(child.getQName().getName(), child.getText()));
			}
			httpRequest.setEntity(new UrlEncodedFormEntity(nameValuePairs));
		} else {
			String jsonstr;
			if (configNode.valueOf("input-type").equals("json")) {
				//Conversion of XML input to JSON
				JSONObject jsondata = new JSONObject();
				populateJSONObject(jsondata,dataDocument);
				jsonstr = jsondata.toString();
			} else {
				//No conversion, just use plain text in input
				jsonstr = dataDocument.getRootElement().getText();
			}
			httpRequest.setEntity(new StringEntity(jsonstr));
			logger.info("Body: " + jsonstr);
		}
	}

	private void parseJSONObject(ContentHandler contentHandler, JSONObject json) throws SAXException {
		Object[] names = json.names().toArray();
		for( int i = 0; i < names.length; i++ ){
			String name = (String) names[i];
			Object value = json.get(name);
			String safeName = name.replace('@','_');
			contentHandler.startElement("", safeName, safeName, new AttributesImpl());

			if ( value instanceof JSONObject ) {
				parseJSONObject(contentHandler, (JSONObject)value);
			} else if ( value instanceof JSONArray ) {
				Iterator<?> jsonit = ((JSONArray)value).iterator();
				while (jsonit.hasNext()) {
					Object arrayValue = jsonit.next();
					if ( arrayValue instanceof JSONObject ) {
						parseJSONObject(contentHandler, (JSONObject)arrayValue);
					}
					else {
						String textValue = String.valueOf(arrayValue);
						contentHandler.characters(textValue.toCharArray(),0,textValue.length());
					}
					//Array means repeating the XML node, so end the current node, and start a new one
					if (jsonit.hasNext()) {
						contentHandler.endElement("", safeName, safeName);
						contentHandler.startElement("", safeName, safeName, new AttributesImpl());
					}
				}
			} else {
				String textValue = String.valueOf(value);
				contentHandler.characters(textValue.toCharArray(),0,textValue.length());
			}

			contentHandler.endElement("", safeName, safeName);
		}
	}

	private void populateJSONArray(JSONArray root, Element element) {
		//At this moment, only simple arrays are possible, not arrays that contain arrays or objects
		Attribute typeAttr = element.attribute("type");
		String nodeType = (typeAttr!=null) ? typeAttr.getValue() : "";
		if (nodeType.equals("number")) {
			//Numeric field
			try {
				root.add(Float.valueOf(element.getText()));
			}
			catch (NumberFormatException e) {
				logger.warn("Not a number: "+element.getText());
			}
		} else {
			//Default = string
			root.add(element.getText());
		}
	}

	private void populateJSONObject(JSONObject root, Element element) {
		Attribute typeAttr = element.attribute("type");
		String nodeType = (typeAttr!=null) ? typeAttr.getValue() : "";
		if (element.isTextOnly()) {
			if (nodeType.equals("node")) {
				//Text only means: no children. If type is explicitly set to "node", the result should be an empty object
				root.put(element.getQName().getName(),new JSONObject());
			} else if (nodeType.equals("number")) {
				//Numeric field
				try {
					root.put(element.getQName().getName(),Float.valueOf(element.getText()));
				}
				catch (NumberFormatException e) {
					logger.warn("Not a number: "+element.getText());
				}
			} else {
				//Default = string
				root.put(element.getQName().getName(),element.getText());
			}
		} else if (nodeType.equals("nodelist")) {
			JSONArray json = new JSONArray();
			Iterator<?> elit = element.elementIterator();
			while (elit.hasNext()) {
				Element child = (Element) elit.next();
				populateJSONArray(json,child);
			}
			root.put(element.getQName().getName(),json);
		} else {
			JSONObject json = new JSONObject();
			Iterator<?> elit = element.elementIterator();
			while (elit.hasNext()) {
				Element child = (Element) elit.next();
				populateJSONObject(json,child);
			}
			root.put(element.getQName().getName(),json);
		}
	}

	private void populateJSONObject(JSONObject root, Document document) {
		Element rootElement = document.getRootElement();
		populateJSONObject(root,rootElement);
	}
}
