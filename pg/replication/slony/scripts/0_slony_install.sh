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
yum -y install perl
yum -y install slony1-${PGVERSION}

### To compile from source
# VER_MAJ=2.2
# VER_MIN=8
# SLON_VER=slony1-${VER_MAJ}.${VER_MIN}
# PG_BIN=/usr/pgsql-${PGVERSION}/bin
# yum -y groupinstall "Development Tools"
# yum -y install wget tar bzip2 gcc postgresql${PGVERSION//./}-devel
# wget http://main.slony.info/downloads/${VER_MAJ}/source/${SLON_VER}.tar.bz2
# tar -xvjf ${SLON_VER}.tar.bz2
# cd ${SLON_VER}
# ./configure --with-perltools --with-pgconfigdir=${PG_BIN}
# make all
# make install
