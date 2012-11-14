# this from the instructions here: http://code.google.com/p/wise4/wiki/StableWISEDeploymentModel

# Create the vagrant user

user "vagrant" do
  comment "vagrant user for vagrant/ec2 deploy convergence."
  shell "/bin/bash"
  home "/home/vagrant/"
  # supports :manage_home => false
end

# create vagrants home directory unless it exists already:
directory "/home/vagrant" do
   mode 0775
   owner "vagrant"
   group "vagrant"
   action :create
   recursive true
end

include_recipe "apt"
include_recipe "emacs"
include_recipe "vim"
include_recipe "wise4"
