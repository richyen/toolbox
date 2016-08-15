#!/bin/bash

export PATH="/opt/PostgresPlus/9.5AS/bin:${PATH}"

echo 'Step 0. Set up replication'
pg_ctl -D /tmp/5555/data -mi stop
pg_ctl -D /tmp/6666/data -mi stop
rm -rf /tmp/5555/data
rm -rf /tmp/6666/data
rm -rf /tmp/arch

set -x
set -e
mkdir -p /tmp/arch

initdb -D /tmp/5555/data
echo 'set postgresql.conf'
sed -i "s/^port.*/port = 5555/" /tmp/5555/data/postgresql.conf
sed -i "s/^#wal_level.*/wal_level = hot_standby/" /tmp/5555/data/postgresql.conf
sed -i "s/.*max_wal_senders.*/max_wal_senders = 3/" /tmp/5555/data/postgresql.conf
sed -i "s/.*wal_keep_segments.*/wal_keep_segments = 64/" /tmp/5555/data/postgresql.conf
sed -i "s/.*archive_mode.*/archive_mode = on/" /tmp/5555/data/postgresql.conf
sed -i "s/.*archive_command.*/archive_command = 'cp %p \/tmp\/arch\/%f'/" /tmp/5555/data/postgresql.conf
sed -i "s/.*wal_log_hints.*/wal_log_hints = on/" /tmp/5555/data/postgresql.conf

echo "host replication repuser 127.0.0.1/0 trust" >> /tmp/5555/data/pg_hba.conf
echo "host replication repuser ::1/0 trust" >> /tmp/5555/data/pg_hba.conf
echo "local replication repuser trust" >> /tmp/5555/data/pg_hba.conf

pg_ctl -D /tmp/5555/data start
sleep 5
psql -p5555 -c "create user repuser replication"

pg_basebackup -PRD /tmp/6666/data/ -X stream -c fast -U repuser -p5555
sleep 5
sed -i "s/^port.*/port = 6666/" /tmp/6666/data/postgresql.conf
sed -i "s/^#hot_standby.*/hot_standby = on/" /tmp/6666/data/postgresql.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/6666/data/recovery.conf
echo "recovery_target_timeline = 'latest'" >> /tmp/6666/data/recovery.conf
pg_ctl -D /tmp/6666/data start
sleep 5
psql -p6666 -c "select pg_is_in_recovery()"
psql -p5555 edb -c"create table mc1 (id int);"
psql -p5555 edb -c"insert into mc1 values (generate_series(1,100000));"
sleep 5
psql -p6666 edb -c"select count(*) from mc1"
psql -p 6666 -c 'select pg_last_xlog_receive_location() "receive_location", pg_last_xlog_replay_location() "replay_location", pg_is_in_recovery() "recovery_status";'

echo 'Step 1. Verify standby is Streaming Replication-ready'
cat /tmp/6666/data/postgresql.conf | grep "^wal_level"
cat /tmp/6666/data/postgresql.conf | grep "^archive_mode"
cat /tmp/6666/data/postgresql.conf | grep "^archive_command"
cat /tmp/6666/data/postgresql.conf | grep "^max_wal_senders"
cat /tmp/6666/data/postgresql.conf | grep "^wal_keep_segments"
cat /tmp/6666/data/postgresql.conf | grep "^wal_log_hints"

echo 'step 2. Perform failover with pg_ctl promote'
pg_ctl -D /tmp/6666/data promote
sleep 5
psql -p 6666 -c "select pg_is_in_recovery();"

echo 'Step 3. Do clean shutdown of primary[5555] (-m fast or smart)'
pg_ctl -D /tmp/5555/data -mf stop

echo 'step 4. Simulate reality -- make some changes while in detached state'
psql -p6666 edb -c"select * from pg_stat_replication;"
psql -p6666 edb -c"create table mc2 (id int);"
psql -p6666 edb -c"insert into mc2 values (generate_series(1,100000));"
pgbench -i -s 2 -p 6666

echo 'step 5. Need a checkpoint to cause a real diversion'
psql -p6666 edb -c"checkpoint"

echo 'Step 6. Do pg_rewind'
pg_rewind -P --source-server="host=127.0.0.1 port=6666" --target-pgdata=/tmp/5555/data

echo 'Step 6. Create a recovery.conf file in the old master cluster (5555)'
echo "standby_mode='on'" > /tmp/5555/data/recovery.conf
echo "primary_conninfo='host=localhost port=6666 user=repuser'" >> /tmp/5555/data/recovery.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/5555/data/recovery.conf
echo "recovery_target_timeline = 'latest'" >> /tmp/5555/data/recovery.conf

echo 'Step 7. Start the old master which is now actually the slave of 6666'
rm -f /tmp/5555/data/postmaster.pid
rm -f /tmp/5555/data/recovery.done
rm -f /tmp/5555/data/backup_label.old
sed -i "s/^port.*/port = 5555/" /tmp/5555/data/postgresql.conf
pg_ctl -D /tmp/5555/data start
sleep 5
psql -p5555 edb -c "\dt"

echo 'Step 9. Test replication functionality all the way through'
psql -p 6666 edb -c "create table mc3 (id int);"
psql -p 6666 edb -c "insert into mc3 values (generate_series(1,100));"
psql -p 5555 edb -c"\dt"
psql -p 5555 edb -c"select count(*) from mc2;"
