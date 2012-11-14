name              "vagrant_main"
maintainer        "Noah Paessel"
maintainer_email  "npaessel@concord.org"
license           "mit"
description       "Bootsraps a WISE4 deploy"
version           "0.0.2"
recipe            "default", "Setups Vagrant user, requires other cookbooks."

%w{ ubuntu debian }.each do |os|
  supports os
end
