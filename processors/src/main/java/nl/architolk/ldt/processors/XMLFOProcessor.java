/**
 * NAME     XMLFOProcessor.java
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
 * Orbeon processor to serialize xml document to PDF, using XML-FO engine
 *
 */
package nl.architolk.ldt.processors;

import org.apache.fop.apps.FOUserAgent;
import org.apache.fop.apps.Fop;
import org.apache.fop.apps.FopFactory;
import org.apache.fop.apps.MimeConstants;
import org.apache.log4j.Logger;
import org.orbeon.oxf.common.OXFException;
import org.orbeon.oxf.pipeline.api.PipelineContext;
import org.orbeon.oxf.processor.ProcessorInput;
import org.orbeon.oxf.util.LoggerFactory;
import org.orbeon.oxf.xml.ForwardingXMLReceiver;
import org.orbeon.oxf.processor.serializer.legacy.HttpBinarySerializer;

import java.io.File;
import java.io.OutputStream;
import java.net.URL;

public class XMLFOProcessor extends HttpBinarySerializer {

    private static final Logger logger = LoggerFactory.createLogger(XMLFOProcessor.class);

    public static String DEFAULT_CONTENT_TYPE = "application/pdf";

    protected String getDefaultContentType() {
        return DEFAULT_CONTENT_TYPE;
    }

    protected void readInput(PipelineContext context, ProcessorInput input, Config config, OutputStream outputStream) {
        try {
            // Setup FOP to output PDF
            final FopFactory fopFactory = FopFactory.newInstance();
            final FOUserAgent foUserAgent = fopFactory.newFOUserAgent();

			final Config httpConfig = (Config) config;
			
            final URL configFileUrl = this.getClass().getClassLoader().getResource("fop-userconfig.xml");
            if (configFileUrl == null) {
                logger.warn("FOP config file not found. Please put a fop-userconfig.xml file in your classpath for proper display of UTF-8 characters.");
            } else {
                final File userConfigXml = new File(configFileUrl.getFile());
                fopFactory.setUserConfig(userConfigXml);
            }

            Fop fop = fopFactory.newFop(httpConfig.contentType, foUserAgent, outputStream);

            // Send data to FOP
            readInputAsSAX(context, INPUT_DATA, new ForwardingXMLReceiver(fop.getDefaultHandler()));
        } catch (Exception e) {
            throw new OXFException(e);
        }
    }
}
