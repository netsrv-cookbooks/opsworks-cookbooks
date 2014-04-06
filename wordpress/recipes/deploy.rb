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
  
  # Use user supplied configuration (e.g. for RDS) and fall back to stack configured
  # Placed early so as to fail fast
  begin
    db_name     = node[:wordpress][app_name][:db_name] rescue deploy[:database][:database]
    db_user     = node[:wordpress][app_name][:db_user] rescue deploy[:database][:username]
    db_password = node[:wordpress][app_name][:db_password] rescue deploy[:database][:password]
    db_host     = node[:wordpress][app_name][:db_host] rescue deploy[:database][:host]
  rescue 
    Chef::Log.error('Cannot resolve database configuration from either stack config or user supplied data')
    Chef::Log.warn("Application (#{app_name}) may not work correctly due to configuration error")
    next
  end

  Chef::Log.info("Configuring Wordpress to connect to #{db_host}/#{db_name} as #{db_user}")
  
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

  template "#{deploy[:deploy_to]}/current/wp-config.php" do
    source "wp-config.php.erb"
    mode 0660
    group deploy[:group]
    
    if platform?("ubuntu")
      owner "www-data"
    elsif platform?("amazon")
      owner "apache"
    end
    
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
