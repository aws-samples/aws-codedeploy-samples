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
