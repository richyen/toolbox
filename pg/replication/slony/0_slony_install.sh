#!/bin/bash

export YUMUSERNAME=''
export YUMPASSWORD=''

rpm -ivh http://yum.enterprisedb.com/edbrepos/edb-repo-latest.noarch.rpm
sed -i "s/<username>:<password>/${YUMUSERNAME}:${YUMPASSWORD}/" /etc/yum.repos.d/edb.repo
sed -i "s/enabled.*/enabled=1/" /etc/yum.repos.d/edb.repo
yum -y install yum-plugin-ovl
yum -y install epel-release perl-DBD-Pg

### To use EDB RPM
yum -y install ppas93-server-core

# Need to download Slony (aka ppas9x-replication-core) first
# rpm -ivh /Desktop/ppas93-replication-core-2.2.1-3.rhel6.x86_64.rpm


### To compile from source
# SLON_VER=2.2
# PG_BIN=/usr/ppas-9.5/bin
# yum -y install wget tar bzip2 gcc
# wget http://main.slony.info/downloads/${SLON_VER}/source/slony1-${SLON_VER}.4.tar.bz2
# tar -xvjf slony1-${SLON_VER}.4.tar.bz2
# cd slony1-${SLON_VER}.4
# ./configure --with-perltools --with-pgconfigdir=${PG_BIN}
# gmake all
# gmake install
