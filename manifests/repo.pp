class trystack::repo {
  if $::osfamily == 'RedHat' {
    if $proxy_address != '' {
      $myline= "proxy=${proxy_address}"
      include stdlib
      file_line { 'yumProxy':
        ensure => present,
        path   => '/etc/yum.conf',
        line   => $myline,
        before => Yumrepo['openstack-juno'],
      }
    }

    yumrepo { "openstack-juno":
      baseurl => "http://repos.fedorapeople.org/repos/openstack/openstack-juno/epel-7/",
      descr => "RDO Community repository",
      enabled => 1,
      gpgcheck => 0,
    }

    yumrepo { 
            "ceph":
                   baseurl => "http://ceph.com/rpm-giant/el7/\$basearch",
                   descr => "Ceph packages for \$basearch",
                   enabled => 1,
                   gpgcheck => 0;
            "Ceph-noarch":
                   baseurl => "http://ceph.com/rpm-giant/el7/noarch",
                   descr => "Ceph noarch packages",
                   enabled => 1,
                   gpgcheck => 0;
            "ceph-source":
                   baseurl => "http://ceph.com/rpm-giant/el7/SRPMS",
                   descr => "Ceph source packages",
                   enabled => 1,
                   gpgcheck => 0;
    }

    
  }
}
