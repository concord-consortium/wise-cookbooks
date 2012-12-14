# Cookbook Name:: wise4
# Recipe:: default
#
# Copyright (C) 2012 The Concord Consortium

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

include_recipe "mysql::server"
include_recipe "tomcat"
include_recipe "ant"

# TODO: We should get Maven and BUILD FORM SOURCE working again.

# http://serverfault.com/questions/407818/overriding-attributes-with-chef-solo
# include_recipe "maven"  #Todo maven isn't installing 404 errors.

include_recipe "git"

script "set locale and timezone" do
  interpreter "bash"
  user "root"
  code <<-EOH
  locale-gen en_US.UTF-8
  /usr/sbin/update-locale LANG=en_US.UTF-8
  cp /usr/share/zoneinfo/right/America/New_York /etc/localtime
  EOH
end


template "#{node["tomcat"]["config_dir"]}/context.xml" do
  source "context.xml.erb"
  owner node["tomcat"]["user"]
  group node["tomcat"]["user"]
  mode "0644"
  notifies :restart, resources(:service => "tomcat")
end


%w{curriculum studentuploads}.each do |dir|
  directory "#{node["tomcat"]["webapp_dir"]}/#{dir}" do
     mode 0775
     owner node["tomcat"]["user"]
     group node["tomcat"]["user"]
     action :create
     recursive true
  end
end

# create a directory for the wise4 source checkouts
WISE4_SRC_PATH = "/home/vagrant/src"
directory WISE4_SRC_PATH do
   mode 0775
   owner "vagrant"
   group "vagrant"
   action :create
   recursive true
end


if (node["build_wise_from_source"])
    git "WISE4 sail.p:trunk:portal" do
    repository "git://github.com/concord-consortium/WISE-Portal.git"
    reference "master"
    destination "#{WISE4_SRC_PATH}/portal"
    user "vagrant"
    group "vagrant"
    action :sync
  end

  git "WISE4 sail-web:trunk:vlewrapper" do
    repository "https://github.com/WISE-Community/WISE-VLE.git"
    reference "master"
    destination "#{WISE4_SRC_PATH}/vlewrapper"
    user "vagrant"
    group "vagrant"
    action :sync
  end

  build_webapps = {'portal' => 'webapp', 'vlewrapper' => 'vlewrapper'}
  build_webapps.each do |dir, war_name|

    script "build #{dir}:#{war_name}.war with maven and install" do
      interpreter "bash"
      user "vagrant"
      cwd "#{WISE4_SRC_PATH}/#{dir}"
      code "mvn -Dmaven.test.skip=true package"
    end

    script "install war file for #{war_name}" do
      interpreter "bash"
      user node["tomcat"]["version"]
      code "cp #{WISE4_SRC_PATH}/#{dir}/target/#{war_name}.war #{node["tomcat"]["webapp_dir"]}"
    end
  end
else  #for a binary build:
  puts "Using binary build of WISE4 set BUILD_WISE_FROM_SOURCE in your environment to build from source"
  # unfortunately, its often much easier just to do this:
  webapps = node["wise4"]["web_apps"]
  webapps.each do |name, url|
    puts "doanloading #{name}from #{url}"
    remote_file "#{node["tomcat"]["webapp_dir"]}/#{name}.war" do
      owner node["tomcat"]["user"]
      source url
      mode "0644"
      not_if { File.directory? "#{node["tomcat"]["webapp_dir"]}/#{name}" }
    end
  end
end


# need to force a catalina restart so the wars get exploded
service "tomcat" do
  action :restart
end

# we need to pause here for a while.
# Shouldn't need this; but we do.
execute "wait for tomcat to restart" do
  command "sleep 30"
end

service "tomcat" do
  action :stop
end

# we need to pause here for a while.
# Shouldn't need this; but we do.
execute "wait for tomcat to stop" do
  command "sleep 10"
end


##
## TODO: Make this more portable
##  Change ownership of the vlewrapper/vle/node folder 
## to be owned bynode["wise4"]["dev_user"]
##
execute "give Wise4 Dev user permission to write vle/node directory" do
  command "sudo chown -R #{node["wise4"]["dev_user"]} #{node["tomcat"]["webapp_dir"]}/vlewrapper/vle/node"
end


template "#{node["tomcat"]["webapp_dir"]}/webapp/WEB-INF/classes/portal.properties" do
  source "portal.properties.erb"
  owner node["tomcat"]["user"]
  group node["tomcat"]["user"]
  mode "0644"
end

template "#{node["tomcat"]["webapp_dir"]}/vlewrapper/WEB-INF/classes/vle.properties" do
  source "vle.properties.erb"
  owner node["tomcat"]["user"]
  group node["tomcat"]["user"]
  mode "0644"
end

template "/home/#{node["wise4"]["dev_user"]}/backup.sh" do
  source "backup.sh.erb"
  owner node["wise4"]["dev_user"]
  group node["wise4"]["dev_user"]
  mode "0755"
end

template "/home/#{node["wise4"]["dev_user"]}/restore.sh" do
  source "restore.sh.erb"
  owner node["wise4"]["dev_user"]
  group node["wise4"]["dev_user"]
  mode "0755"
end

execute "create wise4user user" do
  user = node["wise4"]["db_user"]
  pass = node["wise4"]["db_pass"]
  command "/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} -e \"CREATE USER '#{user}'@'localhost' identified by '#{pass}'\""
  only_if { `/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} -D mysql -r -B -N -e "SELECT COUNT(*) FROM user where User='#{user}' and Host = 'localhost'"`.to_i == 0 }
end

execute "create application_production databases" do
  not_if { File.exists? '/home/vagrant/made_databases'}
  user = node["wise4"]["db_user"]
  pass = node["wise4"]["db_pass"]
  sql= <<-SQL
    drop database if exists sail_database;
    create database sail_database;
    grant all privileges on sail_database.* to '#{user}'@'localhost' identified by '#{pass}';
    drop database if exists vle_database;
    create database vle_database;
    grant all privileges on vle_database.* to '#{user}'@'localhost' identified by '#{pass}';
    flush privileges;
  SQL
  # using commandline here instead of mysql recipe because that doesn't support for queries outside of databases
  command "mysql -u root -p#{node[:mysql][:server_root_password]} -e\"#{sql}\" && touch /home/vagrant/made_databases"
  creates "/home/vagrant/made_databases"
end

execute "create-sail_database-schemas" do
  not_if { File.exists? '/home/vagrant/made_sail_schema'}
  cwd "#{node["tomcat"]["webapp_dir"]}/webapp/WEB-INF/classes/tels"
  command "mysql sail_database -u root -p#{node[:mysql][:server_root_password]} < wise4-createtables.sql && touch /home/vagrant/made_sail_schema"
  creates "/home/vagrant/made_sail_schema"
end

execute "insert-default-values-into-sail_database" do
  not_if { File.exists? '/home/vagrant/made_sail_data'}
  cwd "#{node["tomcat"]["webapp_dir"]}/webapp/WEB-INF/classes/tels"
  command "mysql sail_database -u root -p#{node[:mysql][:server_root_password]} < wise4-initial-data.sql  && touch /home/vagrant/made_sail_data"
  creates "/home/vagrant/made_sail_data"
end

# restart tomcat after DB changes? sure.
service "tomcat" do
  action :restart
end
