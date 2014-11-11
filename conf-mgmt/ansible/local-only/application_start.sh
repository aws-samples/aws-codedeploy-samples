#!/bin/bash

# Deploy hooks are run via absolute path, so taking dirname of this script will give us the path to
# our deploy_hooks directory.
. $(dirname $0)/common_variables.sh

ansible-playbook $DESTINATION_PATH/lamp_simple/site.yml -i $DESTINATION_PATH/lamp_simple/hosts --connection=local 
