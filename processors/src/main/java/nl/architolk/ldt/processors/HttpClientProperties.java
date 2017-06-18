/**
 * NAME     HttpClientProperties.java
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
 * Properties for the HttpClient (static class for proxy and ssl information)
 *
 */
package nl.architolk.ldt.processors;

import org.apache.http.impl.client.HttpClients;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.client.methods.HttpGet;

//Get Orbeon properties for proxy and ssl settings
import org.orbeon.oxf.properties.Properties;
import org.orbeon.oxf.properties.PropertySet;

//Proxy
import org.apache.http.client.config.RequestConfig;
import org.apache.http.HttpHost;

//Security SSL Keystore
import java.net.URL;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import javax.net.ssl.SSLContext;
import org.apache.http.ssl.SSLContexts;
 
public class HttpClientProperties {

	private static boolean notInitialized = true;
	private static SSLConnectionSocketFactory sslsf = null;
	private static RequestConfig requestConfig = null;
	private static String proxyExclude = null;
	
	//TODO: All exceptions are handled as Exception, and not their real class
	private static void initialize() throws Exception {
		notInitialized = false;

		//Fetch property-values
		PropertySet props = Properties.instance().getPropertySet();
		String proxyHost = props.getString("oxf.http.proxy.host");
		Integer proxyPort = props.getInteger("oxf.http.proxy.port");
		proxyExclude = props.getString("oxf.http.proxy.exclude");
		String sslKeystoreURI = props.getStringOrURIAsString("oxf.http.ssl.keystore.uri", false);
		String sslKeystorePassword = props.getString("oxf.http.ssl.keystore.password");

		//Create custom scheme if needed
		if (sslKeystoreURI!=null && sslKeystorePassword!=null) {
			SSLContext sslcontext = SSLContexts.custom()
				.loadTrustMaterial(new URL(sslKeystoreURI), sslKeystorePassword.toCharArray())
				.build();
			sslsf = new SSLConnectionSocketFactory(sslcontext);
		}
		
		//Create requestConfig proxy if needed
		if (proxyHost!=null && proxyPort!=null) {
			requestConfig = RequestConfig.custom().setProxy(new HttpHost(proxyHost, proxyPort, "http")).build();
		}
	}

	//Creates a default httpClient, or a custom httpClient with SSL certificates if specified
	public static CloseableHttpClient createHttpClient() throws Exception {
		if (notInitialized) {initialize();}
		if (sslsf!=null) {
			return HttpClients.custom().setSSLSocketFactory(sslsf).build();
		} else {
			return HttpClients.createDefault();
		}
	}
	
	//Sets proxy settings if needed (specified and hostname is not excluded)
	//TODO: not using HttpGet, but interface (to facility same method for HttpPost, etc)
	public static void setProxy(HttpGet httpRequest, String hostname) throws Exception {
		if (notInitialized) {initialize();}
		if ((requestConfig!=null) && ((proxyExclude==null) || !hostname.matches(proxyExclude))) {
			httpRequest.setConfig(requestConfig);
		}
	}
}
