notice('MODULAR: postgres_database/pacemaker.pp')

$nodes_hash                     = hiera('nodes', {})
$network_metadata = hiera_hash('network_metadata')
#$nodes_list       = join(keys($network_metadata[nodes])," ")
$pgsql_vip   = $network_metadata['vips']['pgsql']['ipaddr']
$postgres_resource_name = 'p_pgsql'
$postgres_vip_name = 'vip__pgsql'
$corosync_nodes = nodes_with_roles($nodes_hash, ['primary-controller', 'controller'], 'fqdn')
$separate_corosync_nodes = join($corosync_nodes,' ')

define puppet::binary::location ($fqdn = $title) {
cs_location { "postgresql_service_$fqdn":
  primitive => 'master_p_pgsql',
  node_name =>  "$fqdn",
  score     => '100'
} }



# Stopping postgresql befor adding it to the pacemaker
exec { "service postgresql stop":
  path    => ["/usr/bin", "/usr/sbin"]
} ->

# Creating postgresql resource in pacemaker
cs_resource {$postgres_resource_name:
  ensure          => present,
  primitive_class => 'ocf',
  provided_by     => 'heartbeat',
  primitive_type  => 'pgsql',
  parameters => {
    'pgctl'     => '/usr/lib/postgresql/9.3/bin/pg_ctl',
    'psql'      => '/usr/lib/postgresql/9.3/bin/psql',
    'pgdata'    => '/var/lib/postgresql/9.3/main',
    'conf'      => '/etc/postgresql/9.3/main/postgresql.conf',
    'rep_mode'  => 'sync',
    'node_list' => "$separate_corosync_nodes",
    'master_ip' => "$pgsql_vip",
    'restart_on_promote' => 'true',
  },
  complex_type => 'master',
  ms_metadata  => {
    'notify'          => 'true',
    'clone-node-max'  => '1',
    'master-max'      => '1',
    'master-node-max' => '3',
    'target-role'     => 'Master'
  },
  operations   => {
    'monitor'  => {
      'interval' => '4',
      'timeout'  => '60',
      'on-fail'  => 'restart',
    },
    'monitor:Master' => {
      'role'         => 'Master',
      'interval'     => '3',
      'timeout'      => '60',
      'on-fail'  => 'restart',
     },
    'start'  => {
      'interval' => '0',
      'timeout'  => '60',
      'on-fail'  => 'restart',
    },
    'stop'  => {
      'interval' => '0',
      'timeout'  => '60',
      'on-fail'  => 'block',
    },
    'promote'  => {
      'interval' => '0',
      'timeout'  => '60',
      'on-fail'  => 'restart',
    },
    'demote'  => {
      'interval' => '0',
      'timeout'  => '60',
      'on-fail'  => 'stop',
    },
    'notify'  => {
      'interval' => '0',
      'timeout'  => '60',
    },

  },
} ->

# colocate postgresql resource with its vip
cs_colocation { "pgsql_with_vip":
  primitives => [ "master_${postgres_resource_name}:Master", "$postgres_vip_name" ],
} ->

# order postgresql resource vip its vip during promote and demote
cs_order { "start_vip_before_pgsql_promote":
  first   => "master_$postgres_resource_name:Promote",
  second  => "$postgres_vip_name",
  score   => "INFINITY",
} ->

cs_order { "stop_vip_before_pgsql_demote":
  first   => "master_$postgres_resource_name:Demote",
  second  => "$postgres_vip_name",
  score   => "0",
} ->

puppet::binary::location { $corosync_nodes: }

