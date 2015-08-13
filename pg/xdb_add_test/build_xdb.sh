#!/bin/bash

PUBSVR_IP=`hostname -i`
export MDN_IP="172.17.1.0"
export OTHER_MASTER_IPS='
172.17.0.255
172.17.1.4
172.17.1.1
172.17.1.3
172.17.0.254
'

# Start xDB
createdb -h ${PUBSVR_IP} xdb_pub
service edb-xdbpubserver start

# Load data into MDN
pgbench -h ${MDN_IP} -i -F 10 -s 10 edb
# psql -h ${MDN_IP} -c "ALTER TABLE pgbench_history add primary key (tid,bid,aid,delta,mtime)" edb

# Build xDB replication infrastructure
java -jar /usr/ppas-xdb-5.1/bin/edb-repcli.jar -repsvrfile /usr/ppas-xdb-5.1/etc/xdb_repsvrfile.conf -uptime
java -jar /usr/ppas-xdb-5.1/bin/edb-repcli.jar -addpubdb -repsvrfile /usr/ppas-xdb-5.1/etc/xdb_repsvrfile.conf -dbtype enterprisedb -dbhost ${MDN_IP} -dbuser enterprisedb -dbpassword `cat /usr/ppas-xdb-5.1/etc/xdb_repsvrfile.conf | grep pass | cut -f2- -d'='` -database edb -repgrouptype m -nodepriority 1 -dbport 5432
java -jar /usr/ppas-xdb-5.1/bin/edb-repcli.jar -createpub xdbtest -repsvrfile /usr/ppas-xdb-5.1/etc/xdb_repsvrfile.conf -pubdbid 1 -reptype T -tables public.pgbench_accounts public.pgbench_branches public.pgbench_tellers -repgrouptype M -standbyconflictresolution 1:E 2:E 3:E

# Add other masters
for i in ${OTHER_MASTER_IPS}
do
    java -jar /usr/ppas-xdb-5.1/bin/edb-repcli.jar -repsvrfile /usr/ppas-xdb-5.1/etc/xdb_repsvrfile.conf -addpubdb -dbtype enterprisedb -dbhost ${i} -dbuser enterprisedb -dbpassword `cat /usr/ppas-xdb-5.1/etc/xdb_repsvrfile.conf | grep pass | cut -f2- -d'='` -database edb -repgrouptype m -dbport 5432 -initialsnapshot -replicatepubschema true
done

# Create Schedule
java -jar /usr/ppas-xdb-5.1/bin/edb-repcli.jar -repsvrfile /usr/ppas-xdb-5.1/etc/xdb_repsvrfile.conf -confschedulemmr basic_schedule -pubname xdbtest -realtime 5
