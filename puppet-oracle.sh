#!/bin/bash
rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional
yum install puppet git wget -y
rm -rf /etc/puppet
cd /etc
git clone git@github.com:luisbolson/puppet-oracle.git puppet
puppet apply --verbose /etc/puppet/manifests/pre-install.pp