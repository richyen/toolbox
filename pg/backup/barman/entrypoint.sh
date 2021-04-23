#!/bin/bash

### Very basic barman demo

# Environment vars
PGUSER=postgres

# Install barman
yum -y -q install epel-release
yum -y -q install barman barman-cli

# Configure barman
cat << EOF >> /etc/barman.d/barmantest.conf
[barmantest]
description = "Basic barman test"
conninfo = host=127.0.0.1 user=barman dbname=postgres
backup_method = postgres
streaming_archiver = on
slot_name = barman
;retention_policy = RECOVERY WINDOW OF 2 WEEKS
retention_policy = REDUNDANCY 2
retention_policy_mode = auto
wal_retention_policy = main
EOF

## Optional, if we want to do archiver method
# cat << EOF >> ${PGDATA}/postgresql.conf
# archive_mode = on
# archive_command = 'test -f %p'
# EOF

sed -i "s/repuser/barman/" ${PGDATA}/pg_hba.conf

# Start database
su - postgres -c "pg_ctl start"

# Create barman user
# NOTE: without true superuser privs, barman lacks certain abilities
createuser --replication barman
psql << EOF
GRANT EXECUTE ON FUNCTION pg_start_backup(text, boolean, boolean) to barman;
GRANT EXECUTE ON FUNCTION pg_stop_backup() to barman;
GRANT EXECUTE ON FUNCTION pg_stop_backup(boolean, boolean) to barman;
GRANT EXECUTE ON FUNCTION pg_switch_wal() to barman;
GRANT EXECUTE ON FUNCTION pg_create_restore_point(text) to barman;
GRANT pg_read_all_settings TO barman;
GRANT pg_read_all_stats TO barman;
EOF

# Create replication slot for archiving
su - barman -c "barman receive-wal --create-slot barmantest"

# Create the barmantest destination folder
su - barman -c "barman cron"

# Generate some data
pgbench -is 10

# Start barman background procs
su - barman -c "barman cron"

# Check config
su - barman -c "barman check barmantest"

# Try a backup
su - barman -c "barman backup barmantest"
su - barman -c "barman list-backup barmantest"

# Keep running (if desired)
tail -f /dev/null
