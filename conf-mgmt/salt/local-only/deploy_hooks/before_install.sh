#!/bin/bash

# Check for salt, and attempt to install if not

yum list installed | grep salt-minion &> /dev/null
if [ $? != 0 ]; then
    yum install -y --enablerepo=epel salt-minion
fi
