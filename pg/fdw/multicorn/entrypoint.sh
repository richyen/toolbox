#!/bin/bash

# Install -contrib on db2
if [[ ${HOSTNAME} == 'pg2' ]]; then
  echo "Installing -contrib"
  yum -y install postgresql${PGMAJOR}-contrib
fi

# Start up postgres on all containers
su - postgres -c "pg_ctl -D /var/lib/pgsql/${PGMAJOR}/data start"

# Create demo schema
if [[ ${HOSTNAME} == 'multicorn1' ]]; then
  pgbench -iU postgres postgres
else
  yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  yum -y install centos-release-scl-rh
  yum -y install postgresql13-devel centos-release-scl-rh llvm-devel vim git python3-devel
  yum -y groupinstall development
  git clone https://github.com/Segfault-Inc/Multicorn.git
  cd Multicorn && make && make install
  psql -c "create extension multicorn" postgres postgres
fi

# Keep things running
tail -f /dev/null
