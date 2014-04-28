class trystack::highavailability {

    class {'pacemaker::corosync':
        cluster_name => 'trystack',
        cluster_members => '10.100.0.1 10.100.0.3 10.100.0.16',
    }

    class {'pacemaker::stonith':
        disable => true,
    }

    pacemaker::resource::ip { 'ip-10.100.0.200':
        ip_address => '10.100.0.200',
        group => 'test',
        ensure => 'absent',
    }

    pacemaker::resource::lsb { 'tgtd':
        clone => true,
        ensure => 'absent',
    }

    pacemaker::resource::ip { 'ip-10.100.0.225':
        ip_address => '10.100.0.225',
        group => 'trystack_qpid',
    }
    pacemaker::resource::lsb { 'qpidd':
        group => 'trystack_qpid',
        require => Pacemaker::Resource::Ip['ip-10.100.0.225'],
    }

    pacemaker::resource::ip { 'ip-8.21.28.222':
        ip_address => '8.21.28.222',
        group => 'trystack',
    }
    pacemaker::resource::ip { 'ip-10.100.0.222':
        ip_address => '10.100.0.222',
        group => 'trystack',
    }
    pacemaker::resource::lsb {'haproxy':
        group => 'trystack',
        require => [Pacemaker::Resource::Ip['ip-8.21.28.222'],
                    Pacemaker::Resource::Ip['ip-10.100.0.222'],]
    }

    pacemaker::resource::lsb {'openstack-nova-novncproxy':
        group => 'trystack',
        require => Pacemaker::Resource::Lsb['haproxy'],
    }

    pacemaker::resource::ip { 'ip-10.100.0.221':
        ip_address => '10.100.0.221',
        group => 'trystack_mysql',
    }
    pacemaker::resource::filesystem { "mysql_storage":
        device => "host13:/mysql",
        directory => "/var/lib/mysql/data",
        fstype => "glusterfs",
        group => 'trystack_mysql',
    }

    pacemaker::resource::mysql {'mysqld':
        name => 'mysqld',
        group => 'trystack_mysql',
        additional_params => 'datadir=/var/lib/mysql/data/ pid=/var/run/mysqld/mysql.pid socket=/var/lib/mysql/mysql.sock',
        require => [Pacemaker::Resource::Filesystem['mysql_storage'],
                    Pacemaker::Resource::Ip['ip-10.100.0.221'],],
    }

    pacemaker::constraint::location{'mysql-avoid':
        ensure => absent,
        resource => 'trystack_qpid',
        location => '10.100.0.1',
        score => 1,
        #score => '-INFINITY',
    }

    pacemaker::constraint::colocation{'colo-qpid':
        ensure => absent,
        source => 'lsb-qpidd',
        target => 'ip-10.100.0.225',
        #score => 1,
        score => 'INFINITY',
    }

    #pacemaker::stonith::ipmilan { '$ipmi_address':
    #    address  => '$ipmi_address',
    #    user     => '$ipmi_user',
    #    password => '$ipmi_pass',
    #    hostlist => '$ipmi_host_list',
    #}
}
