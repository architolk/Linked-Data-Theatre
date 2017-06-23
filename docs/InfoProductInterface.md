# Information Product Interface
The information product factory creates workers that implement the information product interface. This document describes this interface.

- INPUT: An InformationProductRequest class
- OUPUT: An InformationProduct class

## Information Product Request
The information Product Request contains the following properties:

- `identifier`: (mandatory) the IRI that identifies the particular information product
- `subject`: (optional) the IRI that identifies the "subject" of an information product. In a RESTful or Linked Data dereferenceable URL, this is the URL that originally is provided by the client. This value can be used as {$SUBJECT} in a template.
- `parameters` (optional) a name-value list containing the parameters that are passed to the information product. The values can be used as {$<name>} in a template.

## Information Product
The information Product contains the following properties:

- `type`: (optional) the class/interface of the the information product. At this moment, classtype can have the values `org.eclipse.rdf4j.model.Model` (for set of triples - CONSTRUCT/DESCRIBE) or `org.eclipse.rdf4j.query.BindingSet` (for a set of tuples - SELECT/ASK). An empty values means that some error has occurred.
- `data`: (mandatory) a class that contains the data. The type should be compatible with the type set in the `type` property.
- `error`: (optional) in case of an error: a class containing the error.
    