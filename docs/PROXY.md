#Accessing remote endpoints via a proxy
If you are using the Linked Data Theatre behind a corporate firewall, changes are that the LInked Data Theatre cannot access a remote endpoint directly. Sometimes it is necessary to use a proxy server.

The Linked Data Theatre is capable of using a proxy server via the proxy-access functionality of Orbeon.
(see: [http://doc.orbeon.com/configuration/properties/index.html](http://doc.orbeon.com/configuration/properties/index.html))

## Steps
Create the file `properties-local.xml` in the directory `\WEB-INF\resources\config`. This file should look something like:

	<properties xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:oxf="http://www.orbeon.com/oxf/processors">

		<property as="xs:string" name="oxf.http.proxy.host" value="{PROXY-HOST-NAME}"/>
		<property as="xs:integer" name="oxf.http.proxy.port" value="{PROXY-PORT}"/>
		<property as="xs:string" name="oxf.http.proxy.exclude" value="127\.0\.0\.1|localhost"/>
	</properties>

Replace `{PROXY-HOST-NAME}` with the address of your proxy, and `{PROXY-PORT}` with the port number at which the proxy server listens. Optionally, you could change the proxy.exlude value. This is a regex expression that defines which address should not use the proxy (normally: any local address).

Remember to restart the server after you have made the changes.