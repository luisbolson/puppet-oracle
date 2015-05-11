$pass = 'ora123'
$salt = 'xyz'
$confdir = "$settings::confdir"

package {'aws-sdk':
  provider => 'gem',
  ensure   => present,
  }

$host_instances = {
  "${fqdn}" => {
    ip            => $ipaddress,
    host_aliases  => $hostname,
  },
  localhost => {
    ip            => '127.0.0.1',
    host_aliases  =>  ['localhost.localdomain','localhost4','localhost4.localdomain4'],
  },
}

create_resources('host',$host_instances)

# disable the firewall
service { 'iptables':
  enable    => false,
  ensure    => false,
  hasstatus => true,
}

# set the tmpfs - will be worked on later
/*
mount { '/dev/shm':
  ensure      => present,
  atboot      => true,
  device      => 'tmpfs',
  fstype      => 'tmpfs',
  options     => "size=${oramem}M",
}
*/

$all_groups = ['oinstall','dba' ,'oper']
group { $all_groups :
  ensure      => present,
}

user { 'oracle' :
  ensure      => present,
  uid         => 500,
  gid         => 'oinstall',
  groups      => ['oinstall','dba','oper'],
  shell       => '/bin/bash',
  password    => inline_template("<%= '$pass'.crypt('\$6$$salt') %>"),
  home        => "/home/oracle",
  comment     => "This user oracle was created by Puppet",
  require     => Group[$all_groups],
  managehome  => true,
}

file {"${settings::confdir}/modules/oradb/files":
    ensure  =>  directory,
}

s3 { "${settings::confdir}/modules/oradb/files/linuxamd64_12102_database_1of2.zip":
    # Required paramters:
    ensure              => present,
    source              => '/lhb/software/oracle/db_linuxamd64_12102/linuxamd64_12102_database_1of2.zip',
    access_key_id       => $awskey,
    secret_access_key   => $awssecret,
    # Optional parameters:
    region              => 'us-east-1', # Defaults to us-east-1
    require             => [
      Package['aws-sdk'],
      File["${settings::confdir}/modules/oradb/files"],
    ],
}

s3 { "${settings::confdir}/modules/oradb/files/linuxamd64_12102_database_2of2.zip":
    # Required paramters:
    ensure              => present,
    source              => '/lhb/software/oracle/db_linuxamd64_12102/linuxamd64_12102_database_2of2.zip',
    access_key_id       => $awskey,
    secret_access_key   => $awssecret,
    # Optional parameters:
    region              => 'us-east-1', # Defaults to us-east-1
    require             => S3["${settings::confdir}/modules/oradb/files/linuxamd64_12102_database_1of2.zip"],
}

$install = [ 'binutils.x86_64','bind-utils.x86_64','compat-libstdc++-33.x86_64', 'glibc.x86_64','ksh.x86_64','libaio.x86_64',
             'libgcc.x86_64', 'libstdc++.x86_64', 'make.x86_64','compat-libcap1.x86_64', 'gcc.x86_64',
             'gcc-c++.x86_64','glibc-devel.x86_64','libaio-devel.x86_64','libstdc++-devel.x86_64',
             'sysstat.x86_64','unixODBC-devel','glibc.i686','libXext.x86_64','libXtst.x86_64','bc.x86_64',
             'nfs-utils.x86_64','smartmontools.x86_64','xorg-x11-utils.x86_64','xorg-x11-xauth.x86_64','zip.x86_64','unzip.x86_64']
package { $install:
  ensure  => present,
}

package { 'oracle-rdbms-server-11gR2-preinstall-1.0-10.el6.x86_64':
  ensure  => present,
  provider => 'rpm',
  source  => "${settings::confdir}/files/oracle-rdbms-server-11gR2-preinstall-1.0-10.el6.x86_64.rpm",
  require => Package[$install],
}

$puppetDownloadMntPoint = "puppet:///modules/oradb/"

oradb::installdb{ '12.1.0.2_Linux-x86-64':
  version                => '12.1.0.2',
  file                   => 'linuxamd64_12102_database',
  databaseType           => 'EE',
  oracleBase             => '/u01/app/oracle',
  oracleHome             => '/u01/app/oracle/product/12.1.0.2/db',
  bashProfile            => true,
  user                   => 'oracle',
  group                  => 'dba',
  group_install          => 'oinstall',
  group_oper             => 'oper',
  downloadDir            => '/u01/app/oracle/install',
  zipExtract             => true,
  puppetDownloadMntPoint => $puppetDownloadMntPoint,
  require => [
    S3["${settings::confdir}/modules/oradb/files/linuxamd64_12102_database_1of2.zip"],
    S3["${settings::confdir}/modules/oradb/files/linuxamd64_12102_database_2of2.zip"],
    Package['oracle-rdbms-server-11gR2-preinstall-1.0-10.el6.x86_64'],
  ],
}