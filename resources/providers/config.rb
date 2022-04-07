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
    sensor_id = new_resource.sensor_id

    #yum_package "barnyard2" do
    #  action :upgrade
    #  flush_cache [:before]
    #end 

    groups = node["redborder"]["snort"]["groups"].keys.map{|x| x.to_i}
    used_segments = []

    node["redborder"]["snort"]["groups"].each do |id, original_group|
      group = node["redborder"]["snort"]["groups"][id].to_hash.clone
      bindings = group["bindings"].keys.map{|x| x.to_i}.flatten
      name = (group["name"].nil? ? "default" : group["name"].to_s)
      group["name"]     = name 
      group["segments"] = node["redborder"]["segments"].keys  if group["segments"].nil?
      group["cpu_list"] = 0.upto(node["cpu"]["total"]-1).to_a if group["cpu_list"].nil?
      group["cpu_list"] = (group["cpu_list"].map { |x| x.to_i }).sort.uniq
      group["segments"] = group["segments"].sort.uniq
      group["instances_group"] = id.to_i
      group["segments"] = group["segments"].select{ |x| !used_segments.include?(x) }
  
      if group["cpu_list"].size==0 or group["segments"].size==0 or group["bindings"].nil? or group["bindings"].size==0
        groups.delete(id.to_i)
      else
        used_segments = used_segments + group["segments"]
        
    
        [ "barnyard2" ].each do |s|
          [ "reload", "restart", "stop", "start" ].each do |s_action|
            execute "#{s_action}_#{s}_#{group["instances_group"]}_#{name}" do
              command "/bin/env WAIT=1 /etc/init.d/#{s} #{s_action} #{name}" 
              ignore_failure true
              action :nothing
            end
          end
        end
  
        template "/etc/snort/#{group["instances_group"]}/barnyard2.conf" do
          source "barnyard2.conf.erb"
          cookbook "barnyard2"
          owner "root"
          group "root"
          mode 0644
          retries 2
          variables(:sensor_id => sensor_id, :name => name, :group => group)
          notifies :run, "execute[restart_barnyard2_#{group["instances_group"]}_#{name}]", :delayed
        end
  
       
        template "/etc/sysconfig/barnyard2-#{group["instances_group"]}" do
          source "barnyard2.erb"
          cookbook "barnyard2"
          owner "root"
          group "root"
          mode 0644
          retries 2
          variables(:sensor_id => sensor_id, :name => name, :group => group)
          notifies :run, "execute[restart_barnyard2_#{group["instances_group"]}_#{name}]", :delayed
        end
      end
    end


    known_ips={}
    node_keys = Chef::Node.list.keys.sort
    node_keys.each do |n_key|
      n = Chef::Node.load n_key
      known_ips[n["rbname"]] = n["ipaddress"] if !n["ipaddress"].nil? and !n["rbname"].nil?
    end
    
    directory "/etc/objects" do
      owner "root"
      group "root"
      mode 0774
      action :create
    end
    
    [ "icmps", "interfaces", "hosts" ].each do |ob|
      objects={}
      if (!node["redborder"].nil? and !node["redborder"]["objects"].nil? and !node["redborder"]["objects"][ob].nil? and node["redborder"]["objects"][ob].class != Chef::Node::ImmutableArray)
        if ob=="hosts"
            objects = known_ips.merge(node["redborder"]["objects"][ob])
          else
            objects=node["redborder"]["objects"][ob]
          end
      elsif ob=="hosts"
        objects=known_ips
      end
  
      template "/etc/objects/#{ob}" do
        source "objects_hosts.erb"
        cookbook "barnyard2"
        owner "root"
        group "root"
        mode 0644
        retries 2
        variables(:objects => objects)
        notifies :reload, "service[barnyard2]", :delayed
      end
    end
    
    [ "macs", "protocols", "services", "networks", "vlans" ].each do |ob|
      ob_db = Chef::DataBagItem.load('rBglobal', ob) rescue ob_db=nil
      objects={}
      if !ob_db.nil? and !ob_db["list"].nil? and !ob_db["list"].empty?
          objects=ob_db["list"]
      end
    
      template "/opt/rb/etc/objects/#{ob}" do
        source "objects.erb"
        cookbook "barnyard2"
        owner "root"
        group "root"
        mode 0644
        retries 2
        variables(:objects => objects)
        notifies :reload, "service[barnyard2]", :delayed
      end
    end


    service "barnyard2" do
      #service_name node[:redBorder][:barnyard2][:service]
      ignore_failure true
      supports :status => true, :reload => true, :restart => true
      action([:start, :enable])
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