Using AWS CodeDeploy to Orchestrate chef-solo
=============================================

[Chef](http://www.getchef.com/chef/) is a great tool for automating infrastructure management, but
sometimes running and maintaining a central Chef server – and ensuring that it's highly available –
can be cost-prohibitive. So you turn to chef-solo, where you are fully responsible for orchestrating
the distribution of cookbooks and running chef-solo. Up until now, you've used a set of custom
scripts (perhaps built on top of tools like Capistrano) to do that orchestration. Here, we'll show
you how AWS CodeDeploy can do all of the heavy lifting for you with almost no custom scripting.

For this post, we'll start with an instance that already has the CodeDeploy agent installed. If you
haven't already – or cleaned up afterwards – please complete *Step 1: Set Up a New Amazon EC2 Instance*
in the [AWS CodeDeploy Getting Started Guide](http://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-set-up-new-instance.html).

*Note: The CloudFormation example is a lot easier to use: http://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-use-cloud-formation-template.html*

Prepare the bundle
------------------

Next, we prepare the bundle, or source content, that will contain our Chef cookbooks and
configuration. Here, we use a simple "hello world" cookbook, but you're free to substitute your own.
The full source for this example bundle is also available 
[here](https://github.com/awslabs/aws-codedeploy-samples/tree/master/conf-mgmt/chef/solo).

Note:  You will have to use the Apache Maven command, "mvn package" to create the target/hello.war file.

First, create directories for our application and deploy hooks. The base of these will be the root
of our CodeDeploy revision:

```bash
mkdir -p chef-solo-example/deploy_hooks
cd chef-solo-example
```

Then create a simple AppSpec as `./appspec.yml`:

```yml
version: 0.0
os: linux
files:
  - source: chef/
    destination: /etc/chef/codedeploy
  - source: target/hello.war
    destination: /var/lib/tomcat6/webapps
hooks:
  BeforeInstall:
    - location: deploy_hooks/install-chef.sh
      timeout: 1800
      runas: root
  ApplicationStart:
    - location: deploy_hooks/chef-solo.sh
      runas: root
  ValidateService:
    - location: deploy_hooks/verify_service.sh
      runas: root
```

This AppSpec tells AWS CodeDeploy that we want all of our chef configurations to be installed into
`/etc/chef/codedeploy`, the war file for our app should be installed into the default tomcat6
webapps directory, and that it should run the scripts in `deploy_hooks/` on the appropriate
deployment events. Specifically: one to ensure that Chef is properly installed and one to initiate
the chef-solo run.

Before we run anything, our `BeforeInstall` checks that Chef and RubyGems are installed and attempts
to install them. It also runs `knife install` to fetch the tomcat cookbook (in a normal application,
it's more likely that you'd already have done this; we're doing it as part of the deployment to keep
the sample bundle small):

```bash
#!/bin/bash

yum list installed rubygems &> /dev/null
if [ $? != 0 ]; then
    yum -y install gcc-c++ ruby-devel make autoconf automake rubygems
fi

gem list | grep -q chef
if [ $? != 0 ]; then
    gem install chef ohai
fi

# Install the tomcat cookbook
yum list installed git &> /dev/null
if [ $? != 0 ]; then
    yum install -y git
fi

cd /etc/chef/codedeploy/
if ! test -r .git; then 
    git init .; git add -A .; git commit -m "Init commit"
fi
if ! test -r ./cookbooks/tomcat; then
    /usr/local/bin/knife cookbook site install tomcat -o ./cookbooks
fi
```

Then, once our files are installed into the correct locations, our `ApplicationStart` lifecycle hook
actually initiates the chef-solo run::

```bash
#!/bin/bash
/usr/local/bin/chef-solo -c /etc/chef/codedeploy/chef/solo.rb
```

Finally, the `ValidateService` hook checks to see whether or not our app is responding as expected:

```bash
#!/bin/bash

result=$(curl -s http://localhost/hello/)

if [[ "$result" =~ "Hello World" ]]; then
    exit 0
else
    exit 1
fi
```

Our chef configuration in this case is simply to set a couple of default tomcat options:

```ruby
node.default["tomcat"]["user"] = "root"
node.default["tomcat"]["port"] = 80
```

And the node.json and solo.rb configurations are similarly straightforward, just running the tomcat
default recipe and our own configuration (which we've titled `homesite`):

node.json:

```javascript
{
  "run_list": [ "recipe[homesite]", "recipe[tomcat]" ]
}
```

solo.rb:

```ruby
file_cache_path "/etc/chef/codedeploy/"
cookbook_path "/etc/chef/codedeploy/cookbooks"
json_attribs "/etc/chef/codedeploy/node.json"
```

The java app does nothing more than respond with 'Hello World' at the root of the app. You can take
a closer look by downloading the source at the link above.

Now that we've set up our bundle, we're ready to get things set up in AWS CodeDeploy.

Set Up the AWS CodeDeploy Application
------------------------------

Even though we might have an application and deployment group set up already set up on this
instance, it's a good practice to create new ones. First, we create the new application:

```sh
aws deploy create-application --application-name chef-solo-example
```

Then, using the ***CodeDeployTrustRoleArn*** that was assigned to our AWS CloudFormation stack, we create a
new deployment group for the chef-solo-example application:

```sh
aws deploy create-deployment-group \
    --application-name chef-solo-example \
    --deployment-group-name ChefSolo_DeploymentGroup \
    --deployment-config-name CodeDeployDefault.AllAtOnce \
    --ec2-tag-filters Key=Name,Value=CodeDeployDeployment,Type=KEY_AND_VALUE \
    --service-role-arn CodeDeployTrustRoleArn
```

In this deployment group, we've set the default deployment configuration to
`CodeDeployDefault.AllAtOnce`. This will deploy to all of our instances at the same time. In a real
production app, you'd probably want to set it to something more conservative like
`CodeDeployDefault.OneAtATime` or a custom configuration.

Push and Deploy the Application
-------------------------------

At this point, we have a running Amazon EC2 instance that has the AWS CodeDeploy agent installed, an
application bundle containing our Chef cookbooks, and an AWS CodeDeploy application ready to accept
deployments.

We next need to upload our bundle and register it as a new revision in AWS CodeDeploy. The `aws deploy push` command in
the AWS CLI will take care of that for us (make sure you replace ***bucket-name*** with the name of
an Amazon S3 bucket you have set up for AWS CodeDeploy):

```sh
aws deploy push \
    --application-name chef-solo-example \
    --s3-location s3://bucket-name/chef-solo.zip \
    --ignore-hidden-files
```

And now we're ready for a deployment:

```sh
aws deploy create-deployment \
    --application-name chef-solo-example \
    --deployment-config-name CodeDeployDefault.AllAtOnce \
    --deployment-group-name ChefSolo_DeploymentGroup \
    --s3-location bucket=bucket-name,key=chef-solo.zip,bundleType=zip
```

Note here that we specify the deployment configuration again. This is so that we can override any
default that we might have set on the deployment group.

Once the deployment finishes (which you can check with either the AWS CodeDeploy console, or the `aws deploy
get-deployment` CLI command), you should be able to log into the instance and verify that your
cookbooks were applied.

Wrapping up
-----------

Now you're ready to use the power of AWS CodeDeploy to orchestrate your fleet of chef-solo nodes. In our
next post, we'll demonstrate how you can use a Chef recipe to install the AWS CodeDeploy agent, thus
allowing your infrastructure to continue to be managed by Chef while your application deployments
are managed via AWS CodeDeploy.
