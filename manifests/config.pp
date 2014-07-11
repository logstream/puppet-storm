# == Class storm::config
#
class storm::config inherits storm {
  file { $config_dir:
    ensure => directory,
    owner => root,
    group => root,
  }

  file { $config:
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($config_template),
    require => [ Package['storm'], File[$log_dir], File[$local_dir] ],
  }

  file { $logback:
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template($logback_template),
    require => File[$config],
  }

}
