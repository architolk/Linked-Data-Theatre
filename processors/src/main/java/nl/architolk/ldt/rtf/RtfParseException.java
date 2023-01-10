package nl.architolk.ldt.rtf;

/**
 * This exception is thrown if errors occur when parsing RTF strings, e.g. with
 * an invalid structure.
 *
 * @author <a href="mailto:acsf.dev@gmail.com">Kay Schröer</a>
 */
public class RtfParseException extends Exception {
	private static final long serialVersionUID = 0L;

	/**
	 * Creates the new exception.
	 *
	 * @param message
	 *            error details
	 */
	public RtfParseException(String message) {
		super(message);
	}
}
