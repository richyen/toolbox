#!/bin/bash

# This script demonstrates the effect of tuning max_standby_streaming_delay, and how it cancels long-running queries that interfere with WAL-writing (specifically, maintenance)

# NOTE: This script to be run on the standby server; it is up to you to set up streaming replication first

MASTER_IP=127.0.0.1
MASTER_PGPORT=5432
STANDBY_IP=`hostname -i`
STANDBY_PGPORT=5433
STANDBY_PGDATA="/tmp/data"
sleep_time=120

# Setup
dropdb -h ${MASTER_IP} -p ${MASTER_PGPORT} bench
createdb -h ${MASTER_IP} -p ${MASTER_PGPORT} bench
pgbench -i -F 50 -s 50 -h ${MASTER_IP} -p ${MASTER_PGPORT} bench 2> /dev/null

# See if max_standby_streaming_delay cancels a query
sed -i "s/max_standby_streaming_delay.*/max_standby_streaming_delay = 10s/" ${STANDBY_PGDATA}/postgresql.conf
psql -h ${STANDBY_IP} -p ${STANDBY_PGPORT} -Atc "select pg_reload_conf()"
psql -h ${STANDBY_IP} -p ${STANDBY_PGPORT} -Atc "show max_standby_streaming_delay"
psql -h ${MASTER_IP}  -p ${MASTER_PGPORT} -c "DELETE FROM pgbench_accounts where aid between 0 and 10000" bench
psql -h ${STANDBY_IP} -p ${STANDBY_PGPORT} -c "select pg_sleep(45), count(*) from pgbench_accounts" bench &
psql -h ${MASTER_IP}  -p ${MASTER_PGPORT} -c "vacuum" bench
echo "You should see a query cancellation message soon"
sleep ${sleep_time}

# Try again
sed -i "s/max_standby_streaming_delay.*/max_standby_streaming_delay = 60s/" ${STANDBY_PGDATA}/postgresql.conf
psql -h ${STANDBY_IP} -p ${STANDBY_PGPORT} -Atc "select pg_reload_conf()"
psql -h ${STANDBY_IP} -p ${STANDBY_PGPORT} -Atc "show max_standby_streaming_delay"
psql -h ${MASTER_IP}  -p ${MASTER_PGPORT} -c "DELETE FROM pgbench_accounts where aid between 10000 and 20000" bench
psql -h ${STANDBY_IP} -p ${STANDBY_PGPORT} -c "select pg_sleep(30), count(*) from pgbench_accounts" bench &
psql -h ${MASTER_IP}  -p ${MASTER_PGPORT} -c "vacuum" bench
echo "No query cancellation should occur in the next ${sleep_time} seconds"
sleep ${sleep_time}

# Try with longer sleep
psql -h ${MASTER_IP}  -p ${MASTER_PGPORT} -c "DELETE FROM pgbench_accounts where aid between 20000 and 30000" bench
psql -h ${STANDBY_IP} -p ${STANDBY_PGPORT} -c "select pg_sleep(120), count(*) from pgbench_accounts" bench &
psql -h ${MASTER_IP}  -p ${MASTER_PGPORT} -c "vacuum" bench
echo "You should see a query cancellation message soon"
sleep ${sleep_time}

# Try again
sed -i "s/max_standby_streaming_delay.*/max_standby_streaming_delay = 120s/" ${STANDBY_PGDATA}/postgresql.conf
psql -h ${STANDBY_IP} -p ${STANDBY_PGPORT} -Atc "select pg_reload_conf()"
psql -h ${STANDBY_IP} -p ${STANDBY_PGPORT} -Atc "show max_standby_streaming_delay"
psql -h ${MASTER_IP}  -p ${MASTER_PGPORT} -c "DELETE FROM pgbench_accounts where aid between 30000 and 40000" bench
psql -h ${STANDBY_IP} -p ${STANDBY_PGPORT} -c "select pg_sleep(60), count(*) from pgbench_accounts" bench &
psql -h ${MASTER_IP}  -p ${MASTER_PGPORT} -c "vacuum" bench
echo "No query cancellation should occur in the next ${sleep_time} seconds"
sleep ${sleep_time}

# Check the number of conflicts recorded
psql -h ${STANDBY_IP} -p ${STANDBY_PGPORT} -c "select * from pg_stat_database_conflicts where datname = 'bench'"
