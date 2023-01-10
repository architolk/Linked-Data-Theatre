package nl.architolk.ldt.rtf;

import java.util.ArrayList;
import java.util.List;

/**
 * This class represents an RTF group in the element tree.
 *
 * @author <a href="mailto:acsf.dev@gmail.com">Kay Schröer</a>
 */
public class RtfGroup extends RtfElement {
	/**
	 * Instance of the parent group element
	 */
	public RtfGroup parent;

	/**
	 * List of child elements (group, control word, control symbol, text)
	 */
	public List<RtfElement> children;

	/**
	 * Creates a new group element.
	 */
	public RtfGroup() {
		parent = null;
		children = new ArrayList<>();
	}

	/**
	 * Gets the group type.
	 *
	 * @return control word of the first child as type or an empty string if
	 *         there are no children or the first child is not a control word
	 */
	public String getType() {
		// No children?
		if (children.isEmpty()) {
			return "";
		}

		// First child not a control word?
		RtfElement child = children.get(0);
		if (!(child instanceof RtfControlWord)) {
			return "";
		}

		return ((RtfControlWord) child).word;
	}

	/**
	 * Checks if the group is a destination.
	 *
	 * @return {@code true} if a certain control word is referred
	 */
	public boolean isDestination() {
		// No children?
		if (children.isEmpty()) {
			return false;
		}

		// First child not a control symbol?
		RtfElement child = children.get(0);
		if (!(child instanceof RtfControlSymbol)) {
			return false;
		}

		return ((RtfControlSymbol) child).symbol == '*';
	}

	/**
	 * Outputs debug information.
	 */
	public void dump() {
		dump(0);
	}

	/*
	 * (non-Javadoc)
	 *
	 * @see org.rtf.RtfElement#dump(int)
	 */
	@Override
	public void dump(int level) {
		System.out.println("<div>");
		indent(level);
		System.out.println("{");
		System.out.println("</div>");

		for (RtfElement child : children) {
			if (child instanceof RtfGroup) {
				RtfGroup group = (RtfGroup) child;

				// Can we ignore this group?
				if (group.getType().equals("fonttbl")) {
					continue;
				}
				if (group.getType().equals("colortbl")) {
					continue;
				}
				if (group.getType().equals("stylesheet")) {
					continue;
				}
				if (group.getType().equals("info")) {
					continue;
				}

				// Skip any pictures and destinations.
				if (group.getType().length() >= 4 && group.getType().substring(0, 4).equals("pict")) {
					continue;
				}
				if (group.isDestination()) {
					continue;
				}
			}

			child.dump(level + 2);
		}

		System.out.println("<div>");
		indent(level);
		System.out.println("}");
		System.out.println("</div>");
	}
}
