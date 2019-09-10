#!/bin/bash

# Step 0 -- Clean up
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

# Initialize primary
initdb -D /tmp/5555/data
sed -i "s/^port.*/port = 5555/" /tmp/5555/data/postgresql.conf
sed -i "s/^#wal_level.*/wal_level = hot_standby/" /tmp/5555/data/postgresql.conf
sed -i "s/.*max_wal_senders.*/max_wal_senders = 3/" /tmp/5555/data/postgresql.conf
sed -i "s/.*wal_keep_segments.*/wal_keep_segments = 64/" /tmp/5555/data/postgresql.conf
sed -i "s/.*archive_mode.*/archive_mode = on/" /tmp/5555/data/postgresql.conf

echo "host replication repuser 127.0.0.1/0 trust" >> /tmp/5555/data/pg_hba.conf
echo "host replication repuser ::1/0 trust" >> /tmp/5555/data/pg_hba.conf
echo "local replication repuser trust" >> /tmp/5555/data/pg_hba.conf

pg_ctl -D /tmp/5555/data -l /tmp/5555/logfile start
psql -p5555 -c "create user repuser replication"

# Create two asynchronous standby instances
for i in 6666 7777
do
  pg_basebackup -PRD /tmp/${i}/data/ -U repuser -p5555
  sed -i "s/^port.*/port = ${i}/" /tmp/${i}/data/postgresql.conf
  sed -i "s/^#hot_standby.*/hot_standby = on/" /tmp/${i}/data/postgresql.conf
  echo "recovery_target_timeline = 'latest'" >> /tmp/${i}/data/recovery.conf
  if [[ ${i} -eq 6666 ]]
  then
    # Give 6666 ability to become synchronous replication DB
    sed -i "s/primary_conninfo = '/primary_conninfo = 'application_name=mysyncdb /" /tmp/6666/data/recovery.conf
    sed -i "s/.*synchronous_standby_names.*/synchronous_standby_names = 'mysyncdb'/" /tmp/5555/data/postgresql.conf
    psql -p5555 -c "SELECT pg_reload_conf()"
  fi
  pg_ctl -D /tmp/${i}/data -l /tmp/${i}/logfile start
done

# See that 6666 is sync, 7777 is async
psql -p5555 -c "SELECT * FROM pg_stat_replication"
