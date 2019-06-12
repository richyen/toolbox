#!/bin/bash

PUBSVR_IP=`hostname -i`

# Make these IPs available for other scripts
export MDN_IP=`hostname -i`
export OTHER_MASTER_IPS=' 172.17.0.3'

XDB_HOME="/usr/ppas-xdb-6.2"
XDB_PORT="5432"

# Start xDB
rm -f /var/run/edb/xdbpubserver/edb-xdbpubserver.pid
rm -f /var/run/edb-xdbpubserver/edb-xdbpubserver.pid
service edb-xdbpubserver start

# Load data into MDN
pgbench -h ${MDN_IP} -i edb
psql -h ${MDN_IP} -c "ALTER TABLE public.pgbench_accounts REPLICA IDENTITY FULL" edb

# Build xDB replication infrastructure
java -jar ${XDB_HOME}/bin/edb-repcli.jar -repsvrfile ${XDB_HOME}/etc/xdb_repsvrfile.conf -uptime
java -jar ${XDB_HOME}/bin/edb-repcli.jar -addpubdb -repsvrfile ${XDB_HOME}/etc/xdb_repsvrfile.conf -dbtype enterprisedb -dbhost ${MDN_IP} -dbuser enterprisedb -dbpassword `cat ${XDB_HOME}/etc/xdb_repsvrfile.conf | grep pass | cut -f2- -d'='` -database edb -repgrouptype m -nodepriority 1 -dbport ${XDB_PORT} -changesetlogmode W
java -jar ${XDB_HOME}/bin/edb-repcli.jar -createpub xdbtest -repsvrfile ${XDB_HOME}/etc/xdb_repsvrfile.conf -pubdbid 1 -reptype T -tablesfilterclause "1:pgba_10_20_30:aid in (10,20,30)" -tables public.pgbench_accounts public.pgbench_branches public.pgbench_tellers -repgrouptype M -standbyconflictresolution 1:E 2:E 3:E
# Add other masters
for i in ${OTHER_MASTER_IPS}
do
    java -jar ${XDB_HOME}/bin/edb-repcli.jar -repsvrfile ${XDB_HOME}/etc/xdb_repsvrfile.conf -addpubdb -dbtype enterprisedb -dbhost ${i} -dbuser enterprisedb -dbpassword `cat ${XDB_HOME}/etc/xdb_repsvrfile.conf | grep pass | cut -f2- -d'='` -database edb -repgrouptype m -dbport  ${XDB_PORT} -initialsnapshot -replicatepubschema true -changesetlogmode W
done

# Create Schedule
C=`java -jar ${XDB_HOME}/bin/edb-repcli.jar -printpubdbids -repsvrfile ${XDB_HOME}/etc/xdb_repsvrfile.conf | grep -v "Printing" | sort | tail -1`
echo ${C}
F=`java -jar ${XDB_HOME}/bin/edb-repcli.jar -printpubfilterslist xdbtest -repsvrfile ${XDB_HOME}/etc/xdb_repsvrfile.conf | cut -f1 -d' ' | cut -f2 -d':' | grep -v "Printing" | sort | tail -1`
echo ${F}
java -jar ${XDB_HOME}/bin/edb-repcli.jar -repsvrfile ${XDB_HOME}/etc/xdb_repsvrfile.conf -enablefilter -dbid ${C} -filterids ${F}
java -jar ${XDB_HOME}/bin/edb-repcli.jar -repsvrfile ${XDB_HOME}/etc/xdb_repsvrfile.conf -dommrsnapshot xdbtest -pubhostdbid ${C}
