# Content negotiation
One of the key concepts of the web is [content negotiation](https://tools.ietf.org/html/rfc2616#section-12), the practice of making available multiple representations via the same URI. From a client-side perspective, content negotiation allows the client to state which representation suite the client the best. Generally speaking, three methods are used to make such a statement:

1. Using http headers (most important: [Accept](https://tools.ietf.org/html/rfc2616#section-14.1));
2. Using an extension (like .ttl, .rdf or .jsonld);
3. Using a URL parameter (like ?format=ttl).

All methods have pre's and con's. Using http headers doesn't change the URL in any way, but this is also a con, because some clients may not be able to change the http header. Using an extension resembles a file-based approach, but changes the part of the URL that identifies a resource. Using a URL-parameter doesn't change the the identification, but the name of the parameter is not standardised in any way.

## Priority rules
The Linked Data Theatre supports all three formats. Because any http request might contain all three options, some priority-rules are necessary:

1. The extension overrules all other values. The extension is the part after the last `.`, and before a possible `#` or `?`. The extension should be from the known list of extensions.
2. If no extension is given, the format parameter overrules the http header. Only one format should be given, and it should be from the known list of extensions (see below).
3. If no extension parameter is given, the http header should be used as defined by the [Hypertext Transfer Protocol - HTTP 1.1 - Accept header](https://tools.ietf.org/html/rfc2616#section-14.1).
4. If the extension is unknown or the accept header contains an unknown mime-type, a [406 Not Acceptable](https://tools.ietf.org/html/rfc2616#section-10.4.7) http status code should be returned.
4. If the accept header is empty, or equal to `*/*` the format should be `text/html` for calls from a browser (human-to-machine) and `text/plain` for non-browser calls (machine-to-machine).

## Known formats

The following formats are known to the theatre. The accept-header values are from the [IANA Media types registry](https://www.iana.org/assignments/media-types/media-types.xhtml). The italic values are not in the IANA registry, but can be used nonetheless.

| Ext     | Accept-header                                                           | Format                           |
|---------|-------------------------------------------------------------------------|----------------------------------|
| html    | text/html                                                               | HTML representation              |
| xml     | application/xml                                                         | An appropriate XML format        |
| rdf     | application/rdf+xml                                                     | RDF/XML format                   |
| sparql  | application/sparql-results+xml                                          | XML result set format            |
| json    | application/json                                                        | An appropriate json format       |
| jsonld  | application/ld+json                                                     | JSON-LD format                   |
|         | application/sparql-results+json                                         | JSON result set format           |
| ttl     | text/turtle                                                             | RDF in turtle format             |
| txt     | text/plain                                                              | Plain text                       |
| csv     | text/csv                                                                | Comma separated values ([RFC4180](https://www.ietf.org/rfc/rfc4180.txt)) |
| xlsx    | _application/vnd.openxmlformats-officedocument.spreadsheetml.sheet_     | Microsoft Excel format           |
| docx    | _application/vnd.openxmlformats-officedocument.wordprocessingml.document_ | Microsoft Word format            |
| pdf     | application/pdf                                                         | PDF format                       |
| xmi     | application/vnd.xmi+xml                                                 | XMI format                       |
| graphml | _application/graphml+xml_                                               | Graphml                          |
| yed     | _application/x.elmo.yed_                                                | Format of the yEd editor         |
| query   |                                                                         | (Debugging) shows the query      |

An accept header of `application/xml` will result in the appropriate XML serialization: `rdf+xml` for CONSTRUCT and DESCRIBE queries, `sparql-results+xml` for SELECT and ASK queries.

An accept header of `application/json` will result in the appropriate JSON serialization: `ld+json` for CONSTRUCT and DESCRIBE queries, `sparql-results+json` for SELECT and ASK queries.

An accept header of `application/rdf+xml` or `application/ld+json` should give a [406 Not Acceptable](https://tools.ietf.org/html/rfc2616#section-10.4.7) status code for SELECT and ASK queries.

An accept header of `application/sparql-results+xml` or `application/sparql-results+json` should give a [406 Not Acceptable](https://tools.ietf.org/html/rfc2616#section-10.4.7) status code for CONSTRUCT and DESCRIBE queries.
