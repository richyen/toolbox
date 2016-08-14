#!/bin/bash

# This script demonstrates the effect of tuning max_standby_streaming_delay, and how it cancels long-running queries that interfere with WAL-writing (specifically, maintenance)

# This script to be run on the standby server after a Streaming Replication cluster is set up
MASTER_IP=172.17.0.6

# Setup
dropdb -h ${MASTER_IP} bench
createdb -h ${MASTER_IP} bench
pgbench -i -F 50 -s 50 -h ${MASTER_IP} bench 2> /dev/null

# See if max_standby_streaming_delay cancels a query
sed -i "s/max_standby_streaming_delay.*/max_standby_streaming_delay = 10s/" /var/lib/ppas/9.5/data/postgresql.conf 
psql -Atc "select pg_reload_conf()"
psql -Atc "show max_standby_streaming_delay"
psql -h ${MASTER_IP} -c "DELETE FROM pgbench_accounts where aid between 0 and 10000" bench
psql -c "select pg_sleep(45), count(*) from pgbench_accounts" bench &
psql -h ${MASTER_IP} -c "vacuum" bench
sleep 120 # Wait for pg_sleep to get canceled

# Try again
sed -i "s/max_standby_streaming_delay.*/max_standby_streaming_delay = 60s/" /var/lib/ppas/9.5/data/postgresql.conf 
psql -Atc "select pg_reload_conf()"
psql -Atc "show max_standby_streaming_delay"
psql -h ${MASTER_IP} -c "DELETE FROM pgbench_accounts where aid between 10000 and 20000" bench
psql -c "select pg_sleep(30), count(*) from pgbench_accounts" bench &
psql -h ${MASTER_IP} -c "vacuum" bench
sleep 120 # This pg_sleep should succeed

# Try with longer sleep
psql -h ${MASTER_IP} -c "DELETE FROM pgbench_accounts where aid between 20000 and 30000" bench
psql -c "select pg_sleep(120), count(*) from pgbench_accounts" bench &
psql -h ${MASTER_IP} -c "vacuum" bench
sleep 120 # This pg_sleep should get canceled

# Try again
sed -i "s/max_standby_streaming_delay.*/max_standby_streaming_delay = 120s/" /var/lib/ppas/9.5/data/postgresql.conf 
psql -Atc "select pg_reload_conf()"
psql -Atc "show max_standby_streaming_delay"
psql -h ${MASTER_IP} -c "DELETE FROM pgbench_accounts where aid between 30000 and 40000" bench
psql -c "select pg_sleep(60), count(*) from pgbench_accounts" bench &
psql -h ${MASTER_IP} -c "vacuum" bench
sleep 120 # This pg_sleep should succeed

# Check the number of conflicts recorded
psql -c "select * from pg_stat_database_conflicts where datname = 'bench'"
