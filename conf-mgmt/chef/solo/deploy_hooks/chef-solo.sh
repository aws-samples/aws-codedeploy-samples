#!/bin/bash

# First, make sure the tomcat cookbook is installed
cd /etc/chef/codedeploy/
/usr/local/bin/librarian-chef install

/usr/local/bin/chef-solo -c /etc/chef/codedeploy/solo.rb
