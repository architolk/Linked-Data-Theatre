# Linked Data Theatre usage
This documents gives a tutorial and a reference manual to the Linked Data Theatre vocabulary. All examples are also included in the /examples folder.
## Examples to start with
All examples use the following prefixes:

	PREFIX elmo: <http://bp4mc2.org/elmo/def#>
	PREFIX html: <http://www.w3.org/1999/xhtml/vocab#>
	PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> 

### Hello world example
Your first LDT example might look like this:

	<helloWorld> a elmo:Representation;
		elmo:url-pattern "/query/helloWorld$";
		elmo:appearance elmo:HtmlAppearance;
		elmo:data [
			rdfs:label "Hello World";
			elmo:html '''
				<h3>Hello World!</h3>
				<p>This is the first of the Linked Data Theatre examples.</p>
			''';
		]
	.

Let's look at this example:

- The first line states that `<helloWorld>` is a Representation.
- The next line states that this representation should be used whenever the URL conforms to the regex pattern `/query/helloWorld$`.
- The third line states that this represenation should appear as an html-appearance. This means that the data is interpreted as plain html.
- The last lines state that this representation contains some (static) data: the html that should be presented to the user.

### First SPARQL example
The hello-world example didn't actually uses a triple store to fetch any data. The next example will fetch all graphs from the triple store.

	<showGraphs> a elmo:Representation;
		elmo:url-pattern "/query/showGraphs$";
		elmo:query '''
			SELECT DISTINCT ?graph count(?x) as ?tripleCount
			WHERE {
				GRAPH ?graph {
					?x?y?z
				}
			}
		''';
	.

Instead of the `elmo:data` triple, an `elmo:query` triple is included. This query contains the sparql query that is executed against the triple store. You might notice that this example doesn't contain an `elmo:appearance`. The LDT will use the default appearance for a SELECT query: elmo:TableAppearance.

### Changing the header of a table
The Linked Data Theatre uses the names of the variables to display the table headers. You might change this, or even include multiple languages.

	<showGraphs2> a elmo:Representation;
		elmo:url-pattern "/query/showGraphs2$";
		elmo:fragment [
			elmo:applies-to "graph";
			rdfs:label "RDF Graaf"@nl;
			rdfs:label "RDF Graph"@en
		];
		elmo:fragment [
			elmo:applies-to "tripleCount";
			rdfs:label "Aantal triples"@nl;
			rdfs:label "Triple count"@en
		];
		elmo:query '''
			SELECT DISTINCT ?graph count(?x) as ?tripleCount
			WHERE {
				GRAPH ?graph {
					?x?y?z
				}
			}
		''';
	.

You'll notice the inclusion of two elmo:fragment statements. These statements are pretty self-explaining: the first line states to which variable the fragment should apply, the next two lines state the label for the header, in English and in Dutch.

### Using a different SPARQL endpoint
The Linked Data Theatre is capable of accessing any available SPARQL endpoint (if the server has the appropriate connection). The remaining of our examples will use the data of the DBPedia endpoint.

	<dbpedia> a elmo:Representation;
		elmo:url-pattern "/query/dbpedia$";
		elmo:endpoint <http://dbpedia.org/sparql>;
		elmo:query '''
			SELECT DISTINCT ?type
			WHERE {
				?s rdf:type ?type.
			}
			LIMIT 100
		''';
	.
The `elmo:endpoint` statement is used to indicate the remote SPARQL endpoint.

### Representing data of one resource
It is quite common to only show data of one resource. You can use a CONSTRUCT query for such situations. You can also use special URI-parameters to include in you statement. `@SUBJECT@` will always contain the URI of the subject resource, and `@LANGUAGE@` the current language of the user (as configured in the user's browser). Other parameters are accessible by simple using the pattern `@<parameter name in capitals>@`. The following example returns all available triples about the city of Amersfoort in DBPedia.

	<amersfoort> a elmo:Representation;
		elmo:url-pattern "/query/amersfoort";
		elmo:endpoint <http://dbpedia.org/sparql>;
		elmo:query '''
			CONSTRUCT {
				<http://dbpedia.org/resource/Amersfoort> ?p ?o
			}
			WHERE {
				<http://dbpedia.org/resource/Amersfoort> ?p ?o
			}
		'''
	.

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

#### html
States that the object contains a string with html formatting. This property should be used with a HtmlAppearance.