#
# Cookbook Name:: jboss7
# Recipe:: default
#
# Copyright (C) 2014 Andrew DuFour
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'apt'
include_recipe 'java'

user node['jboss7']['jboss_user'] do
  comment 'jboss User'
  home node['jboss7']['jboss_home']
  system true
  shell '/bin/false'
end

group node['jboss7']['jboss_group'] do
  action :create
end

ark 'jboss' do
  url node['jboss7']['dl_url']
  home_dir node['jboss7']['jboss_home']
  prefix_root node['jboss7']['jboss_path']
  owner node['jboss7']['jboss_user']
  version node['jboss7']['jboss_version']
end

directory node['jboss7']['log_dir'] do
  mode '0755'
  owner node['jboss7']['jboss_user']
  action :create
end

## different location for configuration files
if node['jboss7']['config_dir'] != "#{node['jboss7']['jboss_home']}/standalone/configuration"

  ## Delete the default configration folder
  directory "#{node['jboss7']['jboss_home']}/standalone/configuration" do
    recursive true
    action :delete
    # Only remove if its an actual dir
    not_if "test -L #{node['jboss7']['jboss_home']}/standalone/configuration"
  end  

  ## create special config dir
  directory node['jboss7']['config_dir'] do
    mode '0755'
    owner node['jboss7']['jboss_user']
    action :create
    recursive true
  end

  link "#{node['jboss7']['jboss_home']}/standalone/configuration" do
    to      "#{node['jboss7']['config_dir']}"
    not_if "test -L #{node['jboss7']['jboss_home']}/standalone/configuration"    
  end
  
end

template "#{node['jboss7']['config_dir']}/standalone-full.xml" do
  source 'standalone_full_xml.erb'
  owner node['jboss7']['jboss_user']
  group node['jboss7']['jboss_group']
  mode '0644'
  notifies :restart, 'service[jboss]', :delayed
end

template "#{node['jboss7']['config_dir']}/logging.properties" do
  source 'logging_properties.erb'
  owner node['jboss7']['jboss_user']
  group node['jboss7']['jboss_group']
  mode '0644'
  notifies :restart, 'service[jboss]', :delayed
end

template "#{node['jboss7']['config_dir']}/application-roles.properties" do
  source 'application_roles_properties.erb'
  owner node['jboss7']['jboss_user']
  group node['jboss7']['jboss_group']
  mode '0644'
  notifies :restart, 'service[jboss]', :delayed
end

template "#{node['jboss7']['config_dir']}/application-users.properties" do
  source 'application_users_properties.erb'
  owner node['jboss7']['jboss_user']
  group node['jboss7']['jboss_group']
  mode '0644'
  notifies :restart, 'service[jboss]', :delayed
end

template "#{node['jboss7']['config_dir']}/mgmt-groups.properties" do
  source 'mgmt_groups_properties.erb'
  owner node['jboss7']['jboss_user']
  group node['jboss7']['jboss_group']
  mode '0644'
  notifies :restart, 'service[jboss]', :delayed
end

template "#{node['jboss7']['config_dir']}/mgmt-users.properties" do
  source 'mgmt_users_properties.erb'
  owner node['jboss7']['jboss_user']
  group node['jboss7']['jboss_group']
  mode '0644'
  notifies :restart, 'service[jboss]', :delayed
end

template "#{node['jboss7']['jboss_home']}/bin/standalone.conf" do
  source 'standalone_conf.erb'
  owner node['jboss7']['jboss_user']
  group node['jboss7']['jboss_group']
  mode '0644'
  notifies :restart, "service[jboss]", :delayed
end

dist_dir, conf_dir = value_for_platform_family(
  ['debian'] => %w{ debian default },
  ['rhel'] => %w{ redhat sysconfig },
)

template '/etc/jboss-as.conf' do
  source "#{dist_dir}/jboss-as.conf.erb"
  mode 0775
  owner 'root'
  group node['root_group']
  only_if { platform_family?("rhel") }
  notifies :restart, 'service[jboss]', :delayed
end

template '/etc/init.d/jboss' do
  source "#{dist_dir}/jboss-init.erb"
  mode 0775
  owner 'root'
  group node['root_group']
  notifies :enable, 'service[jboss]', :delayed
  notifies :start, 'service[jboss]', :delayed
  notifies :restart, 'service[jboss]', :delayed
end

jboss7_user node['jboss7']['admin_user'] do
  password node['jboss7']['admin_pass']
  action :create
  notifies :restart, 'service[jboss]', :delayed
end

service 'jboss' do
  supports :restart => true
  action :nothing
end
