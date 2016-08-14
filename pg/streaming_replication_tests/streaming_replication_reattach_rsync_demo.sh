#!/bin/bash

export PATH="/opt/PostgresPlus/9.5AS/bin:${PATH}"

echo ' Preliminary steps by Richard'
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

echo 'Step 1. Do clean shutdown of Primary[5555] (-m fast or smart)'
pg_ctl -D /tmp/5555/data stop

echo 'Step 2. Check for sync status and recovery status of First Standby[6666] before promoting it:'
psql -p 6666 -c 'select pg_last_xlog_receive_location() "receive_location", pg_last_xlog_replay_location() "replay_location", pg_is_in_recovery() "recovery_status";'
echo 'Check for sync status and recovery status of Second Standby[7777] before promoting it:'
psql -p 7777 -c 'select pg_last_xlog_receive_location() "receive_location", pg_last_xlog_replay_location() "replay_location", pg_is_in_recovery() "recovery_status";'

echo 'Step 3. Open the postgresql.conf file from the First Standby.'
cat /tmp/6666/data/postgresql.conf | grep "^wal_level"
cat /tmp/6666/data/postgresql.conf | grep "^archive_mode"
cat /tmp/6666/data/postgresql.conf | grep "^archive_command"
cat /tmp/6666/data/postgresql.conf | grep "^max_wal_senders"
cat /tmp/6666/data/postgresql.conf | grep "^wal_keep_segments"

echo 'step 4. Open the Standby as new Primary by pg_ctl promote'
pg_ctl -D /tmp/6666/data promote
sleep 5
psql -p 6666 -c "select pg_is_in_recovery();"

echo 'step 5: Go to the recovery.conf file of  a Second Standby and edit the file'
cat /tmp/7777/data/recovery.conf

echo 'Step 6. Open the postgresql.conf file from the Second Standby.'
cat /tmp/7777/data/postgresql.conf | grep "^wal_level"
cat /tmp/7777/data/postgresql.conf | grep "^archive_mode"
cat /tmp/7777/data/postgresql.conf | grep "^archive_command"
cat /tmp/7777/data/postgresql.conf | grep "^max_wal_senders"
cat /tmp/7777/data/postgresql.conf | grep "^wal_keep_segments"
cat /tmp/7777/data/postgresql.conf | grep "^hot_standby"

echo 'step 7. Restart the Second standby cluster-replication_backup_2nd- which is the new Slave'
pg_ctl -D /tmp/7777/data restart
sleep 5
psql -p 7777 edb -c"select pg_is_in_recovery();"

echo 'step 8. Now again go to the newly Promoted Master and run the below query'
psql -p6666 edb -c"select * from pg_stat_replication;"
psql -p6666 edb -c"create table mc1 (id int);"
psql -p6666 edb -c"insert into mc1 values (generate_series(1,100));"

echo  'Again Go to the Newly Created  Slave to check The consistency'
psql -p 7777 edb -c "\dt"


echo 'Step 9. Do rsync'
psql -p6666 -c "select pg_start_backup('5555')"

rsync -av --progress --delete /tmp/7777/data /tmp/5555

psql -p6666 -c "select pg_stop_backup()"


echo 'Step 10 .Create a recover.conf file in the old master cluster'
echo "standby_mode='on'" > /tmp/5555/data/recovery.conf
echo "primary_conninfo='host=localhost port=7777 user=repuser'" >> /tmp/5555/data/recovery.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/5555/data/recovery.conf
echo "recovery_target_timeline = 'latest'" >> /tmp/5555/data/recovery.conf

echo 'Step 11. Now Start the Old Master which is now actually  be the slave for the first slave(replication_backup_2nd)'
rm -f /tmp/5555/data/postmaster.pid
sed -i "s/^port.*/port = 5555/" /tmp/5555/data/postgresql.conf
pg_ctl -D /tmp/5555/data start
sleep 5
psql -p5555 edb -c "\dt"

echo 'step 12. Now go to the First Slave that is (replication_backup_2nd)'
psql -p 7777 edb -c "select * from pg_stat_replication;"

echo 'Step 13. Again go to the master(replication_backup)'
psql -p 6666 edb -c "create table mc2 (id int);"
psql -p 6666 edb -c "insert into mc2 values (generate_series(1,100));"

echo 'step 14. Again go to the 2nd slave (i.e old master)'
psql -p 5555 edb -c"\dt"
sleep 5
psql -p 5555 edb -c"select count(*) from mc2;"

echo  'Now stop all the three server'
echo  'Go to the second slave (i.e  2nd slave)'

pg_ctl -D /tmp/5555/data stop
pg_ctl -D /tmp/7777/data stop
pg_ctl -D /tmp/6666/data stop

rm -f /tmp/5555/data/recovery.conf

sed -i "s/#hot_standby.*/hot_standby=on/" /tmp/6666/data/postgresql.conf
sed -i "s/^hot_standby.*/hot_standby=on/" /tmp/6666/data/postgresql.conf

echo "standby_mode='on'" > /tmp/6666/data/recovery.conf
echo "primary_conninfo='port=5555 user=repuser'" >> /tmp/6666/data/recovery.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/6666/data/recovery.conf
echo "recovery_target_timeline = 'latest'" >> /tmp/6666/data/recovery.conf

sed -i "s/#hot_standby.*/hot_standby=on/" /tmp/7777/data/postgresql.conf
sed -i "s/^hot_standby.*/hot_standby=on/" /tmp/7777/data/postgresql.conf

echo "standby_mode='on'" > /tmp/7777/data/recovery.conf
echo "primary_conninfo='port=6666 user=repuser'" >> /tmp/7777/data/recovery.conf
echo "restore_command='cp /tmp/arch/%f %p'" >> /tmp/7777/data/recovery.conf
echo "recovery_target_timeline = 'latest'" >> /tmp/7777/data/recovery.conf

pg_ctl -D /tmp/5555/data start
sleep 5
psql -p5555 -c "create table new_master(id numeric);"

pg_ctl -D /tmp/6666/data start
sleep 5
psql -p6666 -c "Select pg_is_in_recovery;"

psql -p6666 -c "\dt"

psql -p5555 -c "select * from pg_stat_replication"
pg_ctl -D /tmp/7777/data start
sleep 5

psql -p7777 -c "\dt"
psql -p7777 -c "Select pg_is_in_recovery;"
