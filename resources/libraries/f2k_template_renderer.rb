module Barnyard2
	module Renderer

		def config_hash(flow_nodes)

	                require 'ruby_dig'

			config = { "sensors_networks" => {} }

			flow_nodes.each do |flow_node|
			node_info = Chef::Node.load(flow_node.at(0))

				if !node_info.nil? and !node_info[:ipaddress].nil? and node_info["redborder"]["parent_id"].nil?
					config["sensors_networks"][node_info[:ipaddress]] = 
							{} if config["sensors_networks"][node_info[:ipaddress]].nil?

					observation = {}
					observation["enrichment"] = {}				

					observation["enrichment"]["index_partitions"] = 
						node_info.dig("redborder", "index_partitions").nil? ? 5 : node_info["redborder"]["index_partitions"]
					observation["enrichment"]["index_replicas"] = 
						node_info.dig("redborder", "index_replicas").nil? ? 1 : node_info["redborder"]["index_replicas"]

					observation["enrichment"]["sensor_ip"] = node_info[:ipaddress].to_s
					observation["enrichment"]["sensor_name"] = node_info["rbname"].nil? ? node_info.name : node_info["rbname"]

					["sensor_uuid", "deployment", "deployment_uuid", "namespace", "namespace_uuid", "market", "market_uuid", 
						"organization", "organization_uuid", "service_provider", "service_provider_uuid", "campus", 
						"campus_uuid", "building", "building_uuid", "floor", "floor_uuid" ].each do |ss|
	          observation["enrichment"][ss] = 
	          	node_info["redborder"][ss] if !node_info["redborder"][ss].nil? and node_info["redborder"][ss]!=""
	        end

	        observation["span_port"] = 
	        	( !node_info["redborder"]["spanport"].nil? and node_info["redborder"]["spanport"].to_i==1 ) ? true : false
		      observation["exporter_in_wan_side"] = true
		      observation["dns_ptr_target"] = ( !node_info["redborder"]["dns_ptr_target"].nil? and node_info["redborder"]["dns_ptr_target"].to_i==1 ) ? true : false
	      	observation["dns_ptr_client"] = ( !node_info["redborder"]["dns_ptr_target"].nil? and node_info["redborder"]["dns_ptr_client"].to_i==1 ) ? true : false

	 	      observation["home_nets"] = []
	      	node_info["redborder"]["homenets"].each do |x|
	        	observation["home_nets"] << { "network" => x["value"], "network_name" => x["name"] }
	      	end unless node_info["redborder"]["homenets"].nil?

					observation["routers_macs"] = []
	      	node_info["redborder"]["routers_macs"].each do |x|
	        	observation["routers_macs"] << x["value"]
	      	end unless node_info["redborder"]["routers_macs"].nil?

					config["sensors_networks"][node_info[:ipaddress]]["observations_id"] = 
							{} if config["sensors_networks"][node_info[:ipaddress]]["observations_id"].nil?
        		config["sensors_networks"][node_info[:ipaddress]]["observations_id"][(node_info["redborder"]["observation_id"].nil? or 
        				node_info["redborder"]["observation_id"]=="")? "default" : node_info["redborder"]["observation_id"]] = observation
	      end
			end

			return config
		end
	end
end
