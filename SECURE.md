#Adding security to the Linked Data Theatre

The Linked Data Theatre supports authentication and autorisation. It uses the regular authentication mechanism of Tomcat or any web application server.

Three steps are necessary to add security to the Linked Data Theatre:

1. Add security definition in web.xml;
2. Add roles to defaults.xml;
3. (Optional) add role to a container.
4. Add usernames and roles to tomcat-users.xml.
5. Configure login, login-error and exit representations.

## Add security definition in web.xml

Open /WEB-INF/web.xml. This file should already have some security-settings, but they'll be commented out. Add the following lines at this point:

    <security-constraint>
        <web-resource-collection>
            <web-resource-name>Admin</web-resource-name>
            <url-pattern>/admin/*</url-pattern>
        </web-resource-collection>
        <auth-constraint>
            <role-name>admin</role-name>
        </auth-constraint>
    </security-constraint>
    <login-config>
        <auth-method>FORM</auth-method>
        <form-login-config>
            <form-login-page>/login</form-login-page>
            <form-error-page>/login-error</form-error-page>
        </form-login-config>
    </login-config>
    <security-role>
        <role-name>admin</role-name>
    </security-role>

The `<url-pattern>` defines which role can access which URLs. The default in this file creates a security context for all URLs beginnen with `/admin`. You could add your own security contexts. Please notice that Tomcat will process this configuration from top to bottom, and will stop at the first security contraint that matches the URL.

The other part of this configuration is necessary for the security to work, please don't change these lines.

## Add roles to defaults.xml

Open /WEB-INF/resource/apps/ldt/defaults.xml, and add some roles to the configuration, for example:

	<roles>
		<role>admin</role>
	</roles>

Add role to a container

You could add a role to a container. This will ensure that only authorized users with the corresponding role can access the container (read and/or write). Container security is handled by the Linked Data Theatre, but you need to have access restricted (step one). If you don't you will always get a 403 not allowed error, because the credentials will not be set.

Add the following triple to you container configuration:

	elmo:user-role "{role}".

Replace `{role}` with your own role, and don't forget to include this role in the web.xml and defaults.xml files.

## Add usernames and roles to tomcat-users.xml

If you use tomcat, you should add the names and roles of users to the tomcat-users.xml file. Open /conf/tomcat-users.xml and add something like:

	<role rolename="admin"/>
	<user username="admin" password="{some secret}" roles="admin"/>

##Configure login, login-error and exit representations

You have to create your own representations for the login, login-error and exit pages. The examples contain some default configurations:

- [login](examples\tutorials\login.ttl);
- [login-error](examples\tutorials\login-error.ttl);
- [exit](examples\tutorials\exit.ttl).


You can change these configurations as you like, but keep in mind that the URL of these representations should remain as they are given in the examples!