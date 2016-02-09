/**
 * NAME     RDB2RDFExecutor.java
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
 * Executor of the RDB2RDF Thread. To be used as a singleton and a JNDI resource
 * This enforces that only one conversion is active at a certain moment in time
 */
package nl.architolk.ldt.processors;

import es.upm.fi.dia.oeg.morph.base.MorphProperties;

public class RDB2RDFExecutor {

	private RDB2RDFThread runThread;

	public String start(MorphProperties properties) {
		if (runThread==null) {
			//No thread started
			runThread = new RDB2RDFThread(properties);
			runThread.start();
			return RDB2RDFConstants.MSG_STARTED;
		} else {
			if (runThread.isAlive()) {
				return RDB2RDFConstants.MSG_ACTIVE;
			} else {
				//Thread has terminated, start a new one
				runThread = new RDB2RDFThread(properties);
				runThread.start();
				return RDB2RDFConstants.MSG_STARTED;
			}
		}
	}
	
}
