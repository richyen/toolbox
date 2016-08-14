#!/bin/bash

# This script demonstrates the effect of enabling hot_standby_feedback, and how it prevents cancellation of long-running queries

# This script to be run on the standby server after a Streaming Replication cluster is set up
MASTER_IP=172.17.0.4

# Setup
createdb -h ${MASTER_IP} bench
pgbench -i -F 50 -s 50 -h ${MASTER_IP} bench 2> /dev/null
psql -c "show hot_standby_feedback" # Should be off

# Run long, complex query repeatedly
while :; do psql -c "select now(), count(*) from pgbench_accounts a join pgbench_history h on a.aid=h.aid join pgbench_branches b on b.bid=h.bid join pgbench_tellers t on h.tid=t.tid where abs(delta) > (random() * 10)" bench; sleep 1; done &> /dev/null &

# Start doing updates on the master
pgbench -h ${MASTER_IP} -c 10 -n -P 10 -T 60 bench
psql -c "select * from pg_stat_database_conflicts where datname = 'bench'" # Should show many conflicts

# Turn on hot_standby_feedback
sed -i "s/hot_standby_feedback.*/hot_standby_feedback = on/" /var/lib/ppas/9.5/data/postgresql.conf
sed -i "s/#hot_standby_feedback.*/hot_standby_feedback = on/" /var/lib/ppas/9.5/data/postgresql.conf
psql -c "select pg_reload_conf()"
psql -c "show hot_standby_feedback"

# Run the test again
pgbench -h ${MASTER_IP} -c 10 -n -P 10 -T 60 bench
psql -c "select * from pg_stat_database_conflicts where datname = 'bench'" # Should show no new conflicts

# Turn off hot_standby_feedback
sed -i "s/hot_standby_feedback.*/hot_standby_feedback = off/" /var/lib/ppas/9.5/data/postgresql.conf
psql -c "select pg_reload_conf()"
psql -c "show hot_standby_feedback"

# Run the test again
pgbench -h ${MASTER_IP} -c 10 -n -P 10 -T 60 bench
psql -c "select * from pg_stat_database_conflicts where datname = 'bench'" # Should show many new conflicts

# Can verify the conflicts in the postgres logs as well
cat /var/lib/ppas/9.5/data/pg_log/* | grep -c "conflict with recovery"
