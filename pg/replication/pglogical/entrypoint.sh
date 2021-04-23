#!/bin/bash

### Very basic pglogical demo

# Environment vars
PROVIDER_IP=10.111.211.11
SUBSCRIBER_IP=10.111.211.12

# Make sure environment is clean
curl https://access.2ndquadrant.com/api/repository/dl/default/release/${PGMAJOR}/rpm | bash
yum -y install postgresql${PGMAJOR}-pglogical postgresql12-contrib

# Start and configure postgres
cat << EOF >> /var/lib/pgsql/${PGMAJOR}/data/postgresql.conf
wal_level = 'logical'
max_worker_processes = 10
max_replication_slots = 10
max_wal_senders = 10
shared_preload_libraries = 'pglogical'
track_commit_timestamp = on
pglogical.conflict_resolution = 'last_update_wins'
EOF

su - postgres -c "pg_ctl start"
psql -c "ALTER SYSTEM SET autovacuum TO off"
psql -c "CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public"
psql -c "CREATE EXTENSION pglogical"
psql -c "SELECT pg_reload_conf()"
psql -c "SHOW autovacuum"

if [[ $( hostname ) == 'provider' ]]; then
  psql -c "select pglogical.create_node(node_name := 'provider1', dsn := 'host=${PROVIDER_IP} port=5432 dbname=postgres user=postgres password=postgres')"
  psql -c "SELECT pglogical.replication_set_add_all_tables('default', ARRAY['public'])"
else
  psql -c "SELECT pglogical.create_node( node_name := 'subscriber1', dsn := 'host=${SUBSCRIBER_IP} port=5432 dbname=postgres user=postgres password=postgres' )"
  psql -c "SELECT pglogical.create_subscription( subscription_name := 'subscription1', provider_dsn := 'host=${PROVIDER_IP} port=5432 dbname=postgres user=postgres password=postgres' )"
fi

if [[ $( hostname ) == 'provider' ]]; then
  pgbench -i
fi

psql -c "select subscription_name, status FROM pglogical.show_subscription_status()"
psql -c "SELECT pglogical.wait_for_subscription_sync_complete('subscription1')"

# Create target database
psql -c "SELECT count(*) from pgbench_accounts"

# Keep running (if desired)
tail -f /dev/null
