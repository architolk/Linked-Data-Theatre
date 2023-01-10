/**
 * NAME     Rtf2html.java
 * VERSION  1.25.0
 * DATE     2020-07-19
 *
 * Copyright 2012-2020
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
 * Creates an MD5 hash from a string
 *
 */
package nl.architolk.ldt.utils;

import nl.architolk.ldt.rtf.RtfReader;
import nl.architolk.ldt.rtf.RtfHtml;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.DocumentType;
import org.jsoup.safety.Cleaner;
import org.jsoup.safety.Safelist;

public class Rtf2html {

    public static String rtf2html(String rtf) {
      try {
        RtfReader reader = new RtfReader();
        reader.parse(rtf.replace("<","&lt;"));
        RtfHtml formatter = new RtfHtml();

        Cleaner cleaner = new Cleaner(Safelist.relaxed().addAttributes(":all","class"));
        Document doc = cleaner.clean(Jsoup.parse(formatter.format(reader.root, true)));
        doc.outputSettings().syntax(Document.OutputSettings.Syntax.xml);
        return doc.html();

      } catch (Exception e) {
        return rtf;
      }
    }
}
