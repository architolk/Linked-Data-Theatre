# Context determination

An key functionality of the Linked Data Theatre is the determination of the right context for a particular request.

The "context" of a request dermines which configuration should be used to show a particular page, use a particular API or execute a particular production.

A LDT configuration is identified by a URI. In case the configuration is stored in a triple store, a named graph with the same URI will exists that holds the whole configuration for the particular context (the set of triples with statements like `<> a elmo:Representation`, `<> a elmo:Container` or `<> a elmo:Production`).

## Basic operation
Under basis circumstances, only one LDT configuration will exist, that will be used for the whole site, for example:

`http://dotwebstack.org/stage` is used as the URI for the configuration that is used for any URI at the site `http://dotwebstack.org`.

## Multiple sites
However, one installation of the LDT can be used to handle multiple domein names ("sites") with specific configurations for each site.

_You could argue that such functionality can also be created by using a proxy server or by using multiple installations, for example: using docker containers. However, we don't want to impose unnecessary infrastructural restrictions on the use of the LDT._

From a maintanance point of view, you want a distinct separation between configurations for different sites. In some cases, it is realy necessary (for example: if you want to use the `elmo:applies-to` pattern to use a particular presentation for a particular rdfs:Class for a particular site.

### Rule for multiple sites
For any http request with pattern `http://{fqdn}:{port}/*`, a site with URI `http://{fqdn}/stage` is expected. Configurations for the site should be retrieved from the named graph `http://{fqdn}/stage`, or a file stored at the appropriate place with the name `{fqdn}.ttl`.

## Multiple stages
Within sites, you might want to differentiate between configurations. For example: your working on a local machine and still want to seperate configurations, or you are using a sandbox machine and want to dynamically create distinctive sites.

### Rule for multiple stages
For any http request with pattern http://{fqdn}:{port]/{stagename}/*, a stage with URI `http://{fqdn}/{stagename}/stage` is expected. The stage with URI `http://{fqdn}/stage` is considerd the "mainstage". Configurations for the site should be retrieved from the named graph `http://{fqdn}/{stagename}/stage` or a file stored at the appropriate place with the name {fqdn}#{stagename}.ttl`.

## Architectural considerations
The concern of determining the right configuration, should be encapsulated and restricted to a single module. This module should contain a function that excepts a http request-URI, and returns the appropriate configuration URI.

The module should only be used at the "front-end" of the architecture. The information product layer should only accept a configuration URI, and should not need to determine the configuration URI itself.

Rational: by using this approach, the decisions how to use sites and stages don't affect the remaining parts of the LDT software. A temporary function can even be used that always returns the same URI, regardless the request-URI (effectively reducing the configurations to one).