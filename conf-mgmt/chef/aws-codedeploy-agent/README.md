Installing the AWS CodeDeploy Agent with Chef
=============================================

In the previous post, we learned how to use the power of AWS CodeDeploy to orchestrate chef-solo. It took
the perspective of having half of your dependencies already installed – namely, the CodeDeploy agent. For
this post, we'll look at it from a different angle: the CodeDeploy host agent isn't installed yet, but you
have a pre-existing Chef environment running on Amazon EC2 instances.

Setup and Preconditions
-----------------------

The post below makes a few assumptions about your environment that may or may not be true. First and
foremost is that you have a working Chef environment. We'll assume that you've worked through your
own workflow for managing that environment and your chef-repo. If you are still new to Chef, their
documentation has a lot of very helpful information: [http://docs.getchef.com](http://docs.getchef.com)

AWS CodeDeploy Host Agent Cookbook
----------------------------------

We've built a custom Chef cookbook to help ease the process of installing the CodeDeploy agent. You
can download that cookbook
[here](https://github.com/awslabs/aws-codedeploy-samples/tree/master/conf-mgmt/chef/aws-codedeploy-agent/cookbooks/codedeploy-agent/recipes).
To install the CodeDeploy agent, simply download the linked archive, copy the codedeploy-agent
directory into your chef-repo, and add `recipe[codedeploy-agent]` to your run list. If you just want
to test this out with a chef-solo instance, we've included a sample configuration for you.

The cookbook has three simple steps:

1.  Download the package for the CodeDeploy host agent.
1.  Install the agent.
1.  Start the agent.
