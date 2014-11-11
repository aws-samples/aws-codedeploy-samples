#!/bin/bash

# Deploy hooks are run via absolute path, so taking dirname of this script will give us the path to
# our deploy_hooks directory.
. $(dirname $0)/../application_vars.sh

salt-call --local --file-root=$DESTINATION_PATH state.highstate
