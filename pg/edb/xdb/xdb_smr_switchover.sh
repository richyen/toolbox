#!/bin/bash

# This script implements the XDB Single-Master Replication (SMR) Controlled Switchover steps as detailed in:
# https://www.enterprisedb.com/docs/en/6.0/repguide/EDB_Postgres_Replication_Server_Users_Guide.1.29.html
# NOTE: This script assumes that edb-xdbpubserver and edb-xdbsubserver services are running on the same host
# This script is to be run where the edb-xdbpubserver and edb-xdbsubserver services are running

XDB_HOME=/usr/ppas-xdb-6.0
### TODO: Fill in IP addresses below ###
# Old Publication Database (aka new subscription database, or old master) IP address
OLD_PUB_IP=
# Old Subscription Database (aka new publication database, or old slave) IP address
NEW_PUB_IP=

# Step 0
#  -- Stop all transaction processing against the publication database
#  -- Perform an on-demand synchronization replication or a snapshot replication
#  -- Stop the publication server and the subscription server
service edb-xdbpubserver stop
service edb-xdbsubserver stop

# Step 1 -- Create a backup of schemas _edb_replicator_pub, _edb_replicator_sub, and _edb_scheduler; then delete these schemas
for i in _edb_replicator_pub _edb_replicator_sub _edb_scheduler
do
  pg_dump -h ${OLD_PUB_IP} -n ${i} > /tmp/1_${i}.sql
  psql -h ${OLD_PUB_IP} -c "DROP SCHEMA ${i} CASCADE"
done

# Step 2 -- Create a backup of the replication triggers and their corresponding trigger functions; then disable/delete these triggers
for i in rrpd rrpi rrpu
do
  psql -h ${OLD_PUB_IP} -Atc "SELECT pg_get_functiondef(oid)||';' FROM pg_proc WHERE proname ILIKE '${i}%'" >> /tmp/1__edb_triggers.sql
  pg_dump -h ${OLD_PUB_IP} -s | grep ${i} | grep "CREATE TRIGGER" >> /tmp/1__edb_triggers.sql
  pg_dump -h ${OLD_PUB_IP} -s | grep "ENABLE ALWAYS TRIGGER ${i}" | sed -s "s/ENABLE ALWAYS/DISABLE/" >> /tmp/1_disable_triggers.sql
done
psql -h ${OLD_PUB_IP} < /tmp/1_disable_triggers.sql

# Step 3 -- Create a backup of schema _edb_replicator_sub on subscription DB; then delete
pg_dump -h ${NEW_PUB_IP} -n _edb_replicator_sub > /tmp/2_edb_replicator_sub.sql
psql -h ${NEW_PUB_IP} -c "DROP SCHEMA _edb_replicator_sub CASCADE"

# Step 4 -- Restore the backups of schemas _edb_replicator_pub, _edb_replicator_sub, and _edb_scheduler onto the new publication DB (aka old subscription DB)
psql -h ${OLD_PUB_IP} < /tmp/2_edb_replicator_sub.sql 

# Step 5 -- Restore the backup of schema _edb_replicator_sub onto the new subscription DB (aka old publication DB)
# Also restore the backup of the replication triggers and trigger functions
cat /tmp/1__edb_* | psql -h ${NEW_PUB_IP} 

# Step 6 -- Update the control schema objects so that the publication database definition references the new publication/subscription databases
psql -h ${NEW_PUB_IP} -c "UPDATE _edb_replicator_pub.xdb_pub_database SET db_host = '${NEW_PUB_IP}'"
psql -h ${NEW_PUB_IP} -c "UPDATE _edb_replicator_sub.xdb_sub_database SET db_host = '${OLD_PUB_IP}'"

# Step 7 -- Edit the xDB Replication Configuration file to reflect new publication database IP address
sed -s "s/${OLD_PUB_IP}/${NEW_PUB_IP}/" /etc/edb-repl.conf 

# Step 8 -- Start up publication and subscription servers
service edb-xdbpubserver start
service edb-xdbsubserver start

# Step 9 -- Verify replication is working
psql -h ${NEW_PUB_IP} -c "SELECT * FROM pgbench_accounts WHERE aid = 1"
psql -h ${NEW_PUB_IP} -c "UPDATE pgbench_accounts SET filler ='test' WHERE aid=1"

# Verify not yet replicated
psql -h ${NEW_PUB_IP} -c "SELECT * FROM pgbench_accounts WHERE aid = 1"
psql -h ${OLD_PUB_IP} -c "SELECT * FROM pgbench_accounts WHERE aid = 1"

# Perform snapshot
java -jar ${XDB_HOME}/bin/edb-repcli.jar -dosnapshot xdbsub -repsvrfile ${XDB_HOME}/etc/xdb_subsvrfile.conf

# Verify replication successful
psql -h ${OLD_PUB_IP} -c "SELECT * FROM pgbench_accounts WHERE aid = 1"
psql -h ${NEW_PUB_IP} -c "SELECT * FROM pgbench_accounts WHERE aid = 1"
