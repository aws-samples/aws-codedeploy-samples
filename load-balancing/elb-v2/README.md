# Lifecycle event scripts for Application Load Balancers and Network Load Balancers

When running a web service, you don't want customer traffic to be sent to the instances that host your service when a deployment is in progress. For this reason, you might register your instances with a load balancer. During an AWS CodeDeploy in-place deployment, a load balancer prevents internet traffic from being routed to an instance while it is being deployed to, and then makes the instance available for traffic again after the deployment to that instance is complete.

Lifecycle event scripts give you the ability to deploy to instances that are registered with a target group for an Application Load Balancer or Network Load Balancer. You set the name or names of the target group that your instances are a part of and run the scripts during the appropriate lifecycle events. The scripts take care of deregistering the instance, waiting for the connection to drain, and re-registering the instance after the deployment is complete.

## Requirements

The following requirements must be met for the register and deregister scripts to interact with an Application Load Balancer or Network Load Balancer:

1.  For instances provisioned as part of an Auto Scaling group only: To use the Standby feature in Auto Scaling, the [AWS CLI](http://aws.amazon.com/cli/) version 1.10.55 or a later must be installed on the instance. If Python and PIP are already installed, you can install the CLI by running the pip install awscli command. Otherwise, follow the [installation instructions](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) in the AWS Command Line Interface User Guide.

2.  For all instances: An IAM instance profile must be attached to the instance with a policy that allows, at minimum, the following actions:


```
    elasticloadbalancing:Describe*
    elasticloadbalancing:DeregisterTargets
    elasticloadbalancing:RegisterTargets
    autoscaling:Describe*
    autoscaling:EnterStandby
    autoscaling:ExitStandby
    autoscaling:UpdateAutoScalingGroup
    autoscaling:SuspendProcesses
    autoscaling:ResumeProcesses
```

For information about creating an IAM instance profile to use with AWS CodeDeploy, see [Create an IAM Instance Profile for Your Amazon EC2 Instances](http://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-create-iam-instance-profile.html).

3. For all instances: The AWS CodeDeploy agent must be installed on the instance. For information, see [Install or Reinstall the AWS CodeDeploy Agent](http://docs.aws.amazon.com/codedeploy/latest/userguide/codedeploy-agent-operations-install.html).


## Installing the Scripts

To use these scripts in your own application:

1. Install the AWS CLI on all your instances. For information, see [Install or Upgrade and Then Configure the AWS CLI](http://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-configure-cli.html).
2. Add the permissions listed in the Prerequisites to your IAM instance profile. For information, see [Modifying a Role](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_manage_modify.html).
3. Copy the `.sh` files in this directory into your application source.
4. Edit your application's `appspec.yml` to run `deregister_from_elb.sh` on the ApplicationStop event,
and `register_with_elb.sh` on the ApplicationStart event.

Note: You can use the application specification file included in this directory

For example:

```
hooks:
   ApplicationStop:
     - location: Scripts/deregister_from_elb.sh
       timeout: 180
   ApplicationStart:
     - location: Scripts/register_with_elb.sh
       timeout: 180
```

5. Edit `common_functions.sh` to set `TARGET_LIST` to contain the names of the target group your deployment group is a part of. Make sure the entries in `TARGET_LIST` are separated by spaces.

For example:

```
# TARGET_LIST defines which target groups behind Load Balancer this instance should be part of.
# The elements in TARGET_LIST should be separated by space.
TARGET_GROUP_LIST="my-targets-1 my-targets-2"
```

6. Edit `common_functions.sh` to set PORT to the port number your application is running on. You need to do this only if the application is running on a port number different from the default port number set in the target group.

For example:

```
# PORT defines which port the application is running at.
# If PORT is not specified, the script will use the default port set in target groups
PORT="80"
```

7. Deploy your application. For information, see [Create a Deployment with AWS CodeDeploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/deployments-create.html).

## Important notice about handling AutoScaling processes

When using AutoScaling with CodeDeploy you have to consider some edge cases during the deployment time window:

1. If you have a scale up event, the new instance(s) will get the latest successful *Revision*, and not the one you are currently deploying. You will end up with a fleet of mixed revisions.
2. If you have a scale down event, instances are going to be terminated, and your deployment will (probably) fail.
3. If your instances are not balanced accross Availability Zones **and you are** using these scripts, AutoScaling may terminate some instances or create new ones to maintain balance (see [this doc](http://docs.aws.amazon.com/autoscaling/latest/userguide/as-suspend-resume-processes.html#process-types)), interfering with your deployment.
4. If you have the health checks of your AutoScaling Group based off the ELB's ([documentation](http://docs.aws.amazon.com/autoscaling/latest/userguide/healthcheck.html)) **and you are not** using these scripts, then instances will be marked as unhealthy and terminated, interfering with your deployment.

In an effort to solve these cases, the scripts can suspend some AutoScaling processes (AZRebalance, AlarmNotification, ScheduledActions and ReplaceUnhealthy) while deploying, to avoid those events happening in the middle of your deployment. You only have to set up `HANDLE_PROCS=true` in `common_functions.sh`.

A record of the previously (to the start of the deployment) suspended process is kept by the scripts (on each instance), so when finishing the deployment the status of the processes on the AutoScaling Group should be returned to the same status as before. I.e. if AZRebalance was suspended manually it will not be resumed. However, if the scripts don't run (failed deployment) you may end up with stale suspended processes.

Disclaimer: There's a small chance that an event is triggered while the deployment is progressing from one instance to another. The only way to avoid that completely would be to monitor the deployment externally to CodeDeploy/AutoScaling and act accordingly. The effort on doing that compared to this depends on the each use case.

**WARNING**: If you are using this functionality you should only use *CodeDeployDefault.OneAtATime* deployment configuration to ensure a serial execution of the scripts. Concurrent runs are not supported.
