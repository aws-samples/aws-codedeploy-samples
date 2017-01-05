#!/bin/bash
#
# Copyright 2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#  http://aws.amazon.com/apache2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

. $(dirname $0)/common_functions.sh

msg "Running AWS CLI with region: $(get_instance_region)"

# get this instance's ID
INSTANCE_ID=$(get_instance_id)
if [ $? != 0 -o -z "$INSTANCE_ID" ]; then
    error_exit "Unable to get this instance's ID; cannot continue."
fi

# Get current time
msg "Started $(basename $0) at $(/bin/date "+%F %T")"
start_sec=$(/bin/date +%s.%N)

msg "Checking if instance $INSTANCE_ID is part of an AutoScaling group"
asg=$(autoscaling_group_name $INSTANCE_ID)
if [ $? == 0 -a -n "${asg}" ]; then
    msg "Found AutoScaling group for instance $INSTANCE_ID: ${asg}"

    msg "Checking that installed CLI version is at least at version required for AutoScaling Standby"
    check_cli_version
    if [ $? != 0 ]; then
        error_exit "CLI must be at least version ${MIN_CLI_X}.${MIN_CLI_Y}.${MIN_CLI_Z} to work with AutoScaling Standby"
    fi

    msg "Attempting to put instance into Standby"
    autoscaling_enter_standby $INSTANCE_ID "${asg}"
    if [ $? != 0 ]; then
        error_exit "Failed to move instance into standby"
    else
        msg "Instance is in standby"
        exit 0
    fi
fi

msg "Instance is not part of an ASG, continuing..."

msg "Checking that user set at least one valid target group"
if test -z "$TARGET_GROUP_LIST"; then
    error_exit "Must have at least one target group to deregister from"
fi

msg "Checking whether the port number has been set"
if test -n "$PORT"; then
    if ! [[ $PORT =~ ^[0-9]+$ ]] ; then
       error_exit "$PORT is not a valid port number"
    fi
    msg "Found port $PORT, it will be used for instance health check against target groups"
else
    msg "PORT variable is not set, will use the default port number set in target groups"
fi

# Loop through all target groups the user set, and attempt to deregister this instance from them.
for target_group in $TARGET_GROUP_LIST; do
    msg "Deregistering $INSTANCE_ID from $target_group starts"
    deregister_instance $INSTANCE_ID $target_group

    if [ $? != 0 ]; then
        error_exit "Failed to deregister instance $INSTANCE_ID from target group $target_group"
    fi
done

# Wait for all Deregistrations to finish
msg "Waiting for instance to de-register from its target groups"
for target_group in $TARGET_GROUP_LIST; do
    wait_for_state "alb" $INSTANCE_ID "unused" $target_group
    if [ $? != 0 ]; then
        error_exit "Failed waiting for $INSTANCE_ID to leave $target_group"
    fi
done

msg "Finished $(basename $0) at $(/bin/date "+%F %T")"

end_sec=$(/bin/date +%s.%N)
elapsed_seconds=$(echo "$end_sec - $start_sec" | /usr/bin/bc)

msg "Elapsed time: $elapsed_seconds"
