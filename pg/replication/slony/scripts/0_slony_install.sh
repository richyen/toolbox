#!/bin/bash

### To use EDB RPM
# export YUMUSERNAME=''
# export YUMPASSWORD=''
# rpm -ivh http://yum.enterprisedb.com/edbrepos/edb-repo-latest.noarch.rpm
# sed -i "s/<username>:<password>/${YUMUSERNAME}:${YUMPASSWORD}/" /etc/yum.repos.d/edb.repo
# yum -y install yum-plugin-ovl
# yum -y install epel-release perl-DBD-Pg
# yum -y --enablerepo=edbas10 --enablerepo=enterprisedb-tools --enablerepo=enterprisedb-dependencies install edb-as10-server edb-as10-slony-replication

### To use PGDG RPM
export PGVERSION=11
yum -y install slony1-${PGVERSION}

### To compile from source
# SLON_VER=2.2
# PG_BIN=/usr/pgsql-${PGVERSION}/bin
# yum -y install wget tar bzip2 gcc
# wget http://main.slony.info/downloads/${SLON_VER}/source/slony1-${SLON_VER}.4.tar.bz2
# tar -xvjf slony1-${SLON_VER}.4.tar.bz2
# cd slony1-${SLON_VER}.4
# ./configure --with-perltools --with-pgconfigdir=${PG_BIN}
# gmake all
# gmake install
