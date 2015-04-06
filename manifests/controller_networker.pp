class trystack::controller_networker {
  if $odl_rest_port == '' { $odl_rest_port= '8081'}
  if ($odl_flag != '') and str2bool($odl_flag) { 
     $ml2_mech_drivers = ['opendaylight']
     $this_agent = 'opendaylight'
  } else {
    $ml2_mech_drivers = ['openvswitch','l2population'] 
    $this_agent = 'ovs'
  }

  ##Mandatory Common variables
  if $admin_email == '' { fail('admin_email is empty') }
  if $ovs_tunnel_if == '' { fail('ovs_tunnel_if is empty') }

  ##Most users will only care about a single user/password for all services
  ##so lets create one variable that can be used instead of separate usernames/passwords
  if !$single_username { $single_username = 'octopus' }
  if !$single_password { $single_password = 'octopus' }

  if !$keystone_admin_token { $keystone_admin_token = $single_password }
  if !$neutron_metadata_shared_secret { $neutron_metadata_shared_secret = $single_password }
  if !$mysql_root_password { $mysql_root_password = $single_password }
  if !$admin_password { $admin_password = $single_password }

  ##Check for HA, if not leave old functionality alone
  if $ha_flag and str2bool($ha_flag) {
    ##Mandatory HA variables
    if !$controllers_ip_array { fail('controllers_ip_array is empty') }
    $controllers_ip_array_str = $controllers_ip_array
    $controllers_ip_array = split($controllers_ip_array, ',')
    if !$controllers_hostnames_array { fail('controllers_hostnames_array is empty') }
    $controllers_hostnames_array_str = $controllers_hostnames_array
    $controllers_hostnames_array = split($controllers_hostnames_array, ',')
    if !$amqp_vip { fail('amqp_vip is empty') }
    if !$private_subnet { fail('private_subnet is empty')}
    if !$cinder_admin_vip { fail('cinder_admin_vip is empty') }
    if !$cinder_private_vip { fail('cinder_private_vip is empty') }
    if !$cinder_public_vip { fail('cinder_public_vip is empty') }
    if !$db_vip { fail('db_vip is empty') }
    if !$glance_admin_vip { fail('glance_admin_vip is empty') }
    if !$glance_private_vip { fail('glance_private_vip is empty') }
    if !$glance_public_vip { fail('glance_public_vip is empty') }
    if !$horizon_admin_vip { fail('horizon_admin_vip is empty') }
    if !$horizon_private_vip { fail('horizon_private_vip is empty') }
    if !$horizon_public_vip { fail('horizon_public_vip is empty') }
    if !$keystone_admin_vip { fail('keystone_admin_vip is empty') }
    if !$keystone_private_vip { fail('keystone_private_vip is empty') }
    if !$keystone_public_vip { fail('keystone_public_vip is empty') }
    if !$loadbalancer_vip { fail('loadbalancer_vip is empty') }
    if !$neutron_admin_vip { fail('neutron_admin_vip is empty') }
    if !$neutron_private_vip { fail('neutron_private_vip is empty') }
    if !$neutron_public_vip { fail('neutron_public_vip is empty') }
    if !$nova_admin_vip { fail('nova_admin_vip is empty') }
    if !$nova_private_vip { fail('nova_private_vip is empty') }
    if !$nova_public_vip { fail('nova_public_vip is empty') }


    ##Optional HA variables
    if !$amqp_username  { $amqp_username = $single_username }
    if !$amqp_password  { $amqp_password = $single_password }
    if !$ceph_fsid { $ceph_fsid = '904c8491-5c16-4dae-9cc3-6ce633a7f4cc' }
    if !$ceph_images_key { $ceph_images_key = 'AQAfHBdUKLnUFxAAtO7WPKQZ8QfEoGqH0CLd7A==' }
    if !$ceph_mon_host { $ceph_mon_host= $controllers_ip_array }
    if !$ceph_mon_initial_members { $ceph_mon_initial_members = $controllers_hostnames_array}
    if !$ceph_osd_journal_size { $ceph_osd_journal_size = '1000' }
    if !$ceph_osd_pool_size { $ceph_osd_pool_size = '1' }
    if !$ceph_public_network { $ceph_public_network = $private_subnet }
    if !$ceph_volumes_key { $ceph_volumes_key = 'AQAfHBdUsFPTHhAAfqVqPq31FFCvyyO7oaOQXw==' }
    if !$cinder_db_password { $cinder_db_password = $single_password }
    if !$cinder_user_password { $cinder_user_password = $single_password }
    if !$cluster_control_ip { $cluster_control_ip = $controllers_ip_array[0] }
    if !$horizon_secret { $horizon_secret = $single_password }
    if !$glance_db_password { $glance_db_password = $single_password }
    if !$keystone_db_password { $keystone_db_password = $single_password }
    if !$keystone_user_password { $keystone_user_password = $single_password }
    if !$lb_backend_server_addrs { $lb_backend_server_addrs = $controllers_ip_array }
    if !$lb_backend_server_names { $lb_backend_server_names = $controllers_hostnames_array }
    if !$neutron_db_password  { $neutron_db_password = $single_password }
    if !$neutron_user_password  { $neutron_user_password = $single_password }
    if !$nova_db_password { $nova_db_password = $single_password }
    if !$nova_user_password { $nova_user_password = $single_password }
    if !$pcmk_server_addrs {$pcmk_server_addrs = $controllers_ip_array}
    if !$pcmk_server_names {$pcmk_server_names = ["pcmk-${controllers_hostnames_array[0]}", "pcmk-${controllers_hostnames_array[1]}", "pcmk-${controllers_hostnames_array[2]}"] }
    if !$rbd_secret_uuid { $rbd_secret_uuid = '3b519746-4021-4f72-957e-5b9d991723be' }
    if !$storage_iface { $storage_iface = $ovs_tunnel_if }

    ##we assume here that if not provided, the first controller is where ODL will reside
    ##this is fine for now as we will replace ODL with ODL HA when it is ready
    if $odl_control_ip == '' { $odl_control_ip =  $controllers_ip_array[0] }

    ###find interface ip of storage network
    $osd_ip = find_ip("",
                      "$storage_iface",
                      "")

    class { "trystack::ceph_deploy":
      fsid                     => $ceph_fsid,
      osd_pool_default_size    => $ceph_osd_pool_size,
      osd_pool_default_size    => $ceph_osd_journal_size,
      mon_initial_members      => $controllers_hostnames_array_str,
      mon_host                 => $controllers_ip_array_str,
      osd_ip                   => $osd_ip,
      public_network           => $ceph_public_network,
      cluster_network          => $ceph_public_network,
      images_key               => $ceph_images_key,
      volumes_key              => $ceph_volumes_key,
    }
    ->
    class { "quickstack::openstack_common": }
    ->
    class { "quickstack::pacemaker::params":
      amqp_password            => $amqp_password,
      amqp_username            => $amqp_username,
      amqp_vip                 => $amqp_vip,
      ceph_cluster_network     => $private_subnet,
      ceph_fsid                => $ceph_fsid,
      ceph_images_key          => $ceph_images_key,
      ceph_mon_host            => $ceph_mon_host, 
      ceph_mon_initial_members => $ceph_mon_initial_members,
      ceph_osd_journal_size    => $ceph_osd_journal_size,
      ceph_osd_pool_size       => $ceph_osd_pool_size,
      ceph_public_network      => $ceph_public_network,
      ceph_volumes_key         => $ceph_volumes_key,
      cinder_admin_vip         => $cinder_admin_vip,
      cinder_db_password       => $cinder_db_password,
      cinder_private_vip       => $cinder_private_vip,
      cinder_public_vip        => $cinder_public_vip,
      cinder_user_password     => $cinder_user_password,
      cluster_control_ip       => $cluster_control_ip,
      db_vip                   => $db_vip,
      glance_admin_vip         => $glance_admin_vip,
      glance_db_password       => $glance_db_password,
      glance_private_vip       => $glance_private_vip,
      glance_public_vip        => $glance_public_vip,
      glance_user_password     => $glance_user_password,
      heat_cfn_enabled         => 'false',
      horizon_admin_vip        => $horizon_admin_vip,
      horizon_private_vip      => $horizon_private_vip,
      horizon_public_vip       => $horizon_public_vip,
      include_ceilometer       => 'false',
      include_cinder           => 'true',
      include_glance           => 'true',
      include_heat             => 'false',
      include_horizon          => 'true',
      include_keystone         => 'true',
      include_neutron          => 'true',
      include_nosql            => 'false',
      include_nova             => 'true',
      include_swift            => 'false',
      keystone_admin_vip       => $keystone_admin_vip,
      keystone_db_password     => $keystone_db_password,
      keystone_private_vip     => $keystone_private_vip,
      keystone_public_vip      => $keystone_public_vip,
      keystone_user_password   => $keystone_user_password,
      lb_backend_server_addrs  => $lb_backend_server_addrs,
      lb_backend_server_names  => $lb_backend_server_names,
      loadbalancer_vip         => $loadbalancer_vip,
      neutron                  => 'true',
      neutron_admin_vip        => $neutron_admin_vip,
      neutron_db_password      => $neutron_db_password,
      neutron_metadata_proxy_secret  => $neutron_metadata_proxy_secret,
      neutron_private_vip      => $neutron_private_vip,
      neutron_public_vip       => $neutron_public_vip,
      neutron_user_password    => $neutron_user_password,
      nova_admin_vip           => $nova_admin_vip,
      nova_db_password         => $nova_db_password,
      nova_private_vip         => $nova_private_vip,
      nova_public_vip          => $nova_public_vip,
      nova_user_password       => $nova_user_password,
      pcmk_iface               => $ovs_tunnel_if,
      pcmk_server_addrs        => $pcmk_server_addrs,
      pcmk_server_names        => $pcmk_server_names,
      private_iface            => $ovs_tunnel_if,
    }
    ->
    class { "quickstack::pacemaker::common": }
    ->
    class { "quickstack::pacemaker::load_balancer": }
    ->
    class { "quickstack::pacemaker::galera":
      mysql_root_password     => $mysql_root_password,
      wsrep_cluster_members   => $controllers_ip_array,
    }
    ->
     class { "quickstack::pacemaker::qpid": }
    ->
    class { "quickstack::pacemaker::rabbitmq": }
    ->
    class { "quickstack::pacemaker::keystone":
      admin_email         =>  $admin_email,
      admin_password      =>  $admin_password,
      admin_token         =>  $keystone_admin_token,
      cinder              =>  'true',
      heat                =>  'false',
      heat_cfn            =>  'false',
      keystonerc          =>  'true',
      use_syslog          =>  'true',
      verbose             =>  'true',
    }
    ->
    class { "quickstack::pacemaker::swift": }
    ->
    class { "quickstack::pacemaker::glance":
      backend         => 'rbd',
      debug           => true,
      pcmk_fs_manage  => 'false',
      use_syslog      => true,
      verbose         => true
    }
    ->
    class { "quickstack::pacemaker::nova":
      neutron_metadata_proxy_secret => $neutron_metadata_shared_secret,
    }
    ->
    class { "quickstack::pacemaker::cinder":
      backend_rbd     => true,
      rbd_secret_uuid => $rbd_secret_uuid,
      use_syslog      => true,
      verbose         => true,
      volume          => true,
    }
    ->
    class { "quickstack::pacemaker::heat": }
    ->
    class { "quickstack::pacemaker::constraints": }

    class { "quickstack::pacemaker::nosql": }

    class { "quickstack::pacemaker::memcached": }

    class { "quickstack::pacemaker::ceilometer":
      ceilometer_metering_secret => $single_password,
    }

    class { "quickstack::pacemaker::horizon":
      horizon_ca       =>  '/etc/ipa/ca.crt',
      horizon_cert     =>  '/etc/pki/tls/certs/PUB_HOST-horizon.crt',
      horizon_key      =>  '/etc/pki/tls/private/PUB_HOST-horizon.key',
      secret_key       =>  $horizon_secret,
      verbose          =>  'true',
    }

    class { "quickstack::pacemaker::neutron":
      agent_type               =>  $this_agent,
      enable_tunneling         =>  'true',
      ml2_mechanism_drivers    =>  $ml2_mech_drivers,
      ml2_network_vlan_ranges  =>  ["physnet1:10:50"],
      odl_controller_ip        =>  $odl_control_ip,
      odl_controller_port      =>  $odl_rest_port,
      ovs_tunnel_iface         =>  $ovs_tunnel_if,
      ovs_tunnel_types         =>  ["vxlan"],
      verbose                  =>  'true',
    }

  } else {

    if $public_ip == '' { fail('public_ip is empty') }
    if $private_ip == '' { fail('private_ip is empty') }

    if $odl_control_ip == '' { $odl_control_ip = $private_ip }

    if $mysql_ip == '' { fail('mysql_ip is empty') }
    if $mysql_root_password == '' { fail('mysql_root_password is empty') }
    if $amqp_ip == '' { fail('amqp_ip is empty') }

    if $memcache_ip == '' { fail('memcache_ip is empty') }
    if $neutron_ip == '' { fail('neutron_ip is empty') }

    if $keystone_db_password == '' { fail('keystone_db_password is empty') }

    if $horizon_secret_key == '' { fail('horizon_secret_key is empty') }

    if $nova_user_password == '' { fail('nova_user_password is empty') }
    if $nova_db_password == '' { fail('nova_db_password is empty') }

    if $cinder_user_password == '' { fail('cinder_user_password is empty') }
    if $cinder_db_password == '' { fail('cinder_db_password is empty') }

    if $glance_user_password == '' { fail('glance_user_password is empty') }
    if $glance_db_password == '' { fail('glance_db_password is empty') }

    if $neutron_user_password == '' { fail('neutron_user_password is empty') }
    if $neutron_db_password == '' { fail('neutron_db_password is empty') }
    if $neutron_metadata_shared_secret == '' { fail('neutron_metadata_shared_secret is empty') }

    if $ceilometer_user_password == '' { fail('ceilometer_user_password is empty') }
    if $ceilometer_metering_secret == '' { fail('ceilometer_user_password is empty') }

    if $heat_user_password == '' { fail('heat_user_password is empty') }
    if $heat_db_password == '' { fail('heat_db_password is empty') }
    if $heat_auth_encrypt_key == '' { fail('heat_auth_encrypt_key is empty') }

    if $swift_user_password == '' { fail('swift_user_password is empty') }
    if $swift_shared_secret == '' { fail('swift_shared_secret is empty') }
    if $swift_admin_password == '' { fail('swift_admin_password is empty') }

    class { "quickstack::neutron::controller_networker":
      admin_email                   => $admin_email,
      admin_password                => $admin_password,
      agent_type                    => $this_agent,
      enable_tunneling              => true,
      ovs_tunnel_iface              => $ovs_tunnel_if,
      ovs_tunnel_network            => '',
      ovs_tunnel_types              => ['vxlan'],
      ovs_l2_population             => 'True',
      external_network_bridge       => 'br-ex',
      tenant_network_type           => 'vxlan',
      tunnel_id_ranges              => '1:1000',
      controller_admin_host         => $private_ip,
      controller_priv_host          => $private_ip,
      controller_pub_host           => $public_ip,
      ssl                           => false,
      #support_profile               => $quickstack::params::support_profile,
      #freeipa                       => $quickstack::params::freeipa,

      mysql_host                    => $mysql_ip,
      mysql_root_password           => $mysql_root_password,
      #amqp_provider                 => $amqp_provider,
      amqp_host                     => $amqp_ip,
      amqp_username                 => 'guest',
      amqp_password                 => 'guest',
      #amqp_nssdb_password           => $quickstack::params::amqp_nssdb_password,

      keystone_admin_token          => $keystone_admin_token,
      keystone_db_password          => $keystone_db_password,

      ceilometer_metering_secret    => $ceilometer_metering_secret,
      ceilometer_user_password      => $ceilometer_user_password,

      cinder_backend_gluster        => $quickstack::params::cinder_backend_gluster,
      cinder_backend_gluster_name   => $quickstack::params::cinder_backend_gluster_name,
      cinder_gluster_shares         => $quickstack::params::cinder_gluster_shares,
      cinder_user_password          => $cinder_user_password,
      cinder_db_password            => $cinder_db_password,

      glance_db_password            => $glance_db_password,
      glance_user_password          => $glance_user_password,

      heat_cfn                      => true,
      heat_cloudwatch               => true,
      heat_db_password              => $heat_db_password,
      heat_user_password            => $heat_user_password,
      heat_auth_encrypt_key         => $heat_auth_encrypt_key,

      horizon_secret_key            => $horizon_secret_key,
      horizon_ca                    => $quickstack::params::horizon_ca,
      horizon_cert                  => $quickstack::params::horizon_cert,
      horizon_key                   => $quickstack::params::horizon_key,
 
      ml2_mechanism_drivers         => $ml2_mech_drivers,

      #neutron                       => true,
      neutron_metadata_proxy_secret => $neutron_metadata_shared_secret,
      neutron_db_password           => $neutron_db_password,
      neutron_user_password         => $neutron_user_password,

      nova_db_password              => $nova_db_password,
      nova_user_password            => $nova_user_password,

      odl_controller_ip             => $odl_control_ip,
      odl_controller_port           => $odl_rest_port,

      swift_shared_secret           => $swift_shared_secret,
      swift_admin_password          => $swift_admin_password,
      swift_ringserver_ip           => '192.168.203.1',
      swift_storage_ips             => ["192.168.203.2","192.168.203.3","192.168.203.4"],
      swift_storage_device          => 'device1',
    }

  }
}
