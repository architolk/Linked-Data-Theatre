/**
 * NAME     RDB2RDFThread.java
 * VERSION  1.5.1
 * DATE     2016-02-09
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
 * Thread for the execution of the MorphRDB converter.
 * To be used with the RDB2RDFProcessor for asynchronous execution
 */
package nl.architolk.ldt.processors;

import java.io.IOException;

import org.apache.log4j.Logger;

import es.upm.fi.dia.oeg.morph.r2rml.rdb.engine.MorphRDBRunner;
import es.upm.fi.dia.oeg.morph.r2rml.rdb.engine.MorphRDBRunnerFactory;
import es.upm.fi.dia.oeg.morph.base.MorphProperties;
import es.upm.fi.dia.oeg.morph.base.engine.MorphBaseRunner;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.CallableStatement;

public class RDB2RDFThread extends Thread {

	private MorphProperties properties;

    public RDB2RDFThread(MorphProperties _properties) {
		//Properties should be in memory space of the Thread
		this.properties = _properties;
    }

	public void run() {
		Logger logger = Logger.getLogger(this.getClass());
		try {

			logger.debug("Mapping document: "+this.properties.getProperty("mappingdocument.file.path"));
			logger.debug("Output file: "+this.properties.getProperty("output.file.path"));
		
			MorphRDBRunnerFactory runnerFactory = new MorphRDBRunnerFactory();
			MorphBaseRunner runner = runnerFactory.createRunner(this.properties);
			try {
				runner.run();
			}
			finally {
				// Closing the outputFile (bug in MorphRDB??)
				runner.outputStream().close();
			}
		}
		catch (Exception e) {
			//Need to do something with the resultMesssage. Maybe write to outputStream??
			String resultMessage = e.getMessage();
			logger.debug("Catched error: " + resultMessage);
		}
		logger.debug("Finished conversion, starting uploading");
		
		// Asynchronous execution, so upload to virtuoso store should be part of this thread
		try {
			Context ctx = new InitialContext();
			DataSource ds = (DataSource) ctx.lookup("java:/comp/env/jdbc/virtuoso");
			Connection con = ds.getConnection();
			CallableStatement cs = con.prepareCall("{call ldt.upload_rdf(?,?,'del','ttl')}");
			cs.setString(1,this.properties.getProperty("output.file.path")); // Input file
			cs.setString(2,this.properties.getProperty("graph")); // Graph
			cs.executeQuery();
		}
		catch (Exception e) {
			logger.debug("Catched SQL error: " + e.getMessage());
		}
		logger.debug("Finished uploading");
	}
	
}
