#!/bin/bash

### Simple script to provision a VM (currently for RHEL 7 on AWS, but can be easily changed to handle other types)

### Environment
REPONAME=ppas95
PGMAJOR=9.5
PGPORT=5432
PGDATABASE=edb
PGUSER=enterprisedb
PATH=/usr/ppas-${PGMAJOR}/bin:${PATH}
PGDATA=/var/lib/ppas/${PGMAJOR}/data
PGLOG=/var/lib/ppas/${PGMAJOR}/pgstartup.log
XDB_VERSION=6.0
XDB_INSTALLDIR=/usr/ppas-xdb-${XDB_VERSION}
JAVA_VERSION=1.7
EDBUSERNAME="richard.yen@enterprisedb.com"
YUMUSERNAME=edb-richardyen                               

### TODO: Set these accordingly
EDBPASSWORD=####
YUMPASSWORD=####

### For EDBAS
rpm -ivh http://yum.enterprisedb.com/reporpms/${REPONAME}-repo-${PGMAJOR}-1.noarch.rpm
sed -i "s/<username>:<password>/${YUMUSERNAME}:${YUMPASSWORD}/" /etc/yum.repos.d/${REPONAME}.repo
yum -y update
yum -y install ${REPONAME}-server.x86_64 sudo wget java-${JAVA_VERSION}.0-openjdk-devel
echo 'root:root'|chpasswd
adduser --home-dir /home/postgres --create-home postgres
echo 'postgres   ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers
echo 'postgres:postgres'|chpasswd
rm -rf ${PGDATA{
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

### For streaming replication, if desired
# sudo -u enterprisedb /usr/ppas-9.5/bin/pg_basebackup -xRP -h 10.228.145.74 -p5432 -D ${PGDATA}

### TODO: Put your desired postgresql.conf in here if you want something customized
# cat ${HOME}/postgresql.conf > ${PGDATA}/postgresql.conf
service ppas-9.5 start

### For XDB, if needed
# wget http://get.enterprisedb.com/xdb/xdbreplicationserver-6.1.2-1-linux-x64.run
# chmod 755 xdbreplicationserver-6.1.2-1-linux-x64.run 
# ${HOME}/xdbreplicationserver-6.1.2-1-linux-x64.run --existing-user ${EDBUSERNAME} --existing-password ${EDBPASSWORD} --mode unattended --admin_user enterprisedb --admin_password abc123 --prefix ${INSTALLDIR}
# echo "user=enterprisedb" > ${XDB_INSTALLDIR}/etc/xdb_repsvrfile.conf
# echo "password=Cz0Ccyegvs8=" >> ${XDB_INSTALLDIR}/etc/xdb_repsvrfile.conf
# echo "port=9051" >> ${XDB_INSTALLDIR}/etc/xdb_repsvrfile.conf
# echo "host=127.0.0.1" >> ${XDB_INSTALLDIR}/etc/xdb_repsvrfile.conf
# cat ${HOME}/xdb_pubserver.conf > ${XDB_INSTALLDIR}/etc/xdb_pubserver.conf

### TODO: Additional config required to make this work--sets up replication
# ${HOME}/build_xdb_mmr_publication.sh 
# psql -p 5432 edb enterprisedb < insert.sql 
# /usr/ppas-9.5/bin/pgbench -P 30 -T 1800 -R 600 -f ${HOME}/bench.sql -p5432 -U enterprisedb edb 
