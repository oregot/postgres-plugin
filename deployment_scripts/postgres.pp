notice('MODULAR: postgres_database/postgres.pp')

$network_metadata = hiera_hash('network_metadata')
$roles            = hiera('roles')
$nodes_list       = join(keys($network_metadata[nodes])," ")
$pgsql_vip   = $network_metadata['vips']['pgsql']['ipaddr']
$postgres_resource_name = 'p_pgsql'
$postgres_vip_name = 'vip__pgsql'


# Installing and configure postgresql

if member($roles, 'primary-controller')
{

file {'/var/lib/pgsql/':
  ensure  => 'directory',
  owner   => 'postgres',
  group   => 'postgres',
  mode    => '0755',
}

file {'/var/lib/pgsql/pg_archive/':
  ensure  => 'directory',
  owner   => 'postgres',
  group   => 'postgres',
  mode    => '0755',
}

exec {'init db':
  name    => '/usr/lib/postgresql/9.3/bin/initdb -D /var/lib/pgsql/data',
  user    => 'postgres',
  group   => 'postgres',
  onlyif  => '/usr/bin/test ! -d /var/lib/pgsql/data/base/',
}

file { '/var/lib/pgsql/data/postgresql.conf':
  ensure  => file,
  content => '
listen_addresses = \'*\'
wal_level = hot_standby
synchronous_commit = on
archive_mode = on
archive_command = \'cp %p /var/lib/pgsql/pg_archive/%f\'
max_wal_senders=5
wal_keep_segments = 32
hot_standby = on
restart_after_crash = off
replication_timeout = 5000
wal_receiver_status_interval = 2
max_standby_streaming_delay = -1
max_standby_archive_delay = -1
restart_after_crash = off
hot_standby_feedback = on
',
}

file { '/var/lib/pgsql/data/pg_hba.conf':
  ensure => file,
  content => '
host    all     all     0.0.0.0/0       trust
host    replication     all     0.0.0.0/0       trust
',
}


}


if  member($roles, 'controller') and ! member($roles, 'primary-controller')   {
notice ("Try to replicate DB from master")

package { 'postgresql-server':
  ensure   => true,
  name     => postgresql,
} ->

exec { "service postgresql stop":
  path     => ["/usr/bin", "/usr/sbin"]
} ->

file { "remove-postgresql-dir":
  name     => "/var/lib/pgsql/data",
  ensure   => 'absent',
  recurse  => true,
  purge    => true,
  force    => true,
} ->

exec { "pg_basebackup -h $primary_controllet_int_ip -U postgres -D /var/lib/pgsql/data -X stream -P":
  path    => ["/usr/bin", "/usr/sbin"],
  user    => 'postgres',
  group   => 'postgres',
}



}
