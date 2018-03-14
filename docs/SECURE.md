# Adding security to the Linked Data Theatre

The Linked Data Theatre supports authentication and autorisation. It uses the regular authentication mechanism of Tomcat or any web application server.

**IMPORTANT: Due to the way Tomcat implements security, it is NOT possible to add security if a proxy is used which changes the URL. This means that in most cases where the docroot is NOT empty, security won't work.**

If you're in the unlucky situation as described above, please change your proxy settings or implement security as part of your proxy.

Three steps are necessary to add security to the Linked Data Theatre:

1. Secure the backstage
2. Add security definition in web.xml;
3. Add roles to config.xml;
4. Add usernames and roles to tomcat-users.xml.
5. (Optional) add role to a container.
6. (Optional) configure login, login-error and exit representations.

## 1. Secure the backstage

In most production cases, you won't have a public backstage. See [SECURE.md](SECURE.md) for more information to hide the public backstage.

In case you want a secure backstage (public or hidden behind a VPN, see [SECURE.md](SECURE.md)), you should perform the following steps:

Look at web.xml for the security definition. The mainstage backstage is secured by default:

	<security-constraint>
        <web-resource-collection>
            <web-resource-name>Backstage</web-resource-name>
            <url-pattern>/backstage/*</url-pattern>
        </web-resource-collection>
        <auth-constraint>
            <role-name>backstageadmin</role-name>
        </auth-constraint>
    </security-constraint>

Create a user with the role `backstageadmin` in your user administration. If you use a default Tomcat installation, this means adding some data in the file `tomcat-users.xml`:

	<role rolename="backstageadmin"/>
	<user username="stagemanager@localhost" password="changeit" roles="backstageadmin"/>

In this example, a user with username "stagemanager" is given the password "changeit". Please notice the use of `@localhost`: the login will automatically add the domainname behind the username entered by the user. You can override this by entering the full username. 

## 2. Add security definition in web.xml

Open /WEB-INF/web.xml. This file should already have some security-settings for the backstage (see above). Add the following lines at this point:

    <security-constraint>
        <web-resource-collection>
            <web-resource-name>Admin</web-resource-name>
            <url-pattern>/admin/*</url-pattern>
        </web-resource-collection>
        <auth-constraint>
            <role-name>admin</role-name>
        </auth-constraint>
    </security-constraint>

The `<url-pattern>` defines which role can access which URLs. The default in this file creates a security context for all URLs beginning with `/admin`. You could add your own security contexts. Please notice that Tomcat will process this configuration from top to bottom, and will stop at the first security contraint that matches the URL.

The other part of this configuration is necessary for the security to work, please don't change these lines.

## 3. Add roles to config.xml

Open /WEB-INF/resource/apps/ldt/config.xml, and add some roles to the configuration, for example:

	<roles>
		<role>admin</role>
	</roles>

## 4. Add usernames and roles to tomcat-users.xml

If you use tomcat, you should add the names and roles of users to the tomcat-users.xml file. Open /conf/tomcat-users.xml and add something like:

	<role rolename="admin"/>
	<user username="admin@localhost" password="{some secret}" roles="admin"/>

Important: the LDT will add a "@{servername}" postfix after the username. So when you configure tomcat-users.xml please add this postfix with the servername you are using. At the login page, a user doesn't have to add this postfix for his/her username.

## 5. Optional: add role to a container

You could add a role to a container. This will ensure that only authorized users with the corresponding role can access the container (read and/or write). Container security is handled by the Linked Data Theatre, but you need to have access restricted (step one). If you don't you will always get a 403 not allowed error, because the credentials will not be set.

Add the following triple to you container configuration:

	elmo:user-role "{role}".

Replace `{role}` with your own role, and don't forget to include this role in the web.xml and config.xml files.

## 6. Optional: configure login, login-error and exit representations

The LDT is equiped with standard pages for login, error and exit. These pages are not part of your configuration, but exists as part of the LDT war. To change the appearance of these pages, you should change the files after you have unpacked the war.

The files are available in the [/ldt/representations](https://github.com/architolk/Linked-Data-Theatre/tree/master/src/main/webapp/WEB-INF/resources/apps/ldt/representations) directory.