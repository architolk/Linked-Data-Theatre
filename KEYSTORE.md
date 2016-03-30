#Accessing remote endpoints via https with unsecure certificate
If you are using the Linked Data Theatre and want to access a secure (https) endpoint, in some cases the certificate is not trusted (for example: self-signed certificates, or certificates has no chain to a trusted ROOT certificate in the default Java keystore).

The Linked Data Theatre is capable of trusting certificates in its own keystore, via the SSL functionality of Orbeon.
(see: [http://doc.orbeon.com/configuration/properties/index.html](http://doc.orbeon.com/configuration/properties/index.html) and [http://wiki.orbeon.com/forms/how-to/use-ssl-https](http://wiki.orbeon.com/forms/how-to/use-ssl-https))

## Steps
Go to the https website and export the certificate (most browsers have the option to export a certificate without trusting it). You should end up with a `.crt` file.

Import the certificate into a newly created keystore (you will be prompted to specify the password for the keystore):

	"%JAVA_HOME%/bin/keytool" -import -alias ldt -keystore ldt.jks -file {CERTIFICATE-FILENAME}

Replace `{CERTIFICATE-FILENAME}` with the name of the exported certificate file. Move the keystore file `ldt.jks` to the `\WEB-INF\resources\config` directory.

Create the file `properties-local.xml` in the directory `\WEB-INF\resources\config`. This file should look something like:

	<properties xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:oxf="http://www.orbeon.com/oxf/processors">

		<property as="xs:string" name="oxf.http.ssl.hostname-verifier" value="allow-all"/>
		<property as="xs:anyURI" name="oxf.http.ssl.keystore.uri" value="file:/{TOMCAT-DIR}/web-apps/ROOT/WEB-INF/resources/config/pdok.jks"/>
		<property as="xs:string" name="oxf.http.ssl.keystore.password" value="{PASSWORD}"/>
	</properties>

Replace `{TOMCAT-DIR}` with the path to the tomcat directory (including drive letter on windows). Replace `{PASSWORD}` with the password of the keystore.

Remember to restart the server after you have made the changes.