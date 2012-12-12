#
# Cookbook Name:: tomcat
# Recipe:: default
#
# Copyright 2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "java"

case node.platform
when "centos","redhat","fedora"
  include_recipe "jpackage"
end

tcv = node["tomcat"]["version"] || "6"
tomcat_name = "tomcat#{tcv}"

tomcat_pkgs = value_for_platform(
  ["debian","ubuntu"] => {
    "default" => ["#{tomcat_name}","#{tomcat_name}-admin"]
  },
  ["centos","redhat","fedora"] => {
    "default" => ["#{tomcat_name}","#{tomcat_name}-admin-webapps"]
  },
  "default" => [tomcat_name]
)
tomcat_pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

service "tomcat" do
  service_name node["tomcat"]["service_name"]
  case node["platform"]
  when "centos","redhat","fedora"
    supports :restart => true, :status => true
  when "debian","ubuntu"
    supports :restart => true, :reload => true, :status => true
  end
  action [:enable, :start]
end

case node["platform"]
when "centos","redhat","fedora"
  template "/etc/sysconfig/#{node["tomcat"]["service_name"]}" do
    source "sysconfig_#{node["tomcat"]["service_name"]}.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :restart, resources(:service => "tomcat")
  end
else  
  template "/etc/default/#{node["tomcat"]["service_name"]}" do
    source "default_#{node["tomcat"]["service_name"]}.erb"
    owner "root"
    group "root"
    mode "0644"
    notifies :restart, resources(:service => "tomcat")
  end
end

template "/etc/#{node["tomcat"]["service_name"]}/server.xml" do
  source "server_#{node["tomcat"]["service_name"]}.xml.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "tomcat")
end
