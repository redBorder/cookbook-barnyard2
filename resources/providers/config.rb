# Cookbook Name:: barnyard2
#
# Provider:: config
#

action :add do #Usually used to install and configure something
  begin
    cores = new_resource.cores
    memory_kb = new_resource.memory_kb
    enrichment_enabled = new_resource.enrichment_enabled
    cache_dir = new_resource.cache_dir
    config_dir = new_resource.config_dir
    templates_dir = new_resource.templates_dir
    user = new_resource.user
    sensors = new_resource.sensors

    chef_gem 'ruby_dig' do
      action :nothing
    end.run_action(:install)

    #User creation
    user user do
      action :create
    end

    # Directory creation
    directory config_dir do
      owner "root"
      group "root"
      mode 0755
    end

    directory cache_dir do
      owner user
      group user
      mode 0755
    end

    directory templates_dir do
      owner user
      group user
      mode 0755
    end


    # RPM Installation
    yum_package "barnyard2" do
      action :upgrade
    end

    # Memory calculation
    dns_cache_size_mb = [ memory_kb/(4*1024), 10 ].max.to_i
    buffering_max_messages = [ memory_kb/4, 1000 ].max.to_i

    # Templates
    template "/etc/sysconfig/barnyard2" do
      source "barnyard2_sysconfig.erb"
      cookbook "barnyard2"
      owner "root"
      group "root"
      mode 0644
      retries 2
      variables(  :cores => cores,
                  :enrichment_enabled => enrichment_enabled,
                  :cache_dir => cache_dir,
                  :config_file => "#{config_dir}/config.json",
                  :dns_cache_size_mb => dns_cache_size_mb,
                  :user => user,
                  :buffering_max_messages => buffering_max_messages
      )
      notifies :reload, 'service[barnyard2]', :delayed
    end

    template "#{config_dir}/config.json" do
      source "barnyard2_config.erb"
      cookbook "barnyard2"
      owner "root"
      group "root"
      mode 0644
      retries 2
      variables(:sensors => sensors)
      helpers Barnyard2::Renderer
      notifies :reload, 'service[barnyard2]', :delayed
    end

    service "barnyard2" do
      supports :status => true, :start => true, :restart => true, :reload => true, :stop => true
      action [:enable, :start]
    end

    Chef::Log.info("barnyard2 cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do #Usually used to uninstall something
  begin
    service "barnyard2" do
      supports :stop => true, :disable => true
      action [:stop, :disable]
    end

    Chef::Log.info("barnyard2 cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do #Usually used to register in consul
  begin
    if !node["barnyard2"]["registered"]
      query = {}
      query["ID"] = "barnyard2-#{node["hostname"]}"
      query["Name"] = "barnyard2"
      query["Address"] = "#{node["ipaddress"]}"
      query["Port"] = 2055
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.set["barnyard2"]["registered"] = true
    end
    Chef::Log.info("barnyard2 service has been registered in consul")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do #Usually used to deregister from consul
  begin
    if node["barnyard2"]["registered"]
      execute 'Deregister service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/deregister/barnyard2-#{node["hostname"]} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.set["barnyard2"]["registered"] = false
    end
    Chef::Log.info("barnyard2 service has been deregistered from consul")
  rescue => e
    Chef::Log.error(e.message)
  end
end