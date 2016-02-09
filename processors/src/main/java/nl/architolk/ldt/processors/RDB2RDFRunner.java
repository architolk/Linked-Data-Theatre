/**
 * NAME     RDB2RDFRunner.java
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
 * Runner for the execution of the MorphRDB converter.
 * To be used with the RDB2RDFProcessor for asynchronous execution
 */
package nl.architolk.ldt.processors;

import java.io.IOException;

import org.apache.log4j.Logger;

import es.upm.fi.dia.oeg.morph.r2rml.rdb.engine.MorphRDBRunner;
import es.upm.fi.dia.oeg.morph.r2rml.rdb.engine.MorphRDBRunnerFactory;
import es.upm.fi.dia.oeg.morph.base.MorphProperties;
import es.upm.fi.dia.oeg.morph.base.engine.MorphBaseRunner;

public class RDB2RDFRunner {

	private MorphProperties properties;

    public RDB2RDFRunner(MorphProperties _properties) {
		this.properties = _properties;
    }

	public String run() {
		Logger logger = Logger.getLogger(this.getClass());
		String resultMessage = RDB2RDFConstants.MSG_SUCCESS;
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
			resultMessage = e.getMessage();
			logger.debug("Catched error: " + resultMessage);
		}
		logger.debug("Finished");
		return resultMessage;
	}
	
}
