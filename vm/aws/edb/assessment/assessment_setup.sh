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
rpm -ivh http://yum.enterprisedb.com/edbrepos/edb-repo-latest.noarch.rpm
sed -i "s/<username>:<password>/${YUMUSERNAME}:${YUMPASSWORD}/" /etc/yum.repos.d/edb.repo
yum -y update
yum -y install epel-release
yum -y --enablerepo=${REPONAME} --enablerepo=enterprisedb-tools --enablerepo=enterprisedb-dependencies install ${REPONAME}-server.x86_64 sudo wget edb-jdbc java-1.7.0-openjdk-devel
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
wget "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/edb_sample.sql"
psql -h 127.0.0.1 < edb_sample.sql
rm -f edb_sample.sql
wget -P ~enterprisedb "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/testJava.java"
wget -P ~enterprisedb "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/top_performers.sql"
wget -P ~enterprisedb "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/update_data.sh"
cp /usr/edb/connectors/jdbc/edb-jdbc17.jar ~enterprisedb/
chown -R enterprisedb:enterprisedb ~enterprisedb

rm -f assessment_vm.sh
