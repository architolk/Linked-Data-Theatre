# Linked Data Theatre
The Linked Data Theatre (LDT) is a platform for an optimal presentation of Linked Data.

### Installation and usage
The easiest way to use the LDT is to install the latest release in a Tomcat container, by following the instructions in [DEPLOY.md](docs/DEPLOY.md):

- [ldt-1.25.2.war](https://github.com/architolk/Linked-Data-Theatre/releases/download/v1.25.2/ldt-1.25.2.war "ldt-1.25.2.war")

**NB: Users that upgrade from version 1.17.0 or lower: from version 1.18.0 the LDT can work with any triplestore via the RDF4J interface. You might need to change your configuration a bit. Please look at [DEPLOY.md](docs/DEPLOY.md), sections 4.3 and 4.4.2 for further instructions.**

**NB: Users that upgrade from version 1.9.0 or lower: the config.xml has changed with release 1.10.0. Please make sure that a `<date/>` entry exists after the upgrade!**

The Linked Data Theatre uses a configuration graph containing all the triples that make up the LDT configuration. Instructions and examples how to create such a configuration can be found at the [wiki](https://github.com/architolk/Linked-Data-Theatre/wiki). A [basic-configuration](basic-configuration.ttl) is provided to get you started.

The wiki contains a [tutorial](https://github.com/architolk/Linked-Data-Theatre/wiki/Tutorial) to guide you through the most common features of the Theatre.

### Build it yourself, linux and docker installations
See [BUILD.md](docs/BUILD.md) for instructions to build the Linked Data Theatre yourself. To deploy the Linked Data Theatre in a Tomcat container, follow the instructions in [DEPLOY.md](docs/DEPLOY.md). A step-by-step installation guide for Linux is also available: [LINUX_SETUP.md](docs/LINUX_SETUP.md). You can also opt for a docker installation, see [DOCKER.md](docs/DOCKER.md).

### Advanced installation - production settings
* The default setting of the LDT is for development purposes. Read [PRODUCTION.md](docs/PRODUCTION.md) for information about securing the LDT for a production environment.

* To create linked data, the LDT can be extended with the [Linked Data Studio](https://github.com/architolk/Linked-Data-Studio) (LDS). If you install a version of the LDS, it includes a version of the LDT.

* If you want to create a new release of the LDT, please look into [BUILD-LICENSE.md](docs/BUILD-LICENSE.md) for instructions to create the approriate license headers. See [RELEASE.md](docs/RELEASE.md) for all steps to make a release, including upload to github.

* To add security to the Linked Data Theatre, follow the instructions in [SECURE.md](docs/SECURE.md).

* If you run the Linked Data Theatre behind a corporate firewall and access to the internet is restricted by a proxy, follow the instructions in [PROXY.md](docs/PROXY.md).

* If you want to access a secure endpoint (https), but the certificate is untrusted, you will have to set up a keystore. Follow the instructions in [KEYSTORE.md](docs/KEYSTORE.md).
