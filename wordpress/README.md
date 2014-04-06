# Wordpress AWS OpsWorks cookbook
Extracts the Wordpress installation over the top of an OpsWorks app and builds the wp-config.php file.

## Usage
Include wordpress::deploy in your stack's Deploy phase run list.

If the project needs to specify additional config that would normally be in wp-config.php you can create a
file called wp-config-custom.php within the project.  This is conditionally required once after the other config has been applied.

Wordpress will only deployed if the app is listed in `['wordpress']['apps']` (array of Strings).  This allows other
non-Wordpress PHP apps to be deployed to the same node without polluting them.

### Plugins
Wordpress sites often have a lot of plugins to enable functionality.  Unfortunately, when operating in a fully automated
multi-server environment the tools used to manage WP plugins are not ideal - if the user installs/updates a plugin, how
it that then replicated the next time an instance starts?

To work around this the cookbook will install a list of plugins as part of its deployment from the stack configuration

    {
      "wordpress": {
        "apps" : [ "mywordpressappname" ],
        "plugins" : [{
	        "name" : "addthis",
            "download" : "http:://downloads.wordpress.org/plugin/addthis.3.5.9.zip"
        }]
      }
    }

If the plugins need additional config, place this in your wp-config-custom.php.

### Using a custom database
You may not want the DB to be setup within the OpsWorks stack, it might be an RDS instance or a box you manage.  By
default the cookbook will try to use the stack's database but you can switch this off by setting `use_stack_database`
false and supplying appropriate information:

    {
      "wordpress": {
        "apps" : [ "mywordpressappname" ],
        "use_stack_database" : false
        "db_name" : "somedb",
        "db_user" : "someusername",
        "db_password" : "somepassword",
        "db_host" : "somedatabasehost"
      }
    }

## Configuration
`['wordpress']['download']` - the URL of the distribution download.  Defaults to 'http://wordpress.org/latest.tar.gz'.
Override this if you need to change the location of the distribution or pin to a specific version.

`['wordpress']['apps']` - an array of application name strings that should have Wordpress installed to them.  Must match
name given in OpsWorks.

`['wordpress']['use_stack_database']` - whether to use the stack's database or a user supplied one.

`['wordpress']['db_name']` - the name of the database to use.  Only applies if `use_stack_database` is false.

`['wordpress']['db_user']` - the username to connect to the database with.  Only applies if `use_stack_database` is false.

`['wordpress']['db_password']` - the password to connect to the database with.  Only applies if `use_stack_database` is false.

`['wordpress']['db_host']` - the FQDN or IP address to use when connecting to the database.  Only applies if `use_stack_database` is false.

## License and Authors

Author:: NetSrv Consulting Ltd. (<enquiries@netsrv-consulting.com>)

    Copyright: 2014, NetSrv Consulting Ltd.
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
