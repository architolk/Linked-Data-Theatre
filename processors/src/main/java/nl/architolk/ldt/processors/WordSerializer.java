/**
 * NAME     WordSerializer.java
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
 * Orbeon processor to serialize xml document to Word (docx)
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

import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.apache.poi.xwpf.usermodel.XWPFRun;

import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTBookmark;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTMarkupRange;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTHyperlink;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTText;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTR;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTRPr;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTColor;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.STUnderline;

import java.io.OutputStream;
import java.math.BigInteger;

public class WordSerializer extends HttpBinarySerializer {

    private static final Logger logger = LoggerFactory.createLogger(WordSerializer.class);

    public static String DEFAULT_CONTENT_TYPE = "application/octet-stream";

    protected String getDefaultContentType() {
        return DEFAULT_CONTENT_TYPE;
    }

	protected void addHyperlink(XWPFParagraph para, String text, String bookmark) {
		//Create hyperlink in paragraph
		CTHyperlink cLink=para.getCTP().addNewHyperlink();
		cLink.setAnchor(bookmark);
		//Create the linked text
		CTText ctText=CTText.Factory.newInstance();
		ctText.setStringValue(text);
		CTR ctr=CTR.Factory.newInstance();
		ctr.setTArray(new CTText[]{ctText});

		//Create the formatting
		CTRPr rpr = ctr.addNewRPr();
		CTColor colour = CTColor.Factory.newInstance();
		colour.setVal("0000FF");
		rpr.setColor(colour);
		CTRPr rpr1 = ctr.addNewRPr();
		rpr1.addNewU().setVal(STUnderline.SINGLE);

		//Insert the linked text into the link
		cLink.setRArray(new CTR[]{ctr});
		
	}
	
    protected void readInput(final PipelineContext pipelineContext, final ProcessorInput input, Config config, OutputStream outputStream) {

		try {
			// Test
			BigInteger markId = BigInteger.ONE;
			// Read the input as a DOM
			final Document domDocument = readInputAsDOM(pipelineContext, input);

			// create document (docx)
			XWPFDocument doc = new XWPFDocument();
			
			//iterate through paragraphs;
			NodeList paragraphNodes = domDocument.getElementsByTagName("p");
			
			for (short i=0; i<paragraphNodes.getLength(); i++) {
				Node paragraphNode = paragraphNodes.item(i);
				if (paragraphNode.getNodeType() == Node.ELEMENT_NODE) {
					//Create new paragraph
					XWPFParagraph paragraph = doc.createParagraph();

					//iterate through paragraph parts
					NodeList textNodes = paragraphNode.getChildNodes();
					for (short r=0; r<textNodes.getLength(); r++) {
						Node textNode = textNodes.item(r);
						if (textNode.getNodeType() == Node.TEXT_NODE) {
							XWPFRun run = paragraph.createRun();
							run.setText(textNode.getTextContent());
						}
						if (textNode.getNodeType() == Node.ELEMENT_NODE) {
							Element textElement = (Element) textNode;
							if (textNode.getLocalName().toUpperCase().equals("B")) {
								//Eigenlijk op een andere plaats, maar nu ff voor de test
								String anchor = textElement.getAttribute("id");
								if (!anchor.isEmpty()) {
									CTBookmark bookStart = paragraph.getCTP().addNewBookmarkStart();
									bookStart.setName(anchor);
									bookStart.setId(markId);
								}
								XWPFRun run = paragraph.createRun();
								run.setBold(true);
								run.setText(textNode.getTextContent());
								if (!anchor.isEmpty()) {
									CTMarkupRange bookEnd = paragraph.getCTP().addNewBookmarkEnd();
									bookEnd.setId(markId);
									markId = markId.add(BigInteger.ONE);
								}
							}
							else if (textNode.getLocalName().toUpperCase().equals("A")) {
								addHyperlink(paragraph,textNode.getTextContent(),textElement.getAttribute("href"));
							}
							else {
								XWPFRun run = paragraph.createRun();
								run.setText(textNode.getTextContent());
							}
						}
					}
				}
			}
			// write workbook to stream
			doc.write(outputStream);
			outputStream.close();
			
		} catch (Exception e) {
            throw new OXFException(e);
		}

    }
}
