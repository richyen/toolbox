#!/bin/bash


### This script takes a BART Docker container and demonstrates how to use incremental backup
### This script also attempts to reproduce issue BART-271, where a VACUUM causes errors upon restore

set -x
set -e
BART_PATH=/usr/edb/bart/bin
export PGUSER=enterprisedb
export PGDATABASE=edb
export PGPORT=5432
export BART_SERVER=epas

mkdir -p /opt/backups
chown enterprisedb:enterprisedb /opt/backups
#cp /Desktop/bart.cfg /usr/edb/bart/etc/
sudo -u enterprisedb ${BART_PATH}/bart init
service edb-as-10 initdb
sed -i -e "s/peer/trust/" -e "s/ident/trust/" /var/lib/edb/as10/data/pg_hba.conf
#sed -i -e "s/#archive_mode.*/archive_mode = on/" -e "s/#archive_command.*/archive_command = 'cp %p \/opt\/backups\/production\/archived_wals\/%f'/" /var/lib/edb/as10/data/postgresql.conf
service edb-as-10 restart
#psql -qc "CREATE EXTENSION bart_helpers" edb
sudo -u enterprisedb ${BART_PATH}/bart-scanner reload

## ssh auth is required in some instances for unknown reasons
SSHDIR="/var/lib/edb/.ssh"
echo 'enterprisedb:enterprisedb'|chpasswd
yum -q -y install wget
mkdir -p ${SSHDIR}
wget -qO ${SSHDIR}/id_rsa "https://www.dropbox.com/s/ko3ygh7homysv6c/dirty_ssh.pem?dl=1"
chown -R enterprisedb:enterprisedb ${SSHDIR}
chmod 700 ${SSHDIR}
chmod 600 ${SSHDIR}/id_rsa
ssh-keygen -y -f ${SSHDIR}/id_rsa > ${SSHDIR}/authorized_keys
chmod 644 ${SSHDIR}/authorized_keys
echo "Host *" >> ${SSHDIR}/config
echo "    StrictHostKeyChecking no" >> ${SSHDIR}/config
chmod 644 ${SSHDIR}/config

# Generate backups
for ((i=0;i<10;i++)); do
   psql -qc "CREATE TABLE table${i} (id serial primary key, first_name text not null default md5(random()::text), last_name text not null default md5(random()::text))" edb;
   psql -qc "INSERT INTO table${i} VALUES (generate_series(1,100),default,default)" edb;
   psql -qc "CREATE TABLE more_table${i} (id serial primary key, first_name text not null default md5(random()::text), last_name text not null default md5(random()::text))" edb;
   psql -qc "INSERT INTO more_table${i} VALUES (generate_series(1,100),default,default)" edb;
done
sudo -u enterprisedb ${BART_PATH}/bart backup -s ${BART_SERVER} --backup-name full1 -F t
psql -c "vacuum full"
sudo -iu enterprisedb ${BART_PATH}/bart backup -s ${BART_SERVER} --backup-name inc1 --parent full1 -F p
sudo -iu enterprisedb ${BART_PATH}/bart backup -s ${BART_SERVER} --backup-name inc2 --parent full1 -F p
sudo -u enterprisedb ${BART_PATH}/bart show-backups -s ${BART_SERVER}
service edb-as-10 stop

# Restore
NEW_PGDATA=/tmp/data
NEW_PGPORT=5442
mkdir ${NEW_PGDATA}
chown enterprisedb:enterprisedb ${NEW_PGDATA}
sudo -u enterprisedb ${BART_PATH}/bart restore -s ${BART_SERVER} -i inc1 -p ${NEW_PGDATA}
sed -i "s/${PGPORT}/${NEW_PGPORT}/" ${NEW_PGDATA}/postgresql.conf

# Start PG
chmod 700 ${NEW_PGDATA}
sudo -u enterprisedb /usr/edb/as10/bin/pg_ctl -l /tmp/logfile -D ${NEW_PGDATA} start
psql -p${NEW_PGPORT} -c "select * from table1 limit 10"

# Restore
NEW_PGDATA=/tmp/data2
NEW_PGPORT=5443
mkdir ${NEW_PGDATA}
chown enterprisedb:enterprisedb ${NEW_PGDATA}
sudo -u enterprisedb ${BART_PATH}/bart restore -s ${BART_SERVER} -i inc2 -p ${NEW_PGDATA}
sed -i "s/${PGPORT}/${NEW_PGPORT}/" ${NEW_PGDATA}/postgresql.conf

# Start PG
chmod 700 ${NEW_PGDATA}
sudo -u enterprisedb /usr/edb/as10/bin/pg_ctl -l /tmp/logfile -D ${NEW_PGDATA} start
psql -p${NEW_PGPORT} -c "select * from table1 limit 10"
