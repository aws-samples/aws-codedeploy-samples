# aws-codedeploy-session-helper Tool | get_sts_creds
##Overview
The aws-codedeploy-session-helper get_sts_creds tool enables customers to generate AWS STS credentials and write them to a file. Just provide the aws-codedeploy-session-helper tool some existing credentials and a file location to write the files to, and the tool will retrieve the credential and write them to the requested file.  This tool is best paired with static credentials on the box and a cron job to automatically pull the STS credentials.
##Usage
`bin/get_sts_creds` will use existing credentials to retrieve STS credentials, then write the credentials to a file location of your choosing. By default, the session name of the STS credentials is the HOSTNAME of the instance executing the tool. More information about STS credentials can be found [here](http://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html).
```
$ bin/get_sts_creds --help
<displays help>
$ bin/get_sts_creds --role-arn arn:aws:iam::123456789012:role/foo --file /var/tmp/foo
$ cat /var/tmp/foo
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
aws_session_token = AQoEXAMPLEH4aoAH0gNCAPyJxz4BlCFFxWNE1OPTgk5TthT+FvwqnKwRcOIfrRh3c/LTo6UDdyJwOOvEVPvLXCrrrUtdnniCEXAMPLE/IvU1dYUg2RVAJBanLiHb4IgRmpRV3zrkuWJOgQs8IZZaIv2BXIa2R4OlgkBN9bkUDNCJiBeb/AXlzBBko7b15fjrBs2+cTQtpZ3CYWFXG8C5zqx37wnOE49mRl/+OtkIKGO7fAE
$
```
### Providing credentials to the tool
Credentials can be provided to the tool in a few different ways. Following the AWS Ruby SDK's [documentation](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html), credentials can be provided by exporting environment variables or having the credentials present at a specific file on the box.
#### Environment variables
Linux
```
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
```
Windows
```
set AWS_ACCESS_KEY_ID=your_access_key_id
set AWS_SECRET_ACCESS_KEY=your_secret_access_key
```
#### File
File format
```
[default]
aws_access_key_id = your_access_key_id
aws_secret_access_key = your_secret_access_key
```
File location - Linux
```
~/.aws/credentials
```
File location - Windows
```
%HOMEPATH%\.aws\credentials
```
### Working with AWS CodeDeploy
This tool will help customers of [AWS CodeDeploy](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0ahUKEwjqoYOU8-LPAhXLsFQKHV4ZDzAQFggeMAA&url=https%3A%2F%2Faws.amazon.com%2Fcodedeploy%2F&usg=AFQjCNFJWFZ0JuuOFbyE390fglFUUi9sXA&sig2=fDXnI7wC1k6B578J-zPDuw)'s OnPremises instance deployment feature by enabling the retrieval and refreshment of the STS credentials that the on premises instance needs. Customers can quickly integrate on premises instances with AWS CodeDeploy by using the AWS CodeDeploy IAM Session support feature [LINK].

You can use this tool with a centralized STS credential broker service distribute credentials to other on premises instances, or deploy a fixed IAM User to each host, then have each host use that IAM user's credentials with this tool to retrieve STS credentials.

When using the `--print-session-arn` flag, you can see the IAM Session ARN that the host will assume. Use this ARN when registering with CodeDeploy. This ARN does not change as long as the arguments to the tool do not change, or the host the tool is running on does not change, as the tool uses the HOSTNAME of the host by default.

## Installation
This tool only requires the Ruby and the aws-sdk-core gem to be installed. This tool can be installed as a ruby gem, or just ran once unzipped via `git clone`.

This has been tested to work with Ruby versions 2.3.1, 2.3.0, 2.2.2, 2.1.10, 2.0.0, and 1.9.3 on Linux.

Note: When using the gem for installation, get_sts_creds will be added to your PATH.
### Amazon Linux
```
// Amazon Linux should have git, ruby, and gem installed
$ gem install aws-sdk-core
$ git clone https://github.com/awslabs/aws-codedeploy-samples.git OR gem install aws-codedeploy-session-helper
$ utilities/aws-codedeploy-session-helper/bin/get_sts_creds <args>
```
### Ubuntu
```
$ sudo apt-get install ruby     // if not installed
$ sudo apt-get install rubygems // if not installed. For 14.04, try rubygems-integration
$ sudo apt-get install git      // if not installed and using git clone to install instead of gem
$ sudo gem install aws-sdk-core
$ git clone https://github.com/awslabs/aws-codedeploy-samples.git OR gem install aws-codedeploy-session-helper
$ utilities/aws-codedeploy-session-helper/bin/get_sts_creds <args>
```
### Windows
1. Install Ruby from rubyinstaller.org (the 2.3 version comes w/ Gem)
1. `> gem install aws-sdk-core`
1. Install Git from https://git-scm.com/download/win
1. `> git clone https://github.com/awslabs/aws-codedeploy-samples.git` OR `> gem install aws-codedeploy-session-helper`
1. `> chdir <install dir>`
1. `> ruby utilities/aws-codedeploy-session-helper/bin/get_sts_creds <args>`
## Automation
For a Linux machine, you can automate the execution of this tool with the following cron
```
0,15,30,45 * * * * /path/to/tool/bin/get_sts_creds <args>
```

## Testing / Development
If you wish to execute the tests for this tool, you must have the `rspec` and `simplecov` gems installed. Then execute
```
$ cd <aws-codedeploy-session-helper dir>
$ rake
```
The rake task executes syntax checks and tests that cover the CLI's failure cases in addition to the tool's backing library.

To build the gem, just run

```
$ cd <aws-codedeploy-session-helper dir>
$ gem build aws-codedeploy-session-helper.gemspec
```
