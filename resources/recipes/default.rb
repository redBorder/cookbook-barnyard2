#
# Cookbook Name:: barnyard2
# Recipe:: default
#
# Copyright 2017, redborder
#
# AFFERO GENERAL PUBLIC LICENSE, Version 3
#

barnyard2_config "config" do
	sensors node["redborder"]["sensors_info"]["flow-sensor"]
  action :add
end
