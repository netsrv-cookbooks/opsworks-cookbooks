# Default configuration for the AWS OpsWorks cookbook for Wordpress
#

# Force logins via https (http://codex.wordpress.org/Administration_Over_SSL#To_Force_SSL_Logins_and_SSL_Admin_Access)
default['wordpress']['wp_config']['force_secure_logins'] = false

# Use the main WP site for distribution by default
default['wordpress']['download'] = "http://wordpress.org/latest.tar.gz"

default['wordpress']['plugins']['w3tc']['download'] = 'http://downloads.wordpress.org/plugin/w3-total-cache.0.9.4.zip'
default['wordpress']['plugins']['w3tc']['enabled'] = true

default['wordpress']['use_stack_database'] = true