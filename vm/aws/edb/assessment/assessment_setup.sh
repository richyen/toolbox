#!/bin/bash

### Provision a VM for assessment

### Environment
REPONAME=ppas95
PGMAJOR=9.5
PGPORT=5432
PGDATABASE=edb
PGUSER=enterprisedb
EDBHOME="/var/lib/ppas"
PATH=/usr/ppas-${PGMAJOR}/bin:${PATH}
PGDATA=/var/lib/ppas/${PGMAJOR}/data
PGLOG=/var/lib/ppas/${PGMAJOR}/pgstartup.log

### TODO: Set these accordingly
YUMUSERNAME=######
YUMPASSWORD=######

### Monitor command history
echo "export HISTTIMEFORMAT=\"%Y-%m-%d %T \"" >> /etc/bashrc
echo "PROMPT_COMMAND='history -a >(tee -a ~/.bash_history | logger -t \"\$USER[\$\$] \$SSH_CONNECTION\")'" >> /etc/bashrc

### Install EDBAS
rpm -ivh http://yum.enterprisedb.com/edbrepos/edb-repo-latest.noarch.rpm
sed -i "s/<username>:<password>/${YUMUSERNAME}:${YUMPASSWORD}/" /etc/yum.repos.d/edb.repo
yum -y update
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y --enablerepo=${REPONAME} --enablerepo=enterprisedb-tools --enablerepo=enterprisedb-dependencies install ${REPONAME}-server.x86_64 sudo wget edb-jdbc java-1.7.0-openjdk-devel

### Initialize new database
rm -rf ${PGDATA}
sudo -u ${PGUSER} /usr/ppas-${PGMAJOR}/bin/initdb -D ${PGDATA}
sed -i "s/^PGPORT.*/PGPORT=${PGPORT}/" /etc/sysconfig/ppas/ppas-${PGMAJOR}
echo "export PGPORT=${PGPORT}"         >> /etc/profile.d/pg_env.sh
echo "export PGDATABASE=${PGDATABASE}" >> /etc/profile.d/pg_env.sh
echo "export PGUSER=${PGUSER}"         >> /etc/profile.d/pg_env.sh
echo "export PATH=${PATH}"             >> /etc/profile.d/pg_env.sh
echo "local  all         all                 peer"  >  ${PGDATA}/pg_hba.conf
echo "host   all         all      0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf
mkdir ${PGDATA}/pg_log
chown ${PGUSER}:${PGUSER} ${PGDATA}/pg_log

### Set user info
adduser --home-dir /home/postgres --create-home postgres
echo 'postgres    ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers
echo "${PGUSER}   ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers

### Start EDBAS
systemctl start ppas-${PGMAJOR}

### Prepare for assessment
mkdir ${EDBHOME}/.ssh
touch ${EDBHOME}/.ssh/authorized_keys
chmod 700 ${EDBHOME}/.ssh
chmod 600 ${EDBHOME}/.ssh/authorized_keys
wget "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/edb_sample.sql"
psql -h 127.0.0.1 < edb_sample.sql
rm -f edb_sample.sql
wget -P ${EDBHOME} "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/testJava.java"
wget -P ${EDBHOME} "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/top_performers.sql"
wget -P ${EDBHOME} "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/update_data.sh"
cp /usr/edb/connectors/jdbc/edb-jdbc17.jar ${EDBHOME}
chown -R ${PGUSER}:${PGUSER} ${EDBHOME}

rm -f assessment_vm.sh
