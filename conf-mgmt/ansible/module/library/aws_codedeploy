#!/usr/bin/python

import sys
import os
import urlparse
import shutil
from subprocess import Popen
from subprocess import PIPE

DOCUMENTATION = '''
---
module: aws_codedeploy
short_description: Installs and starts the AWS CodeDeploy Agent
description:
  - Installs and starts the AWS CodeDeploy Agent
version_added: 0.0
author: Andrew Fitz Gibbon
options:
  enabled:
    description:
      - Enable the agent
     choices: [ "yes", "no" ]
     required: true
'''

try:
    import boto
    from boto.s3.connection import Location
    from boto.utils import get_instance_metadata
except ImportError:
    print "failed=True msg='boto required for this module'"
    sys.exit(1)

# Determine if we're running on an EC2 instance
def on_ec2():
    try:
        instance_metadata = boto.utils.get_instance_metadata(timeout=2, num_retries=2)
        if 'instance-id' in instance_metadata.keys() and len(instance_metadata['instance-id']) > 0:
            return True
        else:
            return False
    except:
        return False

# Determine what kind of instance
def os_type():
    os = 'na'
    release = ''

    try:
        release = str(Popen(['lsb_release', '-a'], stdout=PIPE).communicate())
    except:
        release = str(Popen(['cat', '/etc/system-release'], stdout=PIPE).communicate())

    if 'AmazonAMI' in release or 'Amazon Linux AMI' in release:
        return 'amzn'
    elif 'Debian' in release or 'Ubuntu' in release:
        return 'deb'
    else:
        return os

def get_package(module, pkg_type):
    dest = '/tmp/codedeploy_package.' + pkg_type

    pkg_url = 'https://s3.amazonaws.com/aws-codedeploy-us-east-1/latest/codedeploy-agent'
    if pkg_type == 'deb':
        pkg_url += '_all.deb'
    elif pkg_type == 'rpm':
        pkg_url += '.noarch.rpm'
    else:
        raise ValueError('unknown package type')

    body, info = fetch_url(module, pkg_url)

    if info['status'] != 200:
        module.fail_json(msg="Failed to download agent",
                         status_code=info['status'],
                         respose=info['msg'],
                         url=pkg_url)

    try:
        f = open(dest, 'wb')
        shutil.copyfileobj(body, f)
    except Exception, e:
        module.fail_json(msg="failed to write agent package to disk: %s" % str(e))

    return dest

def install_pacakge(source, pkg_type):
    cmd = ''
    if pkg_type == 'deb': 
        cmd = 'dpkg -i ' + source + '; apt-get -q -y -f install'
    elif pkg_type == 'rpm':
        cmd = 'yum install -q -y ' + source
    else:
        raise ValueError('unknown package type')

    os.system(cmd) # TODO catch return

def main():
    module = AnsibleModule(
        argument_spec = dict(
            enabled   = dict(required=True, choices=BOOLEANS) # TODO actually use this
        )
    )

    if not on_ec2():
        module.fail_json(msg="must install the AWS CodeDeploy on an EC2 instance")

    try:
        os = os_type()
        pkg_type = ''
        if os == 'deb':
            pkg_type = 'deb'
        elif os == 'amzn':
            pkg_type = 'rpm'
        else:
            module.fail_json(msg="must install the AWS CodeDeploy on a supported OS type")

        pkg = get_package(module, pkg_type)
        install_pacakge(pkg, pkg_type)
    except Exception, e:
        module.fail_json(msg=str(e))

    module.exit_json(installed=True)

from ansible.module_utils.basic import *
from ansible.module_utils.urls import *
main()
