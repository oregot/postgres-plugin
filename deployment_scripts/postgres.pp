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

class { 'postgresql::globals':
  encoding => 'UTF8',
} ->

class { 'postgresql::server':
  listen_addresses           => '0.0.0.0',
  ipv4acls                   => ['host all all 0.0.0.0/0 trust','host replication all 0.0.0.0/0 trust'],
  ip_mask_allow_all_users    => '0.0.0.0/0',

}

postgresql::server::config_entry { 'wal_level':
  value => 'hot_standby',
}
postgresql::server::config_entry { 'synchronous_commit':
  value => 'on',
}
postgresql::server::config_entry { 'archive_mode':
  value => 'on',
}
#postgresql::server::config_entry { 'archive_command':
#  value => 'cp %p /var/lib/pgsql/pg_archive/%f',
#}
postgresql::server::config_entry { 'max_wal_senders':
  value => '5',
}
postgresql::server::config_entry { 'hot_standby':
  value => 'on',
}


file {'/var/lib/postgresql/9.3/main/postgresql.conf':
  ensure  => 'link',
  target  => '/etc/postgresql/9.3/main/postgresql.conf',
  owner   => 'postgres',
  group   => 'postgres',

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
  name     => "/var/lib/postgresql/9.3/main",
  ensure   => 'absent',
  recurse  => true,
  purge    => true,
  force    => true,
} ->

exec { "pg_basebackup -h $primary_controllet_int_ip -U postgres -D /var/lib/postgresql/9.3/main -X stream -P":
  path    => ["/usr/bin", "/usr/sbin"],
  user    => 'postgres',
  group   => 'postgres',
} ->

file {'/var/lib/postgresql/9.3/main/postgresql.conf':
  ensure  => 'link',
  target  => '/etc/postgresql/9.3/main/postgresql.conf',
  owner   => 'postgres',
  group   => 'postgres',

}


}
