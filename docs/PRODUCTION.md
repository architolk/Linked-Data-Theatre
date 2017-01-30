#LDT for production environment

To deploy the LDT in a production environment, you should secure some parts of the LDT. All changes are made in the config.xml file.

**NB: Securing Tomcat is not part of this instruction, but should be done!**

###1. Hide the backstage
You probably don't want a public backstage (or your users could change the configuration of the LDT!). You have two options:

1. Delete any reference to the backstage in your config.xml;
2. Use a backstage behind a VPN.

For example, if your config.xml looks like:

	<site domain="data.mydomain.com" backstage="data.mydomain.com">
		<stage />
	</site>

To remove the backstage, change the config to:

	<site domain="data.mydomain.com">
		<stage />
	</site>

To hide the backstage behind a VPN, change the config to:

	<site domain="data.mydomain.com" backstage="backstage.mydomain.internal">
		<stage />
	</site>

(where `backstage.mydomain.internal` refers to a server behind the VPN).

###2. Set the environment to production, remove public sparql endpoint
The default config start with:

	<theatre env="dev" sparql="yes" configuration-endpoint="...

Change this to:

	<theatre env="prod" sparql="no" configuration-endpoint="...

###3. Enable caching
In production, you probably won't change the configuration itself, so you might want to enable caching of the configuration:

	<theatre env="prod" querycache="PT1H" ...

Please look into [xmlduration](http://www.w3.org/TR/xmlschema-2#duration) how to specify the cache duration.`PT1H` specifies a one hour cache.

If your data itself is static, you might enable caching for the data as well. In a scenario where you have a lot of concurrent users and a small amount of static data, this is a good practice. Please note that the amount of memory is a function of the duration multiplied by the amount of data, so don't use a high value for the duration if you have a lot of data!

	<theatre env="prod" cache="PT1M" ...

A value of one minute might be considered pretty safe. Don't use data or query cache for your development environment, or you won't see your changes! (You can check the caching setting via `http://localhost:8080/info`.