# Linked Data Theatre usage
## Examples to start with
### Hello world example
Your first LDT example might look like this:

    <helloWorld> a elmo:Representation;
		elmo:url-pattern "/query/helloWorld$";
		elmo:appearance: HtmlAppearance;
		elmo:data "blub";
	.

Let's look at this example:

- The first line states that `<helloWorld>` is a Representation.
- The next line states that this representation should be used whenever the URL conforms to the regex pattern `/query/helloWorld$`.
- The third line states that this represenation should appear as an html-appearance. This means that the data is interpreted as plain html.
- The last line states that this representation contains some (static) data: the html that should be presented to the user.
### First SPARQL example
The hello-world example didn't actually uses a triple store to fetch any data. The next example will fetch all graphs from the triple store.

    <showGraphs> a elmo:Representation;
		elmo:url-pattern "/query/showGraphs$";
		elmo:query '''
			SELECT ?graph ?graph_label
			WHERE {
				?graph {
					?x?y?z.
					OPTIONAL {?graph rdfs:label ?graph_label}
				}
			}
		'''
	.

Instead of the `elmo:data` triple, an `elmo:query` triple is included. This query contains the sparql query that is executed against the triple store. You might notice that this example doesn't contain an `elmo:appearance`. The LDT will use the default appearance for a SELECT query: elmo:TableAppearance.
## Linked Data Theatre vocabulary
### Classes
#### Representation
The representation of some data
#### Appearance
The appearance for a particular representation. You should only use the predefined appearances of the Linked Data Theatre:

- TableAppearance;
- ShortTableAppearance;
- ContentAppearance;
- HeaderAppearance;
- NavbarAppearance;
- NavbarSearchAppearance;
- HiddenAppearance;
- LoginAppearance;
- CarouselAppearance;
- IndexAppearance;
- HtmlAppearance;
- GraphAppearance;
- TextAppearance;
- FormAppearance;
- GeoAppearance;
- ImageAppearance;
- ChartAppearance.

#### Fragment
A part of a representation that defines how a fragment of a representation is presented.
### Properties
#### url-pattern
The regex pattern to which a URL should conform for this representation. More than one url-pattern properties can be added. The URL should conform to at least one of the patterns.
#### applies-to
The applies-to property is used in three different ways:

- When used as a property of a Representation, it states the pattern that should match the resource description. For example: `[rdf:type owl:Class]` is a pattern that matches all resources of the type owl:Class.
- When used as a property of a Fragment, it defines the property or the variable for which the fragment is defined. For example: `elmo:applies-to rdfs:label` states that the frament is used for a rdfs:label property, and `elmo;applies-to "graph"` states that the fragement is used for the variable ?graph.
#### query
The property that defines the SPARQL query used for the representation.
#### data
Some static data.
#### contains
States that a representation contains some other representations. All containing representations will be presented below each other.
#### index
States the order in which fragments or representations are presented.