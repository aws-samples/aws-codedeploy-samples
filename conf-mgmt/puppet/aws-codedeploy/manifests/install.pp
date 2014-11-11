# == Class codedeploy::install
#
class codedeploy::install {

  package { 'codedeploy-agent':
    ensure   => present,
    source   => $codedeploy::package_source,
    provider => rpm,
  }
}
