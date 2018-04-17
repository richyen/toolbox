#!/bin/bash

export YUMUSERNAME=''
export YUMPASSWORD=''

rpm -ivh http://yum.enterprisedb.com/edbrepos/edb-repo-latest.noarch.rpm
sed -i "s/<username>:<password>/${YUMUSERNAME}:${YUMPASSWORD}/" /etc/yum.repos.d/edb.repo
sed -i "s/enabled.*/enabled=1/" /etc/yum.repos.d/edb.repo
yum -y install yum-plugin-ovl
yum -y install epel-release perl-DBD-Pg
yum -y install ppas93-server-core

# Need to download Slony (aka ppas9x-replication-core) first
# rpm -ivh /Desktop/ppas93-replication-core-2.2.1-3.rhel6.x86_64.rpm
