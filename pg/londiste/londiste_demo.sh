#!/bin/bash

set -e
set -x

### Set up Databases
MASTER_DB='postgres'
SLAVE_DB='londiste'
psql -c "create table mytable (id serial primary key, first_name text, last_name text, birthdate timestamptz)" ${MASTER_DB} postgres
psql -c "insert into mytable values (generate_series(1,1000), md5(random()::text), md5(random()::text), NOW() - '1 month'::INTERVAL * ROUND(RANDOM() * 100))" ${MASTER_DB} postgres
createdb -U postgres ${SLAVE_DB}
pg_dump -s -U postgres ${MASTER_DB} | psql ${SLAVE_DB} postgres

### Install Londiste and dependencies
yum -y install skytools-94 skytools-94-modules

### Set up queueing/ticker system
mkdir -pv ~postgres/londiste-config/{log,pid}
cd ~postgres/londiste-config
cat << EOF > ticker.ini
[pgqd]
base_connstr = user=postgres host=127.0.0.1
database_list = ${MASTER_DB}
logfile = log/ticker.log
pidfile = pid/ticker.pid
EOF
pgqd -d ticker.ini 

### Register the master DB and start worker
cat << EOF > master.ini
[londiste3]
db = user=postgres host=127.0.0.1 dbname=${MASTER_DB}
queue_name = myappq
loop_delay = 0.5
logfile = log/master.log
pidfile = pid/master.pid
EOF
londiste3 master.ini create-root master "user=postgres host=127.0.0.1 dbname=${MASTER_DB}"
londiste3 -d master.ini worker

### Register the slave DB and start worker
cat << EOF > slave.ini
[londiste3]
db = user=postgres host=127.0.0.1 dbname=${SLAVE_DB}
queue_name = myappq
loop_delay = 0.5
logfile = log/slave.log
pidfile = pid/slave.pid
EOF
londiste3 slave.ini create-leaf slave "user=postgres host=127.0.0.1 dbname=${SLAVE_DB}" --provider="user=postgres host=127.0.0.1 dbname=${MASTER_DB}"
londiste3 -d slave.ini worker

### Add tables and sequences to replication
londiste3 master.ini add-table --all
londiste3 master.ini add-seq --all
londiste3 slave.ini add-table --all
londiste3 slave.ini add-seq --all

### Verify replication is working
psql -c "select count(*) from mytable" ${MASTER_DB} postgres
while [[ `psql -Atc "select count(*) from mytable" ${SLAVE_DB} postgres` -eq 0 ]]
do
  sleep 1
done

psql -c "select * from mytable where id = 1" ${SLAVE_DB} postgres
psql -c "update mytable set first_name = 'Richard', last_name = 'Yen' where id = 1" ${MASTER_DB} postgres
sleep 5
psql -c "select * from mytable where id = 1" ${SLAVE_DB} postgres

### Check status
londiste3 slave.ini status
