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
