# AWS OpsWorks Recipe for Wordpress to be executed during the Deploy lifecycle phase
# - Creates the config file wp-config.php with MySQL data.
# - Creates a Cronjob.
# - Imports a database backup if it exists.

require 'uri'
require 'net/http'
require 'net/https'

uri = URI.parse("https://api.wordpress.org/secret-key/1.1/salt/")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
request = Net::HTTP::Get.new(uri.request_uri)
response = http.request(request)
keys = response.body

wp_tarball = "/usr/src/wordpress.tar.gz"

remote_file 'fetch Wordpress tarball' do
  action :create_if_missing
  source node[:wordpress][:download]
  path wp_tarball
  mode 0644
end

node[:deploy].each do |app_name, deploy|
  
  if deploy[:application_type] != 'php'
    Chef::Log.info("Skipping wordpress::deploy for #{app_name} as it is not a PHP app")
    next
  end
  
  # Allow non-Wordpress PHP to be deployed on the same instance
  configured_apps = node[:wordpress][:apps] rescue []
  unless configured_apps.include?(app_name)
    Chef::Log.info("Skipping wordpress::deploy for #{app_name} as it has not been identified as a Wordpress installation")
    next
  end
  
  if node[:wordpress][:use_stack_database]
    # For when a database layer is added to the stack
    Chef::Log.info('Using stack database')
    db_name = deploy[:database][:database] rescue nil
    db_user =  deploy[:database][:username] rescue nil
    db_password = deploy[:database][:password] rescue nil
    db_host = deploy[:database][:host] rescue nil
  else
    # For when an external DB is used (e.g. RDS, self-hosted, etc)
    Chef::Log.info('Using external database')
    db_name = node[:wordpress][:db_name] rescue nil
    db_user = node[:wordpress][:db_user] rescue nil
    db_password = node[:wordpress][:db_password] rescue nil
    db_host = node[:wordpress][:db_host] rescue nil
  end
  
  # Check we have everything we need
  raise 'Database name cannot be empty.' if db_name.empty?
  raise 'Database username cannot be empty.' if db_user.empty?
  raise 'Database password cannot be empty.' if db_password.empty?
  raise 'Database host cannot be empty.' if db_host.empty?

  Chef::Log.info("Wordpress database: #{db_host}/#{db_name} connecting as #{db_user}")
  
  bash "extract wordpress to #{deploy[:deploy_to]}/current" do
    code <<-EOH
      tmpdir="$(mktemp -d)"
      cd $tmpdir
      tar xzf #{wp_tarball}
      cp -R --no-clobber wordpress/* #{deploy[:deploy_to]}/current
      rm -Rf $tmpdir
    EOH
  end
  
  node['wordpress']['plugins'].each do |plugin_name, plugin|

    remote_file "/usr/src/plugin_#{plugin_name}.zip" do
      action :create_if_missing
      source plugin[:download]
    end

    execute "extract plugin #{plugin_name} to #{deploy[:deploy_to]}/current" do
      # Overwrite without prompting
      command "unzip -o /usr/src/plugin_#{plugin_name}.zip"
      cwd "#{deploy[:deploy_to]}/current/wp-content/plugins"
    end

  end

  if platform?("ubuntu")
    httpuser = "www-data"
  elsif platform?("amazon")
    httpuser = "apache"
  end
  
  bash 'set permissions' do
    code <<-EOH
      # Reset all ownership
      chown -R root.root #{deploy[:deploy_to]}/current/
      find #{deploy[:deploy_to]}/current/ -type d -exec chmod 755 {} \;
      find #{deploy[:deploy_to]}/current/ -type f -exec chmod 644 {} \;
      
      # Allow web server to write user supplied content
      chown -R #{httpuser} #{deploy[:deploy_to]}/current/wp-content/
      
      # Prevent update to theme and plugins
      chown -R root #{deploy[:deploy_to]}/current/wp-content/themes
      chown -R root #{deploy[:deploy_to]}/current/wp-content/plugins
    EOH
  end
  
  template "#{deploy[:deploy_to]}/current/wp-config.php" do
    source "wp-config.php.erb"
    mode 0640
    owner 'root'
    group httpuser
    variables(
      :database   => db_name,
      :user       => db_user,
      :password   => db_password,
      :host       => db_host,
      :keys       => (keys rescue nil)
    )
  end
  
  cron 'wordpress' do
    hour '*'
    minute '*/15'
    weekday '*'
    command "wget -q -O - http://#{deploy[:domains].first}/wp-cron.php?doing_wp_cron >/dev/null 2>&1"
  end
  
end
