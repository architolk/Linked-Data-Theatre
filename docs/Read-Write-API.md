# Read-write Linked Data API
With regard to API's three standards have emerged:

- [Linked data concept itself](http://www.w3.org/DesignIssues/LinkedData.html)
- [SPARQL Graph Update](http://www.w3.org/TR/sparql11-http-rdf-update)
- [Linked Data Platform](http://www.w3.org/TR/ldp)

The Linked data concept itself states "When someone looks up a URI, provide useful information, using the standards". This implies a RESTful API for GET http operations. The concept doesn't give directions how to update Linked Data resources (http operations like PUT, POST and DELETE).

The SPARQL Graph Update protocol is part of the SPARQL1.1 standaard. It gives directions what to do when to POST, PUT or DELETE data to a named graph.

The Linked Data Platform gives directions what to do when to GET, POST, PUT or DELETE data to a resource.

As stated in the specification of the Linked Data Platform, the two standards can be used together, but some precautions must be made. The two standards differ conceptually: a named graph versus a resource.

The Read-Write Linked Data API is a proposal to create an API specification that combines the three standards.

## Linked Data concept
- `GET {URI}` returns useful information about a resource that is described by the information-resource identified by {URI}.
- `GET {URI}#{fragment}` returns useful information contained in the information-resource identified by {URI}. At least information about the resource identified by {URI}#{fragment} should be present.
- `GET {URI}` returns a 303 to the information resource that describes a non-information resource identified by {URI}.

A best practice with regard to "userful information about a resource" is the [Concise Bounded Description (CBD)](http://www.w3.org/Submission/CBD) of a resource.

A key concept is the distinction between a non-information resource and an information-resource. Non-information resources (real-life things or abstract concepts) cannot be returned via the http protocol. Non-information resources are associated with one or more information resources that describe the non-information resource.

The Linked Data concept doesn't really give directions how to access a resource that cannot be dereferenced (such as URN's). A best practice for these situations might be:

- `GET /resource?subject={URI}` returns the CBD of the resource identified by {URI}.


## SPARQL Graph Update
- `GET {URI}` returns the set of triples contained in a named graph identified by {URI}.
- `GET /{access-point}?graph={URI}` returns the set of triples contained in a named graph identified by {URI}. The access-point can be any URL.
- `PUT {URI}` replaces the content of a named graph identified by {URI}.
- `PUT /{access-point}?graph={URI}` replaces the content of a named graph identified by {URI}.
- `POST {URI}` merges the content of a named graph identified by {URI}.
- `POST /{access-point}?graph={URI}` merges the content of a named graph identified by {URI}.
- `DELETE {URI}` deletes the content of a named graph identified by {URI}.
- `DELETE /{access-point}?graph={URI}` deletes the content of a named graph identified by {URI}.

## Linked Data Platform

#### Plain resources

- `GET {URI}` returns the content of an information resource identified by {URI}.
- `PUT {URI}` replaces the content of an information resource identified by {URI}.
- `POST {URI}` merges the content of an information resource identified by {URI}.
- `DELETE {URI}` deletes the content of an information resource identified by {URI}.

#### Container resources

- `GET {URI}` returns the content of a container information resource.
- `POST {URI}` adds a new information resource (a member) to a container information resource, and returns the newly minted URI of this information resource member.

The Linked Data Platform defines three different types of containers. Some extra triples might be created, dependent on the type of container:

- Basis container: no extra triples are created;
- Direct container: an extra membership triple is created between the subject of the container (might be a non-information resource) and the newly created container;
- Indirect container: an extra membership triple is created between the subject of the container (might be a non-information resource) and a member related resource (might be a non-information resource, different from the original member URI).
