# == Class codedeploy::params
#
# This class is meant to be called from codedeploy
# It sets variables according to platform
#
class codedeploy::params {
  case $::osfamily {
    'RedHat', 'Linux': {
      $package_source = 'https://s3.amazonaws.com/aws-codedeploy-us-east-1/latest/codedeploy-agent.noarch.rpm'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
