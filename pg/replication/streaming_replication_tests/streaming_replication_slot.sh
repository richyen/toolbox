#!/bin/bash

# Assumes this script is run with a postgres/enterprisedb user, not root
export PGUSER=${USER}
OPORT=5555
NPORT=6666

echo 'Step 0. Clean up and set up'
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

echo 'Step 1. Create replication slot'
psql -p${OPORT} -c "select pg_create_physical_replication_slot('slot1', true)"

echo 'Step 2. Start replication'
pg_basebackup -PRD /tmp/${NPORT}/data/ -S slot1 -U repuser -p${OPORT}
sleep 5
sed -i "s/^port.*/port = ${NPORT}/" /tmp/${NPORT}/data/postgresql.conf
sed -i "s/^#hot_standby.*/hot_standby = on/" /tmp/${NPORT}/data/postgresql.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/${NPORT}/data/recovery.conf
echo "recovery_target_timeline = 'latest'" >> /tmp/${NPORT}/data/recovery.conf
echo "primary_slot_name = 'slot1'" >> /tmp/${NPORT}/data/recovery.conf
pg_ctl -D /tmp/${NPORT}/data start
sleep 5
psql -p${OPORT} postgres -c"create table mc1 (id int);"
psql -p${OPORT} postgres -c"insert into mc1 values (generate_series(1,100000));"
sleep 5
psql -p${NPORT} -c "select pg_is_in_recovery()"
psql -p${NPORT} postgres -c"select count(*) from mc1"
psql -p ${NPORT} -c 'select pg_last_wal_receive_lsn() "receive_lsn", pg_last_wal_replay_lsn() "replay_lsn", pg_is_in_recovery() "recovery_status";'
