package nl.architolk.ldt.rtf;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.stream.Collectors;

/**
 * This class parses RTF strings and documents and provides the read RTF
 * structure as an element tree for further processing.
 *
 * @author <a href="mailto:acsf.dev@gmail.com">Kay Schröer</a>
 */
public class RtfReader {
	private String rtf;
	private int pos;
	private int len;
	private char tchar;
	private RtfGroup group;

	/**
	 * Root element of an element tree that contains the processed RTF groups
	 */
	public RtfGroup root = null;

	/**
	 * Reads the next character from the RTF string at a time and stores it in
	 * global variable for later interpretation.
	 */
	protected void getChar() {
		if (pos < rtf.length()) {
			tchar = rtf.charAt(pos++);
		}
	}

	/**
	 * Converts a hexadecimal string to a decimal value.
	 *
	 * @param s
	 *            hex string, e.g. "a0"
	 * @return number
	 */
	protected int hexdec(String s) {
		return Integer.parseInt(s, 16);
	}

	/**
	 * Checks if the previously read character is a digit.
	 *
	 * @return {@code true} if the character is one of 0-9
	 */
	protected boolean isDigit() {
		if (tchar >= 48 && tchar <= 57) {
			return true;
		}
		return false;
	}

	/**
	 * Checks if the previously read character is a letter.
	 *
	 * @return {@code true} if the character is one of a-z or A-Z
	 */
	protected boolean isLetter() {
		if (tchar >= 65 && tchar <= 90) {
			return true;
		}
		if (tchar >= 97 && tchar <= 122) {
			return true;
		}
		return false;
	}

	/**
	 * Handles the start of a group represented by an opening brace.
	 */
	protected void parseStartGroup() {
		// Store state of document on stack.
		RtfGroup newGroup = new RtfGroup();
		if (group != null) {
			newGroup.parent = group;
		}
		if (root == null) {
			group = newGroup;
			root = newGroup;
		} else {
			group.children.add(newGroup);
			group = newGroup;
		}
	}

	/**
	 * Handles the end of a group represented by a closing brace.
	 */
	protected void parseEndGroup() {
		// Retrieve state of document from stack.
		group = group.parent;
	}

	/**
	 * Gets the name and parameter of the control word and finally adds a new
	 * word element to the current group.
	 */
	protected void parseControlWord() {
		getChar();
		String word = "";

		while (isLetter()) {
			word += tchar;
			getChar();
		}

		// Read parameter (if any) consisting of digits.
		// Paramater may be negative.
		int parameter = -1;
		boolean negative = false;
		if (tchar == '-') {
			getChar();
			negative = true;
		}

		while (isDigit()) {
			if (parameter == -1) {
				parameter = 0;
			}
			parameter = parameter * 10 + Integer.parseInt(tchar + "");
			getChar();
		}

		if (parameter == -1) {
			parameter = 1;
		}
		if (negative) {
			parameter = -parameter;
		}

		// If this is u, then the parameter will be followed by a character.
		if (word.equals("u")) {
			// Ignore space delimiter.
			if (tchar == ' ') {
				getChar();
			}

			// If the replacement character is encoded as hexadecimal value \'hh
			// then jump over it.
			if (tchar == '\\' && rtf.charAt(pos) == '\'') {
				pos += 3;
			}

			// Convert to UTF unsigned decimal code.
			if (negative) {
				parameter += 65536;
			}
		}
		// If the current character is a space, then it is a delimiter. It is
		// consumed.
		// If it's not a space, then it's part of the next item in the text, so
		// put the character back.
		else {
			if (tchar != ' ') {
				pos--;
			}
		}

		RtfControlWord rtfWord = new RtfControlWord();
		rtfWord.word = word;
		rtfWord.parameter = parameter;
		group.children.add(rtfWord);
	}

