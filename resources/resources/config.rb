# Cookbook Name:: barnyard2
#
# Resource:: config
#

actions :add, :remove, :register, :deregister
default_action :add
attribute :groups, :kind_of => Array, :default => []
attribute :sensor_id, :kind_of => Integer, :default => 0 