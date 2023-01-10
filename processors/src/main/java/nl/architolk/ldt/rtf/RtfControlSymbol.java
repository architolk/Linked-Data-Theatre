package nl.architolk.ldt.rtf;

/**
 * This class represents an RTF control symbol in the element tree.
 *
 * @author <a href="mailto:acsf.dev@gmail.com">Kay Schröer</a>
 */
public class RtfControlSymbol extends RtfElement {
	/**
	 * Control symbol, e.g. &#42;
	 */
	public char symbol;

	/**
	 * Symbol parameter, e.g. 0
	 */
	public int parameter = 0;

	/*
	 * (non-Javadoc)
	 *
	 * @see org.rtf.RtfElement#dump(int)
	 */
	@Override
	public void dump(int level) {
		System.out.println("<div style='color:blue'>");
		indent(level);
		System.out.println("SYMBOL " + symbol + " (" + parameter + ")");
		System.out.println("</div>");
	}
}
