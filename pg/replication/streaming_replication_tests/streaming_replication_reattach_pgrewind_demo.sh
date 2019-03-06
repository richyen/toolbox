#!/bin/bash

# Assumes this script is run with a postgres/enterprisedb user, not root
export PGUSER=${USER}
OPORT=5555
NPORT=6666

echo 'Step 0. Set up replication'
pg_ctl -D /tmp/${OPORT}/data -mi stop
pg_ctl -D /tmp/${NPORT}/data -mi stop
rm -rf /tmp/${OPORT}/data
rm -rf /tmp/${NPORT}/data
rm -rf /tmp/arch

set -x
set -e
mkdir -p /tmp/arch

initdb -D /tmp/${OPORT}/data
echo 'set postgresql.conf'
sed -i "s/^port.*/port = ${OPORT}/" /tmp/${OPORT}/data/postgresql.conf
sed -i "s/#port.*/port = ${OPORT}/" /tmp/${OPORT}/data/postgresql.conf
sed -i "s/#listen_addresses.*/listen_addresses = '*'/" /tmp/${OPORT}/data/postgresql.conf
sed -i "s/^#wal_level.*/wal_level = hot_standby/" /tmp/${OPORT}/data/postgresql.conf
sed -i "s/.*max_wal_senders.*/max_wal_senders = 3/" /tmp/${OPORT}/data/postgresql.conf
sed -i "s/.*wal_keep_segments.*/wal_keep_segments = 64/" /tmp/${OPORT}/data/postgresql.conf
sed -i "s/.*archive_mode.*/archive_mode = on/" /tmp/${OPORT}/data/postgresql.conf
sed -i "s/.*archive_command.*/archive_command = 'cp %p \/tmp\/arch\/%f'/" /tmp/${OPORT}/data/postgresql.conf
sed -i "s/.*wal_log_hints.*/wal_log_hints = on/" /tmp/${OPORT}/data/postgresql.conf

echo "host replication repuser 127.0.0.1/0 trust" >> /tmp/${OPORT}/data/pg_hba.conf
echo "host replication repuser ::1/0 trust" >> /tmp/${OPORT}/data/pg_hba.conf
echo "local replication repuser trust" >> /tmp/${OPORT}/data/pg_hba.conf

pg_ctl -D /tmp/${OPORT}/data start
sleep 5
psql -p${OPORT} -c "create user repuser replication"

pg_basebackup -PRD /tmp/${NPORT}/data/ -X stream -c fast -U repuser -p${OPORT}
sleep 5
sed -i "s/^port.*/port = ${NPORT}/" /tmp/${NPORT}/data/postgresql.conf
sed -i "s/^#hot_standby.*/hot_standby = on/" /tmp/${NPORT}/data/postgresql.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/${NPORT}/data/recovery.conf
echo "recovery_target_timeline = 'latest'" >> /tmp/${NPORT}/data/recovery.conf
pg_ctl -D /tmp/${NPORT}/data start
sleep 5
psql -p${OPORT} postgres -c"create table mc1 (id int);"
psql -p${OPORT} postgres -c"insert into mc1 values (generate_series(1,100000));"
sleep 5
psql -p${NPORT} -c "select pg_is_in_recovery()"
psql -p${NPORT} postgres -c"select count(*) from mc1"
psql -p ${NPORT} -c 'select pg_last_wal_receive_lsn() "receive_lsn", pg_last_wal_replay_lsn() "replay_lsn", pg_is_in_recovery() "recovery_status";'

echo 'Step 1. Verify standby is Streaming Replication-ready'
cat /tmp/${NPORT}/data/postgresql.conf | grep "^wal_level"
cat /tmp/${NPORT}/data/postgresql.conf | grep "^archive_mode"
cat /tmp/${NPORT}/data/postgresql.conf | grep "^archive_command"
cat /tmp/${NPORT}/data/postgresql.conf | grep "^max_wal_senders"
cat /tmp/${NPORT}/data/postgresql.conf | grep "^wal_keep_segments"
cat /tmp/${NPORT}/data/postgresql.conf | grep "^wal_log_hints"

echo 'Step 2. Perform failover with pg_ctl promote'
pg_ctl -D /tmp/${NPORT}/data promote
sleep 5
psql -p ${NPORT} -c "select pg_is_in_recovery();"

echo "Step 3. Do clean shutdown of primary[${OPORT}] (-m fast or smart)"
pg_ctl -D /tmp/${OPORT}/data -mf stop

echo 'Step 4. Simulate reality -- make some changes while in detached state'
psql -p${NPORT} postgres -c"select * from pg_stat_replication;"
psql -p${NPORT} postgres -c"create database mynewdatabase"
psql -p${NPORT} postgres -c"create table mc2 (id int, name text);"
psql -p${NPORT} postgres -c"insert into mc2 values (generate_series(1,1000000), 'foo');"
psql -p${NPORT} postgres -c"insert into mc2 values (generate_series(1,1000000), 'bar');"
psql -p${NPORT} postgres -c"insert into mc2 values (generate_series(1,1000000), 'baz');"
pgbench -i -s 2 -p ${NPORT}

echo 'Step 5. Need a checkpoint to cause a real diversion'
psql -p${NPORT} postgres -c"checkpoint"

echo 'Step 6. Do pg_rewind'
pg_rewind -P --source-server="host=127.0.0.1 port=${NPORT}" --target-pgdata=/tmp/${OPORT}/data

echo 'Step 7. Create a recovery.conf file in the old master cluster (${OPORT})'
echo "standby_mode='on'" > /tmp/${OPORT}/data/recovery.conf
echo "primary_conninfo='host=localhost port=${NPORT} user=repuser'" >> /tmp/${OPORT}/data/recovery.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/${OPORT}/data/recovery.conf
echo "recovery_target_timeline = 'latest'" >> /tmp/${OPORT}/data/recovery.conf

echo 'Step 8. Start the old master which is now actually the slave of ${NPORT}'
rm -f /tmp/${OPORT}/data/postmaster.pid
rm -f /tmp/${OPORT}/data/recovery.done
rm -f /tmp/${OPORT}/data/backup_label.old
sed -i "s/^port.*/port = ${OPORT}/" /tmp/${OPORT}/data/postgresql.conf
pg_ctl -D /tmp/${OPORT}/data start
sleep 5
psql -p${OPORT} postgres -c "\dt"

echo 'Step 9. Test replication functionality all the way through'
psql -p ${NPORT} postgres -c "create table mc3 (id int);"
psql -p ${NPORT} postgres -c "insert into mc3 values (generate_series(1,100));"
psql -p ${OPORT} postgres -c"\dt"
psql -p ${OPORT} postgres -c"select count(*) from mc2;"
