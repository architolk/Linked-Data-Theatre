/**
 * NAME     RDF4JProperties.java
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

//Get Orbeon properties for repository settings
import org.orbeon.oxf.properties.Properties;
import org.orbeon.oxf.properties.PropertySet;

import org.apache.log4j.Logger;
import org.orbeon.oxf.util.LoggerFactory;

import virtuoso.rdf4j.driver.VirtuosoRepository;
import org.eclipse.rdf4j.repository.http.HTTPRepository;
import org.eclipse.rdf4j.repository.sparql.SPARQLRepository;
import org.eclipse.rdf4j.repository.Repository;

public class RDF4JProperties {

	private static final Logger logger = LoggerFactory.createLogger(RDF4JProperties.class);

	private static boolean notInitialized = true;
	private static Repository db;
	
	private static void initialize() {
		notInitialized = false;

		//Fetch property-values
		PropertySet props = Properties.instance().getPropertySet();
		String database = props.getString("oxf.rdf.repository.database");
		String connectString = props.getString("oxf.rdf.repository.connectString");
		String username = props.getString("oxf.rdf.repository.username");
		String password = props.getString("oxf.rdf.repository.password");
		String queryEndpoint = props.getString("oxf.rdf.repository.queryEndpoint");
		String updateEndpoint = props.getString("oxf.rdf.repository.updateEndpoint");

		logger.info(String.format("Database: %s", database));

		if (database.equals("virtuoso")) {
			db = new VirtuosoRepository(connectString, username, password);
		} else if (database.equals("sparql")) {
			db = new SPARQLRepository(queryEndpoint, updateEndpoint);
		} else if (database.equals("rdf4j")) {
			db = new HTTPRepository(connectString);
		}
		db.initialize();
	}

	//Creates a repository, or returns the available repository.
	public static Repository createRepository() {
		if (notInitialized) {initialize();}
		return db;
	}
	
}
