notice('MODULAR: postgres_database/postgres.pp')

$nodes_hash                     = hiera('nodes', {})
$network_metadata = hiera_hash('network_metadata')
$roles            = hiera('roles')
$nodes_list       = join(keys($network_metadata[nodes])," ")
$pgsql_vip   = $network_metadata['vips']['pgsql']['ipaddr']
$postgres_resource_name = 'p_pgsql'
$postgres_vip_name = 'vip__pgsql'
$primary_controllet_int_ip = nodes_with_roles($nodes_hash, ['primary-controller'], 'internal_address')
$postgres_hash = hiera_hash('postgresql_database')
$postgresql_version = pick($postgres_hash['postgresql_plugin_version_database'],'9.5')

# Installing and configure postgresql

if member($roles, 'primary-controller')
{

# postgresql installation
package { "postgresql-server-$postgresql_version":
  ensure   => true,
  name     => "postgresql-$postgresql_version",
} ->

# ensure that dir is present and right is correct
file {'/var/lib/pgsql/':
  ensure  => 'directory',
  owner   => 'postgres',
  group   => 'postgres',
  mode    => '0755',
} ->

# creating folder for pid file
file {'/var/run/postgresql/':
  ensure  => 'directory',
  owner   => 'postgres',
  group   => 'postgres',
  mode    => '0755',
} ->

# creating folder for pg_archive files
file {'/var/lib/pgsql/pg_archive/':
  ensure  => 'directory',
  owner   => 'postgres',
  group   => 'postgres',
  mode    => '0755',
} ->

# creating instance
exec {'init db':
  name    => "/usr/lib/postgresql/$postgresql_version/bin/initdb -D /var/lib/pgsql/data",
  user    => 'postgres',
  group   => 'postgres',
  onlyif  => '/usr/bin/test ! -d /var/lib/pgsql/data/base/',
} ->

# change config
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
wal_receiver_status_interval = 2
max_standby_streaming_delay = -1
max_standby_archive_delay = -1
restart_after_crash = off
hot_standby_feedback = on
',
} ->

# adding permission
file { '/var/lib/pgsql/data/pg_hba.conf':
  ensure => file,
  content => '
local   all             all                     trust
host    all             all     0.0.0.0/0       trust
host    replication     all     0.0.0.0/0       trust
',
}  ->

# shutting off default instance
exec { "/usr/lib/postgresql/9.5/bin/pg_ctl -D /var/lib/postgresql/9.5/main stop":
  onlyif  => '/usr/bin/test -f "/var/lib/postgresql/9.5/main/postmaster.pid"',
  path    => ["/usr/bin", "/usr/sbin"],
  user    => 'postgres',
  group   => 'postgres',

} ->

# disable from autostart default instance postgresql
exec { '/usr/sbin/update-rc.d -f postgresql remove':
  path    => ["/usr/bin", "/usr/sbin"],
}


}


if  member($roles, 'controller') and ! member($roles, 'primary-controller')   {
notice ("Try to replicate DB from master")

package { 'postgresql-server':
  ensure   => true,
  name     => "postgresql-$postgresql_version",
} ->

file {'/var/run/postgresql/':
  ensure  => 'directory',
  owner   => 'postgres',
  group   => 'postgres',
  mode    => '0755',
} ->


file { "present-postgresql-dir":
  name     => "/var/lib/pgsql/",
  ensure   => 'directory',
  owner    => 'postgres',
  group    => 'postgres',
  mode     => '0700',

} ->

# copy database from already created instance
exec { "pg_basebackup -h $primary_controllet_int_ip -U postgres -D /var/lib/pgsql/data -X stream -P":
  path    => ["/usr/bin", "/usr/sbin"],
  user    => 'postgres',
  group   => 'postgres',
  onlyif  => '/usr/bin/test ! -d /var/lib/pgsql/data/base/',
} ->

exec { "/usr/lib/postgresql/9.5/bin/pg_ctl -D /var/lib/postgresql/9.5/main stop":
  onlyif  => '/usr/bin/test -f "/var/lib/postgresql/9.5/main/postmaster.pid"',
  path    => ["/usr/bin", "/usr/sbin"],
  user    => 'postgres',
  group   => 'postgres',

} ->

exec { '/usr/sbin/update-rc.d -f postgresql remove':
  path    => ["/usr/bin", "/usr/sbin"],
} ->

# say to pacemaker for try running postgresql on current host
exec { "/usr/sbin/pcs resource cleanup p_pgsql $fqdn":
  path    => ["/usr/bin", "/usr/sbin"],
}



}
