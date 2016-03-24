notice('MODULAR: postgres_database.pp')


class { 'postgresql::globals':
  encoding => 'UTF8',
} ->

class { 'postgresql::server':
  listen_addresses        => '0.0.0.0',
  ip_mask_allow_all_users => '0.0.0.0/0',

} ->

exec { "service postgresql stop":
  path    => ["/usr/bin", "/usr/sbin"]
}


notice('MODULAR: postgres_database.pp')


$postgres_resource_name = 'p_pgsql'
$postgres_vip_name = 'vip__pgsql'

$postgres_vip_ip = '1.1.1.1'
$postgres_vip_mask = '24'

  cs_resource {$postgres_resource_name:
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'hearbeat',
      primitive_type  => 'pgsql',
#      metadata        => {
#        'migration-threshold' => 'INFINITY',
#        'failure-timeout'     => '180s'
#      },
      parameters => {
        'pgctl'     => '/usr/lib/postgresql/9.3/bin/pg_ctl',
        'psql'      => '/usr/lib/postgresql/9.3/bin/psql',
        'pgdata'    => '/var/lib/postgresql/9.3/main',
        'rep_mode'  => 'sync',
        'node_list' => 'node-20',
        'master_ip' => '1.1.1.1',
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
    }

cs_primitive { "${postgres_vip_name}":
  primitive_class => 'ocf',
  primitive_type  => 'IPaddr2',
  provided_by     => 'heartbeat',
  parameters      => { 'ip' => "${postgres_vip_ip}", 'cidr_netmask' => "${postgres_vip_mask}" },
  operations      => {'monitor' => { 'interval' => '10' , 'timeout' => '60' },
                      'start' => { 'interval' => '0' , 'timeout' => '60' },
                      'stop' => { 'interval' => '0' , 'timeout' => '60' },
}
}


cs_colocation { "pgsql_with_vip":
      primitives => [ "master_${postgres_resource_name}:Master", "$postgres_vip_name" ],
    }

cs_order { "start_vip_before_pgsql_promote":
  first   => "master_$postgres_resource_name:Promote",
  second  => "$postgres_vip_name",
  score   => "INFINITY",
}

cs_order { "stop_vip_before_pgsql_demote":
  first   => "master_$postgres_resource_name:Demote",
  second  => "$postgres_vip_name",
  score   => "0",
}

