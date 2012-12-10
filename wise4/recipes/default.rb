
include_recipe "mysql::server"
include_recipe "tomcat"
include_recipe "ant"
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

# Item 2
template "#{node["tomcat"]["config_dir"]}/context.xml" do
  source "context.xml.erb"
  owner node["tomcat"]["user"]
  group node["tomcat"]["user"]
  mode "0644"
  notifies :restart, resources(:service => "tomcat")
end

# Item 3 is specified in Vagrant file 



# Item 4
# this assumes the default CATALAINA_BASE location
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
    git "WISE4 sailportal:trunk:portal" do
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
  puts "Using binary build of WISE4 unset BUILD_WISE_FROM_SOURCE in your environment to build from source"
  # unfortunately, its often much easier just to do this:
  downloaded_webapps = {'webapp' => '4.5', 'vlewrapper' => '4.5'}
  downloaded_webapps.each do |base, suffix|
    remote_file "#{node["tomcat"]["webapp_dir"]}/#{base}.war" do
      owner node["tomcat"]["user"]
      source "http://wise4.org/downloads/software/stable/#{base}-#{suffix}.war"
      mode "0644"
      not_if { File.directory? "#{node["tomcat"]["webapp_dir"]}/#{base}" }
    end
  end

end

cookbook_file "/home/vagrant/src/update-wise4.sh" do
  source "update-wise4.sh"
  owner "vagrant"
  group "vagrant"
  mode "0755"
end


# Item 6
# need to force a catalina restart so the wars get exploded
service "tomcat" do
  action :restart
end

# we need to pause here for a while.
# there has got to be a better way, but meh.
execute "wait for tomcat to restart" do
  command "sleep 30"
end

# Item 7
service "tomcat" do
  action :stop
end

# we need to pause here for a while.
# there has got to be a better way, but meh.
execute "wait for tomcat to restart" do
  command "sleep 10"
end

# Item 8
template "#{node["tomcat"]["webapp_dir"]}/webapp/WEB-INF/classes/portal.properties" do
  source "portal.properties.erb"
  owner node["tomcat"]["user"]
  group node["tomcat"]["user"]
  mode "0644"
end

# also a copy for the update-wise4.sh script
template "/home/vagrant/portal.properties" do
  source "portal.properties.erb"
  owner "vagrant"
  group "vagrant"
  mode "0644"
end

# Item 9
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

# Item 10
# don't need to do anything because the defaults work

# Item 11
execute "create-sail_database-schemas" do
  not_if { File.exists? '/home/vagrant/made_sail_schema'}
  cwd "#{node["tomcat"]["webapp_dir"]}/webapp/WEB-INF/classes/tels"
  command "mysql sail_database -u root -p#{node[:mysql][:server_root_password]} < wise4-createtables.sql && touch /home/vagrant/made_sail_schema"
  creates "/home/vagrant/made_sail_schema"
end

# Item 12
execute "insert-default-values-into-sail_database" do
  not_if { File.exists? '/home/vagrant/made_sail_data'}
  cwd "#{node["tomcat"]["webapp_dir"]}/webapp/WEB-INF/classes/tels"
  command "mysql sail_database -u root -p#{node[:mysql][:server_root_password]} < wise4-initial-data.sql  && touch /home/vagrant/made_sail_data"
  creates "/home/vagrant/made_sail_data"
end

# Item 13 happens automatically with the notifies restart lines above
