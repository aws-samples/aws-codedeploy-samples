Chef and AWS CodeDeploy
-----------------------

[Chef](https://www.getchef.com) is a configuration management tool that enables users to write
recipes that describe how the instances in their fleet are configured. AWS provides two template
samples for integrating Chef and AWS CodeDeploy. The first is a Chef cookbook that will install and
start the AWS CodeDeploy host agent, giving you the ability to continue managing your host
infrastructure via Chef while also being able to take advantage of the power of AWS CodeDeploy. The
second sample template demonstrates how to use CodeDeploy to orchestrate running cookbooks and
recipes via chef-solo on each node.

[Learn more >](https://github.com/awslabs/aws-codedeploy-samples)
