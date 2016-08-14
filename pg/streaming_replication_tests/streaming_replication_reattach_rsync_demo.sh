#!/bin/bash

### Adapted from Raghav's blog post [http://raghavt.blogspot.com/2014/12/implementing-switchoverswitchback-in.html]

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
sed -i "s/^#wal_level.*/wal_level = hot_standby/" /tmp/5555/data/postgresql.conf
sed -i "s/.*max_wal_senders.*/max_wal_senders = 3/" /tmp/5555/data/postgresql.conf
sed -i "s/.*wal_keep_segments.*/wal_keep_segments = 64/" /tmp/5555/data/postgresql.conf
sed -i "s/.*archive_mode.*/archive_mode = on/" /tmp/5555/data/postgresql.conf
sed -i "s/.*archive_command.*/archive_command = 'cp %p \/tmp\/arch\/%f'/" /tmp/5555/data/postgresql.conf

echo "host replication repuser 127.0.0.1/0 trust" >> /tmp/5555/data/pg_hba.conf
echo "host replication repuser ::1/0 trust" >> /tmp/5555/data/pg_hba.conf
echo "local replication repuser trust" >> /tmp/5555/data/pg_hba.conf

pg_ctl -D /tmp/5555/data start
sleep 5
psql -p5555 -c "create user repuser replication"

pg_basebackup -PxRD /tmp/6666/data/ -U repuser -p5555
sleep 5
sed -i "s/^port.*/port = 6666/" /tmp/6666/data/postgresql.conf
sed -i "s/^#hot_standby.*/hot_standby = on/" /tmp/6666/data/postgresql.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/6666/data/recovery.conf
echo "recovery_target_timeline = 'latest'" >> /tmp/6666/data/recovery.conf
pg_ctl -D /tmp/6666/data start
sleep 5
psql -p6666 -c "select pg_is_in_recovery()"

pg_basebackup -PxRD /tmp/7777/data/ -U repuser -p5555
sleep 5
sed -i "s/^port.*/port = 7777/" /tmp/7777/data/postgresql.conf
sed -i "s/^#hot_standby.*/hot_standby = on/" /tmp/7777/data/postgresql.conf
sed -i "s/5555/6666/" /tmp/7777/data/recovery.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/7777/data/recovery.conf
echo "recovery_target_timeline = 'latest'" >> /tmp/7777/data/recovery.conf
pg_ctl -D /tmp/7777/data start
sleep 5
psql -p7777 -c "select pg_is_in_recovery()"

echo 'Step 1. Do clean shutdown of primary[5555] (-m fast or smart)'
pg_ctl -D /tmp/5555/data stop

echo 'step 4. Open the Standby as new Primary by pg_ctl promote'
psql -p 6666 -c 'select pg_last_xlog_receive_location() "receive_location", pg_last_xlog_replay_location() "replay_location", pg_is_in_recovery() "recovery_status";'
psql -p 7777 -c 'select pg_last_xlog_receive_location() "receive_location", pg_last_xlog_replay_location() "replay_location", pg_is_in_recovery() "recovery_status";'

echo 'Step 3. Verify first standby is Streaming Replication-ready'
cat /tmp/6666/data/postgresql.conf | grep "^wal_level"
cat /tmp/6666/data/postgresql.conf | grep "^archive_mode"
cat /tmp/6666/data/postgresql.conf | grep "^archive_command"
cat /tmp/6666/data/postgresql.conf | grep "^max_wal_senders"
cat /tmp/6666/data/postgresql.conf | grep "^wal_keep_segments"

echo 'step 4. Start the first standby as new primary, using pg_ctl promote'
pg_ctl -D /tmp/6666/data promote
sleep 5
psql -p 6666 -c "select pg_is_in_recovery();"

echo 'step 5: Go to the recovery.conf file of the second standby and verify its configuration'
cat /tmp/7777/data/recovery.conf

echo 'Step 6. Open the postgresql.conf file from the second standby and make sure it is still eligible to cascade replication.'
cat /tmp/7777/data/postgresql.conf | grep "^wal_level"
cat /tmp/7777/data/postgresql.conf | grep "^archive_mode"
cat /tmp/7777/data/postgresql.conf | grep "^archive_command"
cat /tmp/7777/data/postgresql.conf | grep "^max_wal_senders"
cat /tmp/7777/data/postgresql.conf | grep "^wal_keep_segments"
cat /tmp/7777/data/postgresql.conf | grep "^hot_standby"

echo 'step 7. Restart the second standby'
pg_ctl -D /tmp/7777/data restart
sleep 5
psql -p 7777 edb -c"select pg_is_in_recovery();"

echo 'step 8. Test replication functionality'
psql -p6666 edb -c"select * from pg_stat_replication;"
psql -p6666 edb -c"create table mc1 (id int);"
psql -p6666 edb -c"insert into mc1 values (generate_series(1,100));"
psql -p7777 edb -c "\dt"
psql -p7777 edb -c "SELECT count(*) from mc1"

echo 'Step 9. Do rsync'
psql -p6666 -c "select pg_start_backup('5555')"

rsync -av --progress --delete /tmp/7777/data /tmp/5555

psql -p6666 -c "select pg_stop_backup()"

echo 'Step 10. Create a recovery.conf file in the old master cluster (5555)'
echo "standby_mode='on'" > /tmp/5555/data/recovery.conf
echo "primary_conninfo='host=localhost port=7777 user=repuser'" >> /tmp/5555/data/recovery.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/5555/data/recovery.conf
echo "recovery_target_timeline = 'latest'" >> /tmp/5555/data/recovery.conf

echo 'Step 11. Start the old master which is now actually be the slave of 7777'
rm -f /tmp/5555/data/postmaster.pid
sed -i "s/^port.*/port = 5555/" /tmp/5555/data/postgresql.conf
pg_ctl -D /tmp/5555/data start
sleep 5
psql -p5555 edb -c "\dt"

echo 'step 12. Verify sync status of the first slave [7777]'
psql -p 7777 edb -c "select * from pg_stat_replication;"

echo 'Step 13. Test replication functionality all the way through'
psql -p 6666 edb -c "create table mc2 (id int);"
psql -p 6666 edb -c "insert into mc2 values (generate_series(1,100));"
psql -p 7777 edb -c"\dt"
psql -p 5555 edb -c"\dt"
psql -p 7777 edb -c"select count(*) from mc2;"
psql -p 5555 edb -c"select count(*) from mc2;"
