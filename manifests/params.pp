# == Class storm::params
#
class storm::params {
  $base_dir                = '/opt/storm'
  $command                 = "${base_dir}/bin/storm"
  $config                  = "${base_dir}/conf"
  $config                  = "${base_dir}/conf/storm.yaml"
  $config_map              = {}
  $config_template         = 'storm/storm.yaml.erb'
  $gid                     = 0
  $group                   = 'service'
  $group_ensure            = 'present'
  $local_dir               = '/app/storm'
  $local_hostname          = $::hostname
  $log_dir                 = '/var/log/storm'
  $logback                 = "${base_dir}/logback/cluster.xml"
  $logback_template        = 'storm/cluster.xml.erb'
  $logviewer_childopts     = '-Xmx128m -Djava.net.preferIPv4Stack=true'
  $nimbus_host             = 'nimbus1'
  $nimbus_childopts        = '-Xmx256m -Djava.net.preferIPv4Stack=true'
  $autoupgrade             = false
  $package_name            = 'storm'
  $package_ensure          = 'present'
  $service_autorestart     = true
  $service_enable          = true
  $service_ensure          = 'present'
  $service_manage          = true
  $service_name_logviewer  = 'storm-logviewer'
  $service_name_nimbus     = 'storm-nimbus'
  $service_name_supervisor = 'storm-supervisor'
  $service_name_ui         = 'storm-ui'
  $service_retries         = 999
  $service_startsecs       = 10
  $service_stderr_logfile_keep    = 10
  $service_stderr_logfile_maxsize = '20MB'
  $service_stdout_logfile_keep    = 5
  $service_stdout_logfile_maxsize = '20MB'
  $shell                   = '/bin/bash'
  $storm_messaging_transport      = 'backtype.storm.messaging.netty.Context'
  $supervisor_childopts    = '-Xmx256m -Djava.net.preferIPv4Stack=true'
  $supervisor_slots_ports  = [6700, 6701]
  $ui_childopts            = '-Xmx256m -Djava.net.preferIPv4Stack=true'
  $uid                     = 53001
  $user                    = 'storm'
  $user_description        = 'Storm system account'
  $user_ensure             = 'present'
  $user_home               = '/home/storm'
  $user_manage             = true
  $user_managehome         = true
  $worker_childopts        = '-Xmx256m -Djava.net.preferIPv4Stack=true'
  $zookeeper_servers       = ['localhost']

  # Parameters not exposed to the user via init.pp
  $storm_rpm_log_dir       = "${base_dir}/logs" # Must match RPM layout; use $log_dir to define actual logging directory
  validate_absolute_path($storm_rpm_log_dir)

  case $::osfamily {
    'RedHat': {}
    'Debian': {}

    default: {
      fail("The ${module_name} module is not supported on a ${::osfamily} based system.")
    }
  }

  case $::kernel {
    'Linux': {
      $package_dir = "${base_dir}/swdl"
    }
    default: {
      fail("\"${module_name}\" provides no config directory default value for \"${::kernel}\"")
    }
  }

  # Download tool
  case $::kernel {
    'Linux': {
      $download_tool = 'wget -O'
    }
    'Darwin': {
      $download_tool = 'curl -o'
    }
    default: {
      fail("\"${module_name}\" provides no download tool default value
           for \"${::kernel}\"")
    }
  }

}
