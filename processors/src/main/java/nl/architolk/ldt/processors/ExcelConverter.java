/**
 * NAME     ExcelConverter.java
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
 * Orbeon processor to convert Excel format (xlsx) to xml
 *
 */
package nl.architolk.ldt.processors;

import org.orbeon.oxf.pipeline.api.PipelineContext;
import org.orbeon.oxf.processor.ProcessorInputOutputInfo;
import org.orbeon.oxf.processor.SimpleProcessor;
import org.orbeon.oxf.util.Base64XMLReceiver;
import org.xml.sax.ContentHandler;
import org.xml.sax.SAXException;
import org.orbeon.oxf.common.OXFException;
import org.xml.sax.helpers.AttributesImpl;
import org.dom4j.Document;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFCell;
import org.apache.poi.xssf.usermodel.XSSFFormulaEvaluator;
import org.apache.poi.ss.usermodel.DataFormatter;

public class ExcelConverter extends SimpleProcessor {

    public ExcelConverter() {
        addInputInfo(new ProcessorInputOutputInfo(INPUT_DATA));
        addOutputInfo(new ProcessorInputOutputInfo(OUTPUT_DATA));
    }

    public void generateData(PipelineContext context, ContentHandler contentHandler) throws SAXException {

		try {
			// Read binary content of Excel file
			ByteArrayOutputStream os =  new ByteArrayOutputStream();
			Base64XMLReceiver base64ContentHandler = new Base64XMLReceiver(os);
			readInputAsSAX(context, INPUT_DATA, base64ContentHandler);
			final byte[] fileContent = os.toByteArray();
			final java.io.ByteArrayInputStream bais = new ByteArrayInputStream(fileContent);

			// Create workbook
			XSSFWorkbook workbook = new XSSFWorkbook(bais);
			DataFormatter formatter = new DataFormatter();
			XSSFFormulaEvaluator evaluator = new XSSFFormulaEvaluator(workbook);

			contentHandler.startDocument();
			contentHandler.startElement("", "workbook", "workbook", new AttributesImpl());
			
			for (int s=0; s<workbook.getNumberOfSheets(); s++) {
				XSSFSheet sheet = workbook.getSheetAt(s);
				AttributesImpl sheetAttr = new AttributesImpl();
				sheetAttr.addAttribute("", "name", "name", "CDATA", sheet.getSheetName());
				contentHandler.startElement("", "sheet", "sheet", sheetAttr);
				for (int r=0; r<=sheet.getLastRowNum(); r++) {
					XSSFRow row = sheet.getRow(r);
					if (row!=null) {
						AttributesImpl rowAttr = new AttributesImpl();
						rowAttr.addAttribute("", "id", "id", "CDATA", Integer.toString(r));
						contentHandler.startElement("", "row", "row", rowAttr);
						for (int c=0; c<row.getLastCellNum(); c++) {
							XSSFCell cell = row.getCell(c);
							if (cell!=null) {
								try {
									String cellvalue = formatter.formatCellValue(cell,evaluator);
									if (cellvalue!="") {
										AttributesImpl columnAttr = new AttributesImpl();
										columnAttr.addAttribute("", "id", "id", "CDATA", Integer.toString(cell.getColumnIndex()));
										contentHandler.startElement("", "column", "column", columnAttr);
										contentHandler.characters(cellvalue.toCharArray(), 0, cellvalue.length());
										contentHandler.endElement("", "column", "column");
									}
								} catch (Exception e) {}
							}
						}
						contentHandler.endElement("", "row", "row");
					}
				}
				contentHandler.endElement("", "sheet", "sheet");
			}
			
			contentHandler.endElement("", "workbook", "workbook");
			contentHandler.endDocument();
			
		} catch (IOException e) {
			throw new OXFException(e);
		}
    }
}
