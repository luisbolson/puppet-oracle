#!/bin/bash
#curl https://raw.githubusercontent.com/luisbolson/puppet-oracle/master/puppet-oracle.sh | bash

rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional rhui-REGION-rhel-server-releases
yum install puppet git wget rubygems -y
rm -rf /etc/puppet
cd /etc
git clone https://github.com/luisbolson/puppet-oracle.git puppet

export FACTER_awskey=$1
export FACTER_awssecret=$2

puppet apply --verbose /etc/puppet/manifests/pre-install.pp