/**
 * NAME     ExcelSerializer.java
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
 * Orbeon processor to serialize xml document to Excel (xlsx)
 *
 * This version uses a domDocument. For better perforance, a SAX parser should be used, but is a bit more complicated
 */
package nl.architolk.ldt.processors;

import org.apache.log4j.Logger;
import org.orbeon.oxf.common.OXFException;
import org.orbeon.oxf.pipeline.api.PipelineContext;
import org.orbeon.oxf.processor.ProcessorInput;
import org.orbeon.oxf.processor.serializer.legacy.HttpBinarySerializer;
import org.orbeon.oxf.util.*;

import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;

import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFCell;

import java.io.OutputStream;

public class ExcelSerializer extends HttpBinarySerializer {

    private static final Logger logger = LoggerFactory.createLogger(ExcelSerializer.class);

    public static String DEFAULT_CONTENT_TYPE = "application/octet-stream";

    protected String getDefaultContentType() {
        return DEFAULT_CONTENT_TYPE;
    }

    protected void readInput(final PipelineContext pipelineContext, final ProcessorInput input, Config config, OutputStream outputStream) {

		try {
			// Read the input as a DOM
			final Document domDocument = readInputAsDOM(pipelineContext, input);

			// create workbook (xlsx)
			XSSFWorkbook wb = new XSSFWorkbook();
			
			//iterate through sheets;
			NodeList sheetNodes = domDocument.getElementsByTagName("sheet");
			
			if (sheetNodes.getLength()==0) {
				throw new OXFException("At least one sheet should be present");
			}
			
			for (short i=0; i<sheetNodes.getLength(); i++) {
				Node sheetNode = sheetNodes.item(i);
				if (sheetNode.getNodeType() == Node.ELEMENT_NODE) {
					Element sheetElement = (Element) sheetNode;
					XSSFSheet sheet = wb.createSheet(sheetElement.getAttribute("name"));
					
					//iterate through rows;
					NodeList rowNodes = sheetNode.getChildNodes();
					short rownr = 0;
					for (short r=0; r<rowNodes.getLength(); r++) {
						Node rowNode = rowNodes.item(r);
						if (rowNode.getNodeType() == Node.ELEMENT_NODE) {
							XSSFRow row = sheet.createRow(rownr++);
							
							//iterate through columns;
							NodeList columnNodes = rowNode.getChildNodes();
							short colnr = 0;
							for (short c=0; c<columnNodes.getLength(); c++) {
								Node columnNode = columnNodes.item(c);
								if (columnNode.getNodeType() == Node.ELEMENT_NODE) {
									XSSFCell cell = row.createCell(colnr++);
									cell.setCellValue(columnNode.getTextContent());
								}
							}
						}
					}
				}
			}
			
			// write workbook to stream
			wb.write(outputStream);
			outputStream.close();
			
		} catch (Exception e) {
            throw new OXFException(e);
		}

    }
}
