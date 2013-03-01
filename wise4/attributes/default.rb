#
# Cookbook Name:: wise4
# Attributes:: default
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


default["wise4"]["db_user"] = "wise4user"
default["wise4"]["db_pass"] = "wise4pass"

# TODO: FIXME Ubuntu / AWS specific(!) and permissions?
default["wise4"]["dev_user"] = "ubuntu"

# Stable WAR files
# default["wise4"]["web_apps"] = {
#   'webapp'     => 'http://wise4.org/downloads/software/stable/webapp-4.5.war',
#   'vlewrapper' => 'http://wise4.org/downloads/software/stable/vlewrapper-4.5.war'
# }

# Nightly Builds:
default["wise4"]["web_apps"] = {
  'webapp'     => "http://wise4.org/downloads/software/nightly/webapp-latest.war",
  'vlewrapper' => "http://wise4.org/downloads/software/nightly/vlewrapper-latest.war"
}

# # DEC 5th snapshot for 4.6 that Noah has testsed with MySystem.
# # TODO put these in some other shared space
# default["wise4"]["web_apps"] = {
#   'webapp'     => "https://dl.dropbox.com/u/73403/wiseimages/webapp_2012_12_05.war",
#   'vlewrapper' => "https://dl.dropbox.com/u/73403/wiseimages/vlewrapper_2012_12_05.war"
# }
