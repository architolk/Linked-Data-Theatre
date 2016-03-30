# Linked Data Theatre
The Linked Data Theatre (LDT) is a platform for an optimal presentation of Linked Data

See [BUILD.md](BUILD.md) for instructions to build the Linked Data Theatre. You can also try one of the releases:

- [ldt-1.6.0.war](https://github.com/architolk/Linked-Data-Theatre/releases/download/v1.6.0/ldt-1.6.0.war "ldt-1.6.0.war")
- [ldt-1.5.0.war](https://github.com/architolk/Linked-Data-Theatre/releases/download/v1.5.0/ldt-1.5.0.war "ldt-1.5.0.war")

If you want to create a new release of the ldt, please look into [BUILD-LICENSE.md](BUILD-LICENSE.md) for instructions to create the approriate license headers. See [RELEASE.md](RELEASE.md) for all steps to make a release, including upload to github.

To deploy the Linked Data Theatre in a tomcat container, follow the instructions in [DEPLOY.md](DEPLOY.md). You can also opt for a docker installation, see [DOCKER.md](DOCKER.md).

The Linked Data Theatre uses a configuration graph containing all the triples that make up the LDT configuration. Instructions and examples how to create such a configuration can be found at the [wiki](https://github.com/architolk/Linked-Data-Theatre/wiki).

To add security to the Linked Data Theatre, follow the instructions in [SECURE.md](SECURE.md).

If you run the Linked Data Theatre behind a corporate firewall and access to the internet is restricted by a proxy, follow the instructions in [PROXY.md](PROXY.md).

If you want to access a secure endpoint (https), but the certificate is untrusted, you have to setup a keystore, follow the instructions in [KEYSTORE.md](KEYSTORE.md).