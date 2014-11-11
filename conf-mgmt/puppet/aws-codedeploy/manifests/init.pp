# == Class: codedeploy
#
# Install and manage the AWS CodeDeploy agent
#
# === Parameters
#
# [*package_source*]
#   URL or filepath passed to package provider to install agent
#
class codedeploy (
  $package_source = $codedeploy::params::package_source,
) inherits codedeploy::params {

  validate_string($package_source)

  class { 'codedeploy::install': } ~>
  class { 'codedeploy::service': } ->
  Class['codedeploy']
}
