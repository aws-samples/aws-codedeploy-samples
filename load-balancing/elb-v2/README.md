# ALB and ASG lifecycle event scripts

Often when running a web service, you'll have your instances behind a load balancer. But when
deploying new code to these instances, you don't want the load balancer to continue sending customer
traffic to an instance while the deployment is in progress. Lifecycle event scripts give you the
ability to integrate your AWS CodeDeploy deployments with instances that are behind an ALB Target Group or
in an Auto Scaling group. Simply set the name (or names) of the ALB Target Groups your instances are
a part of, set the scripts in the appropriate lifecycle events, and the scripts will take care of
deregistering the instance, waiting for connection draining, and re-registering after the deployment
finishes.

## Requirements

The register and deregister scripts have a couple of dependencies in order to properly interact with
Application Load Balancing and AutoScaling:

1. The [AWS CLI](http://aws.amazon.com/cli/). In order to take advantage of
AutoScaling's Standby feature, the CLI must be at least version 1.10.55. If you
have Python and PIP already installed, the CLI can simply be installed with `pip
install awscli`. Otherwise, follow the [installation instructions](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)
in the CLI's user guide.
1. An instance profile with a policy that allows, at minimum, the following actions:

```
    elasticloadbalancing:Describe*
    elasticloadbalancing:DeregisterTargets
    elasticloadbalancing:RegisterTargets
    autoscaling:Describe*
    autoscaling:EnterStandby
    autoscaling:ExitStandby
    autoscaling:UpdateAutoScalingGroup
```

Note: the AWS CodeDeploy Agent requires that an instance profile be attached to all instances that
are to participate in AWS CodeDeploy deployments. For more information on creating an instance
profile for AWS CodeDeploy, see the [Create an IAM Instance Profile for Your Amazon EC2 Instances](http://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-create-iam-instance-profile.html)
topic in the documentation.
1. All instances are assumed to already have the AWS CodeDeploy Agent installed.

## Installing the Scripts

To use these scripts in your own application:

1. Install the AWS CLI on all your instances.
1. Update the policies on the EC2 instance profile to allow the above actions.
1. Copy the `.sh` files in this directory into your application source.
1. Edit your application's `appspec.yml` to run `deregister_from_elb.sh` on the ApplicationStop event,
and `register_with_elb.sh` on the ApplicationStart event.
1. Edit `common_functions.sh` to set `TARGET_LIST` to contain the name(s) of the Target Group your deployment group is a part of. Make sure the entries in TARGET_LIST are separated by space.
1. Edit `common_functions.sh` to set `PORT` to the port number your application is running at (if it's different from the default port number set in Target Group)
1. Deploy!
