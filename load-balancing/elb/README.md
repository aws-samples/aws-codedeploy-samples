# ELB and ASG lifecycle event scripts

Often when running a web service, you'll have your instances behind a load balancer. But when deploying new code to these instances, you don't want the load balancer to continue sending customer traffic to an instance while the deployment is in progress. Lifecycle event scripts give you the ability to integrate your AWS CodeDeploy deployments with instances that are behind an Elastic Load Balancer or in an Auto Scaling group. Simply set the name (or names) of the Elastic Load Balancer your instances are a part of, set the scripts in the appropriate lifecycle events, and the scripts will take care of deregistering the instance, waiting for connection draining, and re-registering after the deployment finishes.

## Requirements

The register and deregister scripts have a couple of dependencies in order to properly interact with Elastic Load Balancing and AutoScaling:

1. The [AWS CLI](http://aws.amazon.com/cli/). In order to take advantage of AutoScaling's Standby feature, the CLI must be at least version 1.3.25. If you have Python and PIP already installed, the CLI can simply be installed with `pip install awscli`. Otherwise, follow the [installation instructions](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) in the CLI's user guide.

2. An instance profile with a policy that allows, at minimum, the following actions:

        elasticloadbalancing:Describe*
        elasticloadbalancing:DeregisterInstancesFromLoadBalancer
        elasticloadbalancing:RegisterInstancesWithLoadBalancer
        autoscaling:Describe*
        autoscaling:EnterStandby
        autoscaling:ExitStandby
        autoscaling:UpdateAutoScalingGroup
        autoscaling:SuspendProcesses
        autoscaling:ResumeProcesses

    **Note**: the AWS CodeDeploy Agent requires that an instance profile be attached to all instances that are to participate in AWS CodeDeploy deployments. For more information on creating an instance profile for AWS CodeDeploy, see the [Create an IAM Instance Profile for Your Amazon EC2 Instances](http://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-create-iam-instance-profile.html) topic in the documentation.

3. All instances are assumed to already have the AWS CodeDeploy Agent installed.

## Installing the Scripts

To use these scripts in your own application:

1. Install the AWS CLI on all your instances.
2. Update the policies on the EC2 instance profile to allow the above actions.
3. Copy the `.sh` files in this directory into your application source.
4. Edit your application's `appspec.yml` to run `deregister_from_elb.sh` on the ApplicationStop event, and `register_with_elb.sh` on the ApplicationStart event.
5. If your instance is not in an Auto Scaling Group, edit `common_functions.sh` to set `ELB_LIST` to contain the name(s) of the Elastic Load Balancer(s) your deployment group is a part of. Make sure the entries in ELB_LIST are separated by space.
Alternatively, you can set `ELB_LIST` to `_all_` to automatically use all load balancers the instance is registered to, or `_any_` to get the same behaviour as `_all_` but without failing your deployments if the instance is not part of any ASG or ELB. This is more flexible in heterogeneous tag-based Deployment Groups.
6. Optionally set up `HANDLE_PROCS=true` in `common_functions.sh`. See note below.
7. Deploy!

## Important notice about handling AutoScaling processes

When using AutoScaling with CodeDeploy you have to consider some edge cases during the deployment time window:

1. If you have a scale up event, the new instance(s) will get the latest successful *Revision*, and not the one you are currently deploying, so you will have a fleet of mixed revisions. To bring the outdated instances up to date, CodeDeploy automatically starts a follow-on deployment (immediatedly after the first) to update
any outdated instances so that all instances end up on the same revision. If you'd like to change this default behavior so that outdated EC2 instances are left at the older revision, see [Configure advanced options for a deployment group](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-groups-configure-advanced-options.html).
2. If you have a scale down event, instances are going to be terminated, and your deployment will (probably) fail.
3. If your instances are not balanced accross Availability Zones **and you are** using these scripts, AutoScaling may terminate some instances or create new ones to maintain balance (see [this doc](http://docs.aws.amazon.com/autoscaling/latest/userguide/as-suspend-resume-processes.html#process-types)), interfering with your deployment.
4. If you have the health checks of your AutoScaling Group based off the ELB's ([documentation](http://docs.aws.amazon.com/autoscaling/latest/userguide/healthcheck.html)) **and you are not** using these scripts, then instances will be marked as unhealthy and terminated, interfering with your deployment.

In an effort to solve these cases, the scripts can suspend some AutoScaling processes (AZRebalance, AlarmNotification, ScheduledActions and ReplaceUnhealthy) while deploying, to avoid those events happening in the middle of your deployment. You only have to set up `HANDLE_PROCS=true` in `common_functions.sh`.

A record of the previously (to the start of the deployment) suspended process is kept by the scripts (on each instance), so when finishing the deployment the status of the processes on the AutoScaling Group should be returned to the same status as before. I.e. if AZRebalance was suspended manually it will not be resumed. However, if the scripts don't run (failed deployment) you may end up with stale suspended processes.

Disclaimer: There's a small chance that an event is triggered while the deployment is progressing from one instance to another. The only way to avoid that completely whould be to monitor the deployment externally to CodeDeploy/AutoScaling and act accordingly. The effort on doing that compared to this depends on the each use case.

**WARNING**: If you are using this functionality you should only use *CodeDepoyDefault.OneAtATime* deployment configuration to ensure a serial execution of the scripts. Concurrent runs are not supported.
