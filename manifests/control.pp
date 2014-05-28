class trystack::control() {

    include '::ntp'
    # _ts (trystack) suffix is to workaround naming conflics

    package{ ['openstack-selinux', 'glusterfs-fuse']:
        ensure => present,
    }

    class { "trystack::control::amqp": }
    class { "trystack::control::mysql": }
    class { "trystack::control::keystone_ts":
        require => Service["mysqld"],
    }
    class { "trystack::control::nova_ts":
        require => [Service["mysqld"], Service['rabbitmq-server']]
    }
    class { "trystack::control::glance":
        require => [Service["mysqld"], Service['rabbitmq-server']]
    }
    class { "trystack::control::horizon_ts":
        require => [Service["mysqld"], Service['rabbitmq-server']]
    }
    class { "trystack::facebook":
        require => Class["trystack::control::horizon_ts"],
    }
    class { "trystack::control::cinder_ts":
        require => [Service["mysqld"], Service['rabbitmq-server'],
                    Class["trystack::control::keystone_ts"]]
    }
    class { "trystack::control::ceilometer_ts":
        require => [Service["mysqld"], Service['rabbitmq-server'],
                    Class["trystack::control::keystone_ts"]]
    }
    class { "trystack::swift::proxy_ts": }
    class { "trystack::control::heat_ts": }
}

