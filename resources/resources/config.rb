# Cookbook Name:: barnyard2
#
# Resource:: config
#

actions :add, :remove, :register, :deregister
default_action :add

attribute :cores, :kind_of => Integer, :default => 1
attribute :memory_kb, :kind_of => Integer, :default => 102400
attribute :enrichment_enabled, :kind_of => [TrueClass, FalseClass], :default => true
attribute :cache_dir, :kind_of => String, :default => "/var/cache/barnyard2"
attribute :templates_dir, :kind_of => String, :default => "/var/cache/barnyard2/templates"
attribute :config_dir, :kind_of => String, :default => "/etc/barnyard2"
attribute :user, :kind_of => String, :default => "barnyard2"
attribute :sensors, :kind_of => Hash, :default => []
