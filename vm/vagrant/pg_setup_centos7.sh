#!/bin/bash

### Set environment variables
export PGMAJOR=10
export REPONAME=pgdg${PGMAJOR}
export PGPORT=5432
export PGDATABASE=postgres
export PGUSER=postgres
export PATH=/usr/pgsql/${PGMAJOR}/bin:${PATH}
export PGDATA=/var/lib/pgsql/${PGMAJOR}/data
export PGLOG=/var/lib/pgsql/${PGMAJOR}/pgstartup.log

### Install basic packages
yum -y update
yum -y install yum-plugin-ovl
yum -y install epel-release sudo vim

### Install EDB Advanced Server
rpm -ivh https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum -y install postgresql${PGMAJOR}-server

### Create OS user
echo 'root:root'|chpasswd
adduser --home-dir /home/postgres --create-home postgres
echo 'postgres   ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers
echo 'postgres:postgres'|chpasswd

### Initialize database
rm -rf ${PGDATA}
sudo -u ${PGUSER} /usr/pgsql-${PGMAJOR}/bin/initdb -D ${PGDATA}

### Customize config files
# sed -i "s/^PGPORT.*/PGPORT=${PGPORT}/" /etc/sysconfig/edb/as${PGMAJOR}/edb-as-${PGMAJOR}.sysconfig
echo "export PGPORT=${PGPORT}"         >> /etc/profile.d/pg_env.sh
echo "export PGDATABASE=${PGDATABASE}" >> /etc/profile.d/pg_env.sh
echo "export PGUSER=${PGUSER}"         >> /etc/profile.d/pg_env.sh
echo "export PATH=${PATH}"             >> /etc/profile.d/pg_env.sh
echo "local  all         all                 trust" >  ${PGDATA}/pg_hba.conf
echo "local  replication all                 trust" >> ${PGDATA}/pg_hba.conf
echo "host   replication repuser  0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf
echo "host   all         all      0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf
sed -i "s/^port = .*/port = ${PGPORT}/"         ${PGDATA}/postgresql.conf
sed -i "s/^logging_collector = off/logging_collector = on/" ${PGDATA}/postgresql.conf
sed -i "s/^#wal_level.*/wal_level=hot_standby/" ${PGDATA}/postgresql.conf
sed -i "s/^#wal_keep_segments = 0/wal_keep_segments = 500/" ${PGDATA}/postgresql.conf
sed -i "s/^#max_wal_senders = 0/max_wal_senders = 5/" ${PGDATA}/postgresql.conf

### Start Postgres
systemctl start postgresql-${PGMAJOR}
