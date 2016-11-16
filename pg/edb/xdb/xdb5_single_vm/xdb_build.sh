#!/bin/bash
export XDBHOME=/usr/ppas-xdb-5.1
export LICENSE_KEY=/Desktop/work/xdb_license.key

# Create a file with a row for each table in the publication, to be run within Docker container
#
cp /Desktop/ppas5445 /etc/init.d/
sudo -iu enterprisedb initdb -D /tmp/5445/data
sudo -iu enterprisedb mkdir /tmp/5445/data/pg_log
sed -i "s/port.*/port = 5445/" /tmp/5445/data/postgresql.conf
sed -i "s/32/0/" /tmp/5445/data/pg_hba.conf
/etc/init.d/ppas5445 start

pgbench -i -p5432 postgres
psql -p 5432 -c "select '' || table_schema || '.' || table_name from information_schema.tables where table_schema = 'public' and  table_name like '%pgbench%'" postgres | grep "\." | grep -v "pgbench_history" > ~/tables.txt
pg_dump -p5432 postgres -U enterprisedb | psql -p5445 postgres enterprisedb
createdb -p5432 xdb_ctl

echo "abc123" > ~/controlpass.in
echo "abc123" > ~/masterpass1.in
echo "abc123" > ~/masterpass2.in
java -jar $XDBHOME/bin/edb-repcli.jar -encrypt -input ~/masterpass1.in -output ~/masterpass1.out
java -jar $XDBHOME/bin/edb-repcli.jar -encrypt -input ~/masterpass2.in -output ~/masterpass2.out
java -jar $XDBHOME/bin/edb-repcli.jar -encrypt -input ~/controlpass.in -output ~/controlpass.out
echo -e "host=127.0.0.1\nport=9051\nuser=enterprisedb\npassword=`cat ~/controlpass.out`" > ~/repsvrfile
echo -e "java.rmi.server.hostname=127.0.0.1" >> ${XDBHOME}/etc/xdb_pubserver.conf
echo -e "\nlicense_key=${LICENSE_KEY}" >> /etc/edb-repl.conf
/etc/init.d/edb-xdbpubserver restart

MASTER1_ID=`java -jar $XDBHOME/bin/edb-repcli.jar -printmdndbid -repsvrfile ~/repsvrfile | grep -v 'Printing'`
MASTER2_ID=`java -jar $XDBHOME/bin/edb-repcli.jar -printpubdbids -repsvrfile ~/repsvrfile | grep -v 'Printing' | grep -v "^$MASTER1_ID$"`
java -jar $XDBHOME/bin/edb-repcli.jar -removepubdb -repsvrfile ~/repsvrfile -pubdbid $MASTER2_ID
java -jar $XDBHOME/bin/edb-repcli.jar -removepub my_pub -repgrouptype m -repsvrfile ~/repsvrfile
java -jar $XDBHOME/bin/edb-repcli.jar -removepubdb -repsvrfile ~/repsvrfile -pubdbid $MASTER1_ID

java -jar $XDBHOME/bin/edb-repcli.jar -addpubdb -repsvrfile ~/repsvrfile -dbtype enterprisedb -dbhost 127.0.0.1 -dbport 5432 -dbuser enterprisedb -dbpassfile ~/masterpass1.out -database postgres -repgrouptype m -nodepriority 1
MASTER1_ID=`java -jar $XDBHOME/bin/edb-repcli.jar -printmdndbid -repsvrfile ~/repsvrfile | grep -v 'Printing'`
java -jar $XDBHOME/bin/edb-repcli.jar -createpub my_pub -repsvrfile ~/repsvrfile -pubdbid $MASTER1_ID -reptype T -tables `cat ~/tables.txt | tr '\n' ' '` -repgrouptype m
java -jar $XDBHOME/bin/edb-repcli.jar -addpubdb -repsvrfile ~/repsvrfile -dbtype enterprisedb -dbhost 127.0.0.1 -dbport 5445 -dbuser enterprisedb -dbpassfile ~/masterpass2.out -database postgres -repgrouptype m -nodepriority 2 -replicatepubschema false
java -jar $XDBHOME/bin/edb-repcli.jar -confschedulemmr $MASTER1_ID -pubname my_pub -repsvrfile ~/repsvrfile -realtime 10

psql -c "update pgbench_accounts set filler = 'foobarbaz' where aid = 1" postgres
sleep 10
psql -c "select * from pgbench_accounts where aid = 1" -p5445 postgres
