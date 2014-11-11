#!/bin/bash

# Check to see that puppet itself is installed
yum list installed puppet &> /dev/null
if [ $? != 0 ]; then
    yum -y install puppet
fi

# Create the base directory for the system-wide puppet modules
mkdir -p /etc/puppet/modules

puppet="/usr/bin/puppet"

# Check for each of the modules we need. If they're not installed, install them.
for module in puppetlabs/stdlib puppetlabs/java puppetlabs/tomcat stahnma/epel; do
    $puppet module list | grep -q $(basename $module)
    if [ $? != 0 ]; then
        $puppet module install $module
    fi
done

exit 0