	/**
	 * Gets the name and parameter of the control symbol and finally adds a new
	 * symbol element to the current group.
	 */
	protected void parseControlSymbol() {
		// Read symbol (one character only).
		getChar();
		char symbol = tchar;

		// Symbols ordinarily have no parameter. However, if this is \', then it
		// is followed by a 2-digit hex-code.
		int parameter = 0;
		if (symbol == '\'') {
			getChar();
			String firstChar = tchar + "";
			getChar();
			String secondChar = tchar + "";
			parameter = hexdec(firstChar + secondChar);
		}

		RtfControlSymbol rtfSymbol = new RtfControlSymbol();
		rtfSymbol.symbol = symbol;
		rtfSymbol.parameter = parameter;
		group.children.add(rtfSymbol);
	}

	/**
	 * Reads the next character from the string and identifies it as start of a
	 * control word or control symbol.
	 */
	protected void parseControl() {
		// Beginning of an RTF control word or control symbol.
		// Look ahead by one character to see if it starts with a letter
		// (control word) or another symbol (control symbol).
		getChar();
		pos--;
		if (isLetter()) {
			parseControlWord();
		} else {
			parseControlSymbol();
		}
	}

	/**
	 * Iteratively reads the next characters from the string and handles them as
	 * plain text. Finally, a new text element is added to the current group.
	 *
	 * @throws RtfParseException
	 *             is thrown if errors occur when parsing RTF strings
	 */
	protected void parseText() throws RtfParseException {
		// Parse plain text up to backslash or brace, unless escaped.
		String text = "";
		boolean terminate = false;

		do {
			terminate = false;

			// Is this an escape?
			if (tchar == '\\') {
				// Perform lookahead to see if this is really an escape
				// sequence.
				getChar();
				switch (tchar) {
				case '\\':
				case '{':
				case '}':
					break;
				default:
					// Not an escape. Roll back.
					pos -= 2;
					terminate = true;
					break;
				}
			} else if (tchar == '{' || tchar == '}') {
				pos--;
				terminate = true;
			}

			if (!terminate) {
				text += tchar;
				getChar();
			}
		} while (!terminate && pos < len);

		RtfText rtfText = new RtfText();
		rtfText.text = text;

		// If group does not exist, then this is not a valid RTF file. Throw an
		// exception.
		if (group == null) {
			throw new RtfParseException("Invalid RTF file.");
		}

		group.children.add(rtfText);
	}

	/**
	 * Parses RTF.
	 *
	 * @param rtfFile
	 *            local file containing the rich text
	 * @throws RtfParseException
	 *             is thrown if errors occur when parsing RTF strings
	 */
	public void parse(File rtfFile) throws RtfParseException {
		try {
			try (FileInputStream fis = new FileInputStream(rtfFile)) {
				parse(fis);
			}
		} catch (IOException e) {
			throw new RtfParseException(e.getMessage());
		}
	}

	/**
	 * Parses RTF.
	 *
	 * @param rtfStream
	 *            stream containing the rich text
	 * @throws RtfParseException
	 *             is thrown if errors occur when parsing RTF strings
	 */
	public void parse(InputStream rtfStream) throws RtfParseException {
		String rtfSource = new BufferedReader(new InputStreamReader(rtfStream)).lines()
				.collect(Collectors.joining("\n"));
		parse(rtfSource);
	}

	/**
	 * Parses RTF.
	 *
	 * @param rtfSource
	 *            string containing the rich text
	 * @throws RtfParseException
	 *             is thrown if errors occur when parsing RTF strings
	 */
	public void parse(String rtfSource) throws RtfParseException {
		rtf = rtfSource;
		pos = 0;
		len = rtf.length();
		group = null;
		root = null;

		while (pos < len) {
			// Read next character.
			getChar();

			// Ignore \r and \n.
			if (tchar == '\n' || tchar == '\r') {
				continue;
			}

			// What type of character is this?
			switch (tchar) {
			case '{':
				parseStartGroup();
				break;
			case '}':
				parseEndGroup();
				break;
			case '\\':
				parseControl();
				break;
			default:
				parseText();
				break;
			}
		}
	}
}
