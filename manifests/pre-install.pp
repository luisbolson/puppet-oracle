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

/*
sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096',}
sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}
 class { 'limits':
  config => {
             '*'       => { 'nofile'  => { soft => '2048'   , hard => '8192',   },},
             'oracle'  => { 'nofile'  => { soft => '65536'  , hard => '65536',  },
                             'nproc'  => { soft => '2048'   , hard => '16384',  },
                             'stack'  => { soft => '10240'  ,},},
             },
  use_hiera => false,
}
*/

s3 { '${settings::confdir}/modules/oradb/files':
    # Required paramters:
    ensure              => present,
    source              => '/lhb/software/oracle/db_linuxamd64_12102/linuxamd64_12102_database_1of2.zip',
    access_key_id       => 'mysecret',
    secret_access_key   => 'anothersecret',
    # Optional parameters:
    region              => 'us-east-1', # Defaults to us-east-1
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
/*
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
}*/