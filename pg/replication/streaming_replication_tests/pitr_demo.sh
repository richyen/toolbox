#!/bin/bash

export PATH="/opt/PostgresPlus/9.5AS/bin:${PATH}"

echo 'Step 0. Set up replication'
pg_ctl -D /tmp/5555/data -mi stop
pg_ctl -D /tmp/6666/data -mi stop
pg_ctl -D /tmp/7777/data -mi stop
rm -rf /tmp/5555/data
rm -rf /tmp/6666/data
rm -rf /tmp/7777/data
rm -rf /tmp/arch

set -x
set -e
mkdir -p /tmp/arch

initdb -D /tmp/5555/data
echo 'set postgresql.conf'
sed -i "s/^port.*/port = 5555/" /tmp/5555/data/postgresql.conf
sed -i "s/^#wal_level.*/wal_level = archive/" /tmp/5555/data/postgresql.conf
sed -i "s/.*archive_mode.*/archive_mode = on/" /tmp/5555/data/postgresql.conf
sed -i "s/.*archive_command.*/archive_command = 'cp %p \/tmp\/arch\/%f'/" /tmp/5555/data/postgresql.conf
sed -i "s/.*wal_log_hints.*/wal_log_hints = on/" /tmp/5555/data/postgresql.conf
sed -i "s/.*max_wal_senders.*/max_wal_senders = 2/" /tmp/5555/data/postgresql.conf
echo "local replication all trust" >> /tmp/5555/data/pg_hba.conf

pg_ctl -D /tmp/5555/data start
sleep 3
psql -p5555 edb -c"create table employee (id int, name text);"
psql -p5555 edb -c"insert into employee values (generate_series(1,50),md5(random()));"
psql -p5555 edb -c"select * from employee"

# Take backup
pg_basebackup -PD /tmp/6666/data/ -X stream -c fast -U enterprisedb -p5555
pg_basebackup -PD /tmp/7777/data/ -X stream -c fast -U enterprisedb -p5555
NOW=`psql -p5555 edb -Atc"select now()"`

echo 'Step 1. Make horrible mistake'
sleep 3
psql -p5555 edb -c"UPDATE employee SET name = 'JOHN DOE'"
psql -p5555 edb -c"CHECKPOINT"
psql -p5555 edb -c"SELECT pg_switch_xlog()"
psql -p5555 edb -c"select * from employee"

echo 'Step 2. Restore full backup -- obviously, this is not going to cut it'
sleep 3
sed -i "s/^port.*/port = 6666/" /tmp/6666/data/postgresql.conf
sed -i "s/^archive_mode.*/archive_mode = off/" /tmp/6666/data/postgresql.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/6666/data/recovery.conf
pg_ctl -D /tmp/6666/data start
sleep 3
psql -p6666 edb -c"select * from employee"

echo 'Step 3. Use PITR to restore backup to last sane moment -- hooray for PITR!'
sleep 3
sed -i "s/^port.*/port = 7777/" /tmp/7777/data/postgresql.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/7777/data/recovery.conf
echo "recovery_target_time = '${NOW}'" >> /tmp/7777/data/recovery.conf
pg_ctl -D /tmp/7777/data start
sleep 3
psql -p7777 edb -c"select * from employee"
