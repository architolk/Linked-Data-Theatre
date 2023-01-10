package nl.architolk.ldt.rtf;

/**
 * This class specifies a structure of layout information used for text
 * formatting in the span tag and obtained from RTF control words.
 *
 * @author <a href="mailto:acsf.dev@gmail.com">Kay Schröer</a>
 */
public class RtfState implements Cloneable {
	/**
	 * Attribute that specifies that text should be written in bold
	 */
	public boolean bold;

	/**
	 * Attribute that specifies that text should be written in italic
	 */
	public boolean italic;

	/**
	 * Attribute that specifies that text should be underlined
	 */
	public boolean underline;

	/**
	 * Attribute that specifies that text should be striked through
	 */
	public boolean strike;

	/**
	 * Attribute that specifies that text should be hidden
	 */
	public boolean hidden;

	/**
	 * Attribute that specifies that the text should be beneath the baseline ("down", negative) or above the baseline ("up", positive) by N.
	 * <br>RTF "dnN" move down N half-points; does not imply font size reduction, thus font size is given separately --> value negative from param, fontsize unchanged.
	 * <br>RTF "upN" move up N half-points; does not imply font size reduction, thus font size is given separately --> value positive from param, fontsize unchanged.
	 */
	public int dnup;

	/**
	 * Attribute that specifies that the text should be subscript. Switchs of superscript.
	 * <br>RTF "sub" denotes subscript and implies font size reduction --> true, actual fontsize is 1/2 of actual font size.
	 * <br>Turned of by /nosupersub.
	 */
	public boolean subscript;

	/**
	 * Attribute that specifies that the text should be superscript. Switches of subscript.
	 * <br>RTF "super" denotes superscript and implies font size reduction --> true, actual fontsize is 1/2 of actual font size.
	 * <br>Turned of by /nosupersub.
	 */
	public boolean superscript;

	/**
	 * Font size in pixels
	 */
	public int fontSize;

	/**
	 * Font as a position in the font table
	 */
	public int font;

	/**
	 * Text color as a position in the color table
	 */
	public int textColor;

	/**
	 * Background color as a position in the color table
	 */
	public int background;

	/**
	 * Creates a new RTF state.
	 */
	public RtfState() {
		reset();
	}

	/**
	 * Clones the layout information.
	 *
	 * @return a copy of this object
	 */
	@Override
	public Object clone() {
		RtfState newState = new RtfState();
		newState.bold = this.bold;
		newState.italic = this.italic;
		newState.underline = this.underline;
		newState.strike = this.strike;
		newState.hidden = this.hidden;
		newState.dnup = this.dnup;
		newState.subscript = this.subscript;
		newState.superscript = this.superscript;
		newState.fontSize = this.fontSize;
		newState.font = this.font;
		newState.textColor = this.textColor;
		newState.background = this.background;
		return newState;
	}

	/**
	 * Compares two states for equality.
	 *
	 * @param obj
	 *            the object to compare with
	 * @return {@code true} if and only if the argument is not {@code null} and
	 *         is a {@code RtfState} object that contains the same layout
	 *         information as this object
	 */
	@Override
	public boolean equals(Object obj) {
		if (obj == null) {
			return false;
		}
		if (!(obj instanceof RtfState)) {
			return false;
		}

		RtfState anotherState = (RtfState) obj;
		return this.bold == anotherState.bold && this.italic == anotherState.italic
				&& this.underline == anotherState.underline && this.strike == anotherState.strike
				&& this.dnup == anotherState.dnup
				&& this.subscript == anotherState.subscript && this.superscript == anotherState.superscript
				&& this.hidden == anotherState.hidden && this.fontSize == anotherState.fontSize
				&& this.font == anotherState.font
				&& this.textColor == anotherState.textColor && this.background == anotherState.background;
	}

	/**
	 * Sets the attributes to default values.
	 */
	public void reset() {
		bold = false;
		italic = false;
		underline = false;
		strike = false;
		hidden = false;
		dnup = 0;
		subscript = false;
		superscript = false;
		fontSize = 0;
		font = 0;
		textColor = 0;
		background = 0;
	}
}
