#!/bin/bash

## Set environment variables
PGDATA="/var/lib/pgsql/10/data"
RPDATA="/tmp/repmgr/data"

## Install repmgr
yum -y install https://rpm.2ndquadrant.com/site/content/2ndquadrant-repo-10-1-1.el7.noarch.rpm
yum -y install repmgr10

## Configure postgres
su - postgres -c "pg_ctl -D ${PGDATA} -mf stop"
sed -i "s/#hot_standby = off/hot_standby = on/" ${PGDATA}/postgresql.conf
echo "local repmgr      repmgr             trust" >> ${PGDATA}/pg_hba.conf
echo "local replication repmgr             trust" >> ${PGDATA}/pg_hba.conf
echo "host  repmgr      repmgr 127.0.0.1/0 trust" >> ${PGDATA}/pg_hba.conf
echo "host  replication repmgr 127.0.0.1/0 trust" >> ${PGDATA}/pg_hba.conf
su - postgres -c "pg_ctl -D ${PGDATA} -l logfile start"

## Create repmgr user and database (for demo)
createuser -s repmgr
createdb repmgr -O repmgr

## Create standby data dir
mkdir -p ${RPDATA}
chown -R postgres:postgres ${RPDATA}
chmod 700 ${PGDATA}

## Configure repmgr for master node
echo "node_id=1" >> /etc/repmgr.conf
echo "node_name=node1" >> /etc/repmgr.conf
echo "conninfo='host=127.0.0.1 port=5432 user=repmgr dbname=repmgr connect_timeout=2'" >> /etc/repmgr.conf
echo "data_directory='${PGDATA}'" >> /etc/repmgr.conf

## Register master node to repmgr
su - postgres -c "repmgr -f /etc/repmgr.conf primary register"
su - postgres -c "repmgr -f /etc/repmgr.conf cluster show"

## Configure repmgr for standby node
echo "node_id=2" >> /etc/repmgr2.conf
echo "node_name=node2" >> /etc/repmgr2.conf
echo "conninfo='host=127.0.0.1 port=5433 user=repmgr dbname=repmgr connect_timeout=2'" >> /etc/repmgr2.conf
echo "data_directory='${RPDATA}'" >> /etc/repmgr2.conf

## Create some data
psql repmgr -c "CREATE TABLE foo (id int, name text)"
psql repmgr -c "INSERT INTO foo VALUES (generate_series(1,100000),'bar')"

## Clone the master node into the standby node
su - postgres -c "repmgr -h 127.0.0.1 -U repmgr -d repmgr -f /etc/repmgr2.conf standby clone"

## Start up the standby node
echo "port = 5433" >> ${RPDATA}/postgresql.conf
su - postgres -c "pg_ctl -D ${RPDATA} -l logfile start"

## Verify replication worked
psql -p5433 repmgr -c "SELECT count(*), 'should be 100,000' FROM foo"
psql repmgr -c "INSERT INTO foo VALUES (generate_series(100001,200000),'bar')"
sleep 10;
psql -p5433 repmgr -c "SELECT count(*), 'should be 200,000' FROM foo"

## Register master node to repmgr
su - postgres -c "repmgr -f /etc/repmgr2.conf standby register"
sleep 5;
su - postgres -c "repmgr -f /etc/repmgr2.conf cluster show"
