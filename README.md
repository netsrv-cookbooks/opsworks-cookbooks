# Wordpress AWS OpsWorks cookbook
Extracts the Wordpress installation over the top of an OpsWorks app and builds the wp-config.php file.

## Usage
Include wordpress::deploy in your stack's Deploy phase run list.

If the project needs to specify additional config that would normally be place in wp-config.php you can create a
file called wp-config-custom.php.  This is conditionally required once after the other config has been applied.

Wordpress will only deployed if the app is listed in `['wordpress']['apps']` (array of Strings).  This allows other
non-Wordpress PHP apps to be deployed to the same node without polluting them.

## Configuration
`['wordpress']['download']` - the URL of the distribution download.  Defaults to 'http://wordpress.org/latest.tar.gz'.
Override this if you need to change the location of the distribution or pin to a specific version.

`['wordpress']['apps']` - an array of application name strings that should have Wordpress installed to them.  Must match
name given in OpsWorks.

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
