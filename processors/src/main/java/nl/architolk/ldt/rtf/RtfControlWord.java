package nl.architolk.ldt.rtf;

/**
 * This class represents an RTF control word in the element tree.
 *
 * @author <a href="mailto:acsf.dev@gmail.com">Kay Schröer</a>
 */
public class RtfControlWord extends RtfElement {
	/**
	 * Control word, e.g. fs
	 */
	public String word;

	/**
	 * Word parameter, e.g. 22
	 */
	public int parameter;

	/*
	 * (non-Javadoc)
	 *
	 * @see org.rtf.RtfElement#dump(int)
	 */
	@Override
	public void dump(int level) {
		System.out.println("<div style='color:green'>");
		indent(level);
		System.out.println("WORD " + word + " (" + parameter + ")");
		System.out.println("</div>");
	}
}
