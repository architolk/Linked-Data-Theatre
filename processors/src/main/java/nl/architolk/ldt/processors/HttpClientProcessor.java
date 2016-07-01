/**
 * NAME     HttpClientProcessor.java
 * VERSION  1.9.0
 * DATE     2016-06-28
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
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.apache.http.entity.StringEntity;

import org.apache.log4j.Logger;
import org.orbeon.oxf.util.LoggerFactory;

import net.sf.json.JSONObject;
import net.sf.json.JSONArray;

public class HttpClientProcessor extends SimpleProcessor {

    private static final Logger logger = LoggerFactory.createLogger(HttpClientProcessor.class);
	
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
			CloseableHttpClient httpclient = HttpClients.createDefault();
			try {
				// Read content of config pipe
				Document configDocument = readInputAsDOM4J(context, INPUT_CONFIG);
				Node configNode = configDocument.selectSingleNode("//config");

				CloseableHttpResponse response;
				
				if (configNode.valueOf("method").equals("post")) {
					// POST
					// Read content of input pipe
					String jsonstr = determineJsonBody(context, configNode);					
					HttpPost httpRequest = new HttpPost(configNode.valueOf("url"));
					StringEntity body = new StringEntity(jsonstr);
					httpRequest.setEntity(body);

					response = executeRequest(httpRequest, httpclient, jsonstr);
				} else if (configNode.valueOf("method").equals("put")) {
					// PUT
					String jsonstr = determineJsonBody(context, configNode);					
					HttpPut httpRequest = new HttpPut(configNode.valueOf("url"));
					StringEntity body = new StringEntity(jsonstr);
					httpRequest.setEntity(body);
					response = executeRequest(httpRequest, httpclient, jsonstr);
				} else if (configNode.valueOf("method").equals("delete")) {
					//DELETE
					HttpDelete httpRequest = new HttpDelete(configNode.valueOf("url"));
					response = executeRequest(httpRequest, httpclient, null);
				} else if (configNode.valueOf("method").equals("head")) {
					//HEAD
					HttpHead httpRequest = new HttpHead(configNode.valueOf("url"));
					response = executeRequest(httpRequest, httpclient, null);
				} else if (configNode.valueOf("method").equals("options")) {
					//HEAD
					HttpOptions httpRequest = new HttpOptions(configNode.valueOf("url"));
					response = executeRequest(httpRequest, httpclient, null);
				} else {
					//Default = GET
					HttpGet httpRequest = new HttpGet(configNode.valueOf("url"));
					response = executeRequest(httpRequest, httpclient, null);
				}

				try {
					contentHandler.startDocument();
					
					int status = response.getStatusLine().getStatusCode();
					AttributesImpl statusAttr = new AttributesImpl();
					statusAttr.addAttribute("", "status", "status", "CDATA", Integer.toString(status));
					contentHandler.startElement("", "response", "response", statusAttr);
					if (status >= 200 && status < 300) {
						HttpEntity entity = response.getEntity();
						if (entity != null) {
							String responseBody = EntityUtils.toString(entity);
							
							// output-type = json means: response is json, convert to xml. Or else: return plain string
							if (configNode.valueOf("output-type").equals("json")) {
								JSONObject json = JSONObject.fromObject(responseBody);
								parseJSONObject(contentHandler,json);
							} else {
								contentHandler.characters(responseBody.toCharArray(), 0, responseBody.length());
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
		} catch (IOException e) {
			throw new OXFException(e);
		}

	}
    
    private CloseableHttpResponse executeRequest(HttpRequestBase httpRequest, CloseableHttpClient httpclient, String jsonstr) throws ClientProtocolException, IOException {
    	logger.info("Executing request " + httpRequest.getRequestLine());
    	if (!jsonstr.isEmpty())
    		logger.info("With body: " + jsonstr);
		return httpclient.execute(httpRequest);
    }
    
    private String determineJsonBody(PipelineContext context, Node configNode) {
    	Document dataDocument = readInputAsDOM4J(context, INPUT_DATA);
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
		
		return jsonstr;
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
