$fuel_settings = parseyaml($astute_settings_yaml)

if $::osfamily == 'RedHat' {
  case $operatingsystemmajrelease {
    '6': {
      $postgres_default_version = '9.3'
      $bindir = "/usr/pgsql-${postgres_default_version}/bin"
      Class['postgresql::server'] -> Postgres_config<||>
      Postgres_config { ensure => present }
      postgres_config {
        log_directory     : value => "'/var/log/'";
        log_filename      : value => "'pgsql'";
        log_rotation_age  : value => "7d";
      }
    }
  }
}

# install and configure postgresql server
class { 'postgresql::globals':
  server_package_name => 'postgresql-server',
  client_package_name => 'postgresql',
  encoding            => 'UTF8',
  bindir              => $bindir,
  version             => $postgres_default_version,
}


class { 'postgresql::server':
  listen_addresses        => '0.0.0.0',
  ip_mask_allow_all_users => '0.0.0.0/0',
#  service_ensure   => 'stopped',
#  service_enable   => 'false',

}


$database_name   = 'maindb'
$database_engine = 'postgresql'
$database_port   = '5434'
$database_user   = 'dbuser'
$database_passwd = 'dbpasswd'


postgresql::server::db { $database_name:
  user             => $database_user,
  password         => $database_passwd,
  grant            => 'all',
  require          => Class['::postgresql::server'],
}

