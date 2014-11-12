AWS CodeDeploy Puppet Module
============================

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module installs the AWS CodeDeploy Agent.

## Module Description

The AWS CodeDeploy agent will copy packages to an EC2 instance from a configured S3 bucket.  This
module should be used on an EC2 instance that already has Puppet installed.  At this time, the only
supported operating systems are RedHat variants and Amazon Linux, through the installation of an RPM
package.

## Usage

Put the classes, types, and resources for customizing, configuring, and doing the fancy stuff with
your module here.


```puppet
    codedeploy {}
```

##Reference

###Class: codedeploy

####Parameters

* **package_source** - The url to install the CodeDeploy package from. Defaults to
`https://s3.amazonaws.com/aws-codedeploy-us-east-1/latest/codedeploy-agent.noarch.rpm`

##Limitations

 * This module requires a RedHat or Amazon Linux based operating system that is capable of
   installing RPM packages.

##Development

Please see our [GitHub repositories](https://github.com/awslabs)
