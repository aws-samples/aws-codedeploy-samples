Using AWS CodeDeploy to Orchestrate Masterless Puppet
=====================================================

[Puppet](http://puppetlabs.com/) is a great tool for automating infrastructure management. You may
be familiar with using custom scripts (perhaps built on top of tools like Capistrano) to orchestrate
application deployments. Here, we'll show you how AWS CodeDeploy can do all of the heavy lifting for
you with almost no custom scripting.

For this post, we'll start with an instance that already has the CodeDeploy agent installed. If you
haven't already – or cleaned up afterwards – please complete *Step 1: Set Up an Amazon EC2 Instance*
in the [AWS CodeDeploy Getting Started Guide](http://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-set-up-new-instance.html).

Prepare the bundle
------------------

To start, we prepare the bundle, or source content, that will contain our Puppet modules and
configuration. The sample app we use here is a simple Java web app, but you're free to substitute
your own. The full source for this example bundle is also available [here](https://github.com/awslabs/aws-codedeploy-samples/tree/master/conf-mgmt/puppet/masterless).

First, create directories for our application and deploy hooks. The base of these will be the root
of our CodeDeploy revision:

```bash
mkdir -p puppet-example/deploy_hooks
cd puppet-example
```

Then create a simple AppSpec as `./appspec.yml`:

```yml
version: 0.0
os: linux
files:
  - source: puppet/
    destination: /etc/puppet/codedeploy
  - source: target/hello.war
    destination: /var/lib/tomcat6/webapps
hooks:
  BeforeInstall:
    - location: deploy_hooks/install-puppet.sh
      timeout: 1800
      runas: root
  ApplicationStart:
    - location: deploy_hooks/puppet-apply.sh
      runas: root
  ValidateService:
    - location: deploy_hooks/verify_service.sh
      runas: root
```

This AppSpec tells AWS CodeDeploy that we want all of our Puppet manifests to be installed into
`/etc/puppet/codedeploy`, the war file for our app should be installed into the default tomcat6
webapps directory, and that it should run the scripts in `deploy_hooks/` on the appropriate
deployment events. Specifically: one to ensure that Puppet is properly installed and one to run
`puppet apply`.

Before we run anything though, our `BeforeInstall` checks that Puppet is installed and attempts to
install it. It also runs `puppet module install` for the tomcat module and its dependencies.

```bash
#!/bin/bash

# Check to see that Puppet itself is installed
yum list installed puppet &> /dev/null
if [ $? != 0 ]; then
    yum -y install puppet
fi

# Create the base directory for the system-wide Puppet modules
mkdir -p /etc/puppet/modules

puppet="/usr/bin/puppet"

# Check for each of the modules we need. If they're not installed, install them.
for module in puppetlabs/stdlib puppetlabs/java puppetlabs/tomcat stahnma/epel; do
    $puppet module list | grep -q $(basename $module)
    if [ $? != 0 ]; then
        $puppet module install $module
    fi
done

exit 0
```

Then, once our files are installed into the correct locations, our `ApplicationStart` lifecycle hook
actually runs `puppet apply`:

```bash
#!/bin/bash

BASE_DIR="/etc/puppet/"

/usr/bin/puppet apply --modulepath=${BASE_DIR}/modules ${BASE_DIR}/codedeploy/manifests/hello_world.pp
```

Finally, the `ValidateService` hook checks to see whether or not our app is responding as expected:

```bash
#!/bin/bash

result=$(curl -s http://localhost:8080/hello/)

if [[ "$result" =~ "Hello World" ]]; then
    exit 0
else
    exit 1
fi
```

Our Puppet manifest in this case is simply to set a couple of default tomcat options and start a
tomcat instance:

```
class { 'tomcat': }

class { 'epel': }->
tomcat::instance{ 'default':
  install_from_source => false,
  package_name        => 'tomcat6',
  package_ensure      => 'present',
}->
tomcat::service { 'default':
  use_jsvc     => false,
  use_init     => true,
  service_name => 'tomcat6',
}
```

The java app does nothing more than respond with 'Hello World' at the root of the app. You can take
a closer look by downloading the source at the link above.

Now that we've set up our bundle, we're ready to get things set up in AWS CodeDeploy.

Set Up the AWS CodeDeploy Application
-------------------------------------

Even though we might have an application and deployment group already set up on this
instance, it's a good practice to create new ones. First, we create the new application:

```sh
aws deploy create-application --application-name puppet-example
```

Then, using the ***CodeDeployTrustRoleArn*** that was assigned to our AWS CloudFormation stack, we create a
new deployment group for the puppet-example application:

```sh
aws deploy create-deployment-group \
    --application-name puppet-example \
    --deployment-group-name puppet_DeploymentGroup \
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
application bundle containing our Puppet manifests, and an AWS CodeDeploy application ready to accept
deployments.

We next need to upload our bundle and register it as a new revision in AWS CodeDeploy. The `aws deploy push` command in
the AWS CLI will take care of that for us (make sure you replace ***bucket-name*** with the name of
an Amazon S3 bucket you have set up for AWS CodeDeploy):

```sh
aws deploy push \
    --application-name puppet-example \
    --s3-location s3://bucket-name/puppet-example.zip \
    --ignore-hidden-files true
```

And now we're ready for a deployment:

```sh
aws deploy create-deployment \
    --application-name puppet-example \
    --deployment-config-name CodeDeployDefault.AllAtOnce \
    --deployment-group-name puppet_DeploymentGroup \
    --revision bucket=bucket-name,key=puppet-example.zip,bundleType=zip
```

Note here that we specify the deployment configuration again. This is so that we can override any
default that we might have set on the deployment group.

Once the deployment finishes (which you can check with either the AWS CodeDeploy console, or the `aws deploy
get-deployment` CLI command), you should be able to log into the instance and verify that the app is
up and running.

Wrapping up
-----------

Now you're ready to use the power of AWS CodeDeploy to orchestrate your fleet of Puppet nodes. In our
next post, we'll demonstrate how you can use a Puppet module to install the AWS CodeDeploy agent, thus
allowing your infrastructure to continue to be managed by Puppet while your application deployments
are managed via AWS CodeDeploy.
