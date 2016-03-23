notice('MODULAR: postgres_database.pp')

$postgres_ensure = 'stopped'
$postgres_enable = false

Class['postgresql::server'] -> Postgres_config<||>
Postgres_config {
  ensure => $postgres_ensure,
  enable => $postgres_enable,

 }
class { 'postgresql::server':
    }

