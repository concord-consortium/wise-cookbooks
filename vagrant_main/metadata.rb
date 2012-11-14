name              "vagrant_main"
maintainer        "Noah Paessel"
maintainer_email  "npaessel@concord.org"
license           "mit"
description       "Bootsraps a WISE4 deploy"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.0.2"
recipe            "default", "Setups Vagrant user, requires other cookbooks."

%w{ ubuntu debian }.each do |os|
  supports os
end
