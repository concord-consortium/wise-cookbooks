maintainer        "Noah Paessel"
maintainer_email  "npaessel@concord.org"
license           "mit"
description       "Configures a WISE4 portal"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.0.2"
recipe            "default", "Simple, bare WISE4 portal setup configuration."

%w{ ubuntu debian }.each do |os|
  supports os
end
