# Cookbook:: barnyard2
# Provider:: config

action :add do
  begin
    groups = new_resource.groups
    sensor_id = new_resource.sensor_id

    dnf_package 'barnyard2' do
      action :upgrade
      flush_cache [:before]
    end

    groups.each do |group|
      name = group['name']

      ['barnyard2'].each do |s|
        %w(reload restart stop start).each do |s_action|
          execute "#{s_action}_#{s}_#{group['instances_group']}_#{name}" do
            command "/bin/env WAIT=1 /etc/init.d/#{s} #{s_action} #{name}"
            ignore_failure true
            action :nothing
          end
        end
      end

      template "/etc/snort/#{group['instances_group']}/barnyard2.conf" do
        source 'barnyard2.conf.erb'
        cookbook 'barnyard2'
        owner 'root'
        group 'root'
        mode '0644'
        retries 2
        variables(sensor_id: sensor_id, name: name, group: group)
        notifies :run, "execute[restart_barnyard2_#{group['instances_group']}_#{name}]", :delayed
      end

      template "/etc/sysconfig/barnyard2-#{group['instances_group']}" do
        source 'barnyard2.erb'
        cookbook 'barnyard2'
        owner 'root'
        group 'root'
        mode '0644'
        retries 2
        variables(sensor_id: sensor_id, name: name, group: group)
        notifies :run, "execute[restart_barnyard2_#{group['instances_group']}_#{name}]", :delayed
      end
    end

    known_ips = {}
    node_keys = Chef::Node.list.keys.sort
    node_keys.each do |n_key|
      n = Chef::Node.load n_key
      known_ips[n['rbname']] = n['ipaddress'] if n['ipaddress'] && n['rbname']
    end

    directory '/etc/objects' do
      owner 'root'
      group 'root'
      mode '0774'
      action :create
    end

    %w(icmps interfaces hosts).each do |ob|
      objects = {}
      if node['redborder'] && node['redborder']['objects'] && node['redborder']['objects'][ob] && node['redborder']['objects'][ob].class != Chef::Node::ImmutableArray
        objects = (ob == 'hosts') ? known_ips.merge(node['redborder']['objects'][ob]) : objects = node['redborder']['objects'][ob]
      elsif ob == 'hosts'
        objects = known_ips
      end

      template "/etc/objects/#{ob}" do
        source 'objects_hosts.erb'
        cookbook 'barnyard2'
        owner 'root'
        group 'root'
        mode '0644'
        retries 2
        variables(objects: objects)
        notifies :reload, 'service[barnyard2]', :delayed
      end
    end

    %w(macs protocols services networks vlans).each do |ob|
      begin
        ob_db = data_bag_item('rBglobal', ob)
      rescue
        ob_db = nil
      end

      objects = {}
      if ob_db && ob_db['list'] && !ob_db['list'].empty?
        objects = ob_db['list']
      end

      template "/etc/objects/#{ob}" do
        source 'objects.erb'
        cookbook 'barnyard2'
        owner 'root'
        group 'root'
        mode '0644'
        retries 2
        variables(objects: objects)
        notifies :reload, 'service[barnyard2]', :delayed
      end
    end

    service 'barnyard2' do
      provider Chef::Provider::Service::Systemd
      service_name node['redborder']['barnyard2']['service']
      ignore_failure true
      supports status: true, reload: true, restart: true
      action([:start])
    end

    Chef::Log.info('barnyard2 cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    service 'barnyard2' do
      provider Chef::Provider::Service::Systemd
      service_name node['redborder']['barnyard2']['service']
      supports stop: true
      action [:stop]
    end

    Chef::Log.info('barnyard2 cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end
