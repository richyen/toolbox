#!/bin/bash

### Provision a VM for assessment

### Environment
export REPONAME=ppas95
export PGMAJOR=9.5
export PGPORT=5432
export PGDATABASE=edb
export PGUSER=enterprisedb
export PATH=/usr/ppas-${PGMAJOR}/bin:${PATH}
export PGDATA=/var/lib/ppas/${PGMAJOR}/data
export PGLOG=/var/lib/ppas/${PGMAJOR}/pgstartup.log

### TODO: Set these accordingly
YUMUSERNAME=######
YUMPASSWORD=######

### Install and configure EDBAS
rpm -ivh http://yum.enterprisedb.com/reporpms/${REPONAME}-repo-${PGMAJOR}-1.noarch.rpm
sed -i "s/<username>:<password>/${YUMUSERNAME}:${YUMPASSWORD}/" /etc/yum.repos.d/${REPONAME}.repo
yum -y update
yum -y install ${REPONAME}-server.x86_64 sudo wget
echo 'root:root'|chpasswd
adduser --home-dir /home/postgres --create-home postgres
echo 'postgres   ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers
echo 'postgres:postgres'|chpasswd
rm -rf ${PGDATA}
sudo -u enterprisedb /usr/ppas-${PGMAJOR}/bin/initdb -D ${PGDATA}
sed -i "s/^PGPORT.*/PGPORT=${PGPORT}/" /etc/sysconfig/ppas/ppas-${PGMAJOR}
echo "export PGPORT=${PGPORT}"         >> /etc/profile.d/pg_env.sh
echo "export PGDATABASE=${PGDATABASE}" >> /etc/profile.d/pg_env.sh
echo "export PGUSER=${PGUSER}"         >> /etc/profile.d/pg_env.sh
echo "export PATH=${PATH}"             >> /etc/profile.d/pg_env.sh
echo "local  all         all                 peer"  >  ${PGDATA}/pg_hba.conf
echo "host   all         all      0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf
mkdir ${PGDATA}/pg_log
chown enterprisedb:enterprisedb ${PGDATA}/pg_log
service ppas-9.5 start
curl "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/edb_sample.sql" | psql -h 127.0.0.1
wget "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/testJava.java"
wget "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/top_performers.sql"
wget "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/update_data.sh"

# rm -f assessment_vm.sh
