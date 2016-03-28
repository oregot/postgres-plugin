notice('MODULAR: postgres_database/firewall.pp')

$network_scheme   = hiera_hash('network_scheme', {})
$network_metadata = hiera_hash('network_metadata')
$ironic_hash      = hiera_hash('ironic', {})
$roles            = hiera('roles')
$postgresql_port               = 5432


Class['firewall'] -> Firewall<||>
Class['firewall'] -> Openstack::Firewall::Multi_net<||>
Class['firewall'] -> Firewallchain<||>

class {'::firewall':}


  firewall {'120-postgresql':
    port   => [$postgresql_port               ,],
    proto  => 'tcp',
    action => 'accept',
  }
