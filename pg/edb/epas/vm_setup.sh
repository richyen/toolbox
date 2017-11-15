#!/bin/bash

# Environment
REPONAME=ppas95
PGMAJOR=9.5
PGPORT=5432
PGDATABASE=edb
PGUSER=enterprisedb
PATH=/usr/ppas-${PGMAJOR}/bin:${PATH}
PGDATA=/var/lib/ppas/${PGMAJOR}/data
PGLOG=/var/lib/ppas/${PGMAJOR}/pgstartup.log
YUMUSERNAME=edb-richardyen                               
YUMPASSWORD=####
XDB_VERSION=6.0
INSTALLDIR=/usr/ppas-xdb-${XDB_VERSION}
JAVA_VERSION=1.7
EDBUSERNAME="richard.yen@enterprisedb.com"
EDBPASSWORD=####

# For EDBAS
rpm -ivh http://yum.enterprisedb.com/reporpms/${REPONAME}-repo-${PGMAJOR}-1.noarch.rpm
sed -i "s/<username>:<password>/${YUMUSERNAME}:${YUMPASSWORD}/" /etc/yum.repos.d/${REPONAME}.repo
yum -y update
yum -y install ${REPONAME}-server.x86_64 sudo wget java-${JAVA_VERSION}.0-openjdk-devel
echo 'root:root'|chpasswd
adduser --home-dir /home/postgres --create-home postgres
echo 'postgres   ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers
echo 'postgres:postgres'|chpasswd
rm -rf /var/lib/ppas/9.5/data/
sudo -u enterprisedb /usr/ppas-9.5/bin/initdb -D ${PGDATA}  
sed -i "s/^PGPORT.*/PGPORT=${PGPORT}/" /etc/sysconfig/ppas/ppas-${PGMAJOR}
echo "export PGPORT=${PGPORT}"         >> /etc/profile.d/pg_env.sh
echo "export PGDATABASE=${PGDATABASE}" >> /etc/profile.d/pg_env.sh
echo "export PGUSER=${PGUSER}"         >> /etc/profile.d/pg_env.sh
echo "export PATH=${PATH}"             >> /etc/profile.d/pg_env.sh
echo "local  all         all                 trust" >  ${PGDATA}/pg_hba.conf
echo "local  replication all                 trust" >> ${PGDATA}/pg_hba.conf
echo "host   replication enterprisedb  0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf
echo "host   all         all      0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf
cat postgresql.conf.new > /var/lib/ppas/9.5/data/postgresql.conf 
service ppas-9.5 start

# For XDB, if needed
wget http://get.enterprisedb.com/xdb/xdbreplicationserver-6.1.2-1-linux-x64.run
chmod 755 xdbreplicationserver-6.1.2-1-linux-x64.run 
./xdbreplicationserver-6.1.2-1-linux-x64.run --existing-user ${EDBUSERNAME} --existing-password ${EDBPASSWORD} --mode unattended --admin_user enterprisedb --admin_password abc123 --prefix ${INSTALLDIR}
echo "user=enterprisedb" > /usr/ppas-xdb-6.0/etc/xdb_repsvrfile.conf
echo "password=Cz0Ccyegvs8=" >> /usr/ppas-xdb-6.0/etc/xdb_repsvrfile.conf
ehco "port=9051" >> /usr/ppas-xdb-6.0/etc/xdb_repsvrfile.conf
echo "host=127.0.0.1" >> /usr/ppas-xdb-6.0/etc/xdb_repsvrfile.conf

# Additional config required to make this work--sets up replication
vi build_xdb_mmr_publication.sh 
./build_xdb_mmr_publication.sh 
psql -p 5432 edb enterprisedb < insert.sql 
/usr/ppas-9.5/bin/pgbench -P 30 -T 1800 -R 600 -f /home/ec2-user/bench.sql -p5432 -U enterprisedb edb 
