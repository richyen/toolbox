#!/bin/bash

### Provision a VM for assessment

### TODO: Set these accordingly
YUMUSERNAME=##########
YUMPASSWORD=##########

# Take in env variable, or use commandline arg
: "${SSH_PUB_KEY:=$1}"
: "${SSH_PUB_KEY:?Need to set SSH_PUB_KEY}"
echo "${SSH_PUB_KEY}"

### Environment
PGMAJOR=11
PGPORT=5432
PGDATABASE=edb
PGUSER=enterprisedb
PGHOME=/var/lib/edb
PGBIN=/usr/edb/as${PGMAJOR}/bin
PATH=${PGBIN}:${PATH}
PGDATA=${PGHOME}/as${PGMAJOR}/data
PGLOG=${PGHOME}/as${PGMAJOR}/pgstartup.log

### Monitor command history
echo "export HISTTIMEFORMAT=\"%Y-%m-%d %T \"" >> /etc/bashrc
echo "PROMPT_COMMAND='history -a >(tee -a ~/.bash_history | logger -t \"\$USER[\$\$] \$SSH_CONNECTION\")'" >> /etc/bashrc

### Install EDBAS
rpm -ivh http://yum.enterprisedb.com/edbrepos/edb-repo-latest.noarch.rpm
sed -i "s/<username>:<password>/${YUMUSERNAME}:${YUMPASSWORD}/" /etc/yum.repos.d/edb.repo
yum -y update
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install edb-as${PGMAJOR}-server.x86_64 sudo wget edb-jdbc java-1.7.0-openjdk-devel

### Prepare user
mkdir ${PGHOME}/.ssh
echo ${SSH_PUB_KEY} >> ${PGHOME}/.ssh/authorized_keys
chmod 700 ${PGHOME}/.ssh
chmod 600 ${PGHOME}/.ssh/authorized_keys
chown -R ${PGUSER}:${PGUSER} ${PGHOME}
restorecon -r -vv ${PGHOME}/.ssh    ### See https://ubuntuforums.org/showthread.php?t=1932058&s=00b938a71d52ba6c47b581befd8e71f6&p=12472161#post12472161
echo "${PGUSER}    ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers
echo "export PATH=${PATH}" >> /etc/profile

### Initialize new database
rm -rf ${PGDATA}
sudo -u ${PGUSER} ${PGBIN}/initdb -D ${PGDATA}
sed -i "s/^PGPORT.*/PGPORT=${PGPORT}/" /etc/sysconfig/edb/as${PGMAJOR}
echo "export PGPORT=${PGPORT}"         >> /etc/profile.d/pg_env.sh
echo "export PGDATABASE=${PGDATABASE}" >> /etc/profile.d/pg_env.sh
echo "export PGUSER=${PGUSER}"         >> /etc/profile.d/pg_env.sh
echo "export PATH=${PATH}"             >> /etc/profile.d/pg_env.sh
echo "local  all         all                 peer"  >  ${PGDATA}/pg_hba.conf
echo "host   all         all      0.0.0.0/0  trust" >> ${PGDATA}/pg_hba.conf
mkdir ${PGDATA}/pg_log
chown ${PGUSER}:${PGUSER} ${PGDATA}/pg_log

### Start EDBAS
sudo -iu ${PGUSER} ${PGINSTALL}/pg_ctl -D ${PGDATA} -l ${PGDATA}/logfile start

### Prepare for assessment
mkdir ${PGHOME}/.ssh
echo ${SSH_PUB_KEY} >> ${PGHOME}/.ssh/authorized_keys
chmod 700 ${PGHOME}/.ssh
chmod 600 ${PGHOME}/.ssh/authorized_keys
wget "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/edb_sample.sql"
psql -h 127.0.0.1 -p ${PGPORT} ${PGDATABASE} ${PGUSER} < edb_sample.sql
rm -f edb_sample.sql
wget -P ${PGHOME} "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/testJava.java"
wget -P ${PGHOME} "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/top_performers.sql"
wget -P ${PGHOME} "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/update_data.sh"
cp /usr/edb/connectors/jdbc/edb-jdbc17.jar ${PGHOME}
chown -R ${PGUSER}:${PGUSER} ${PGHOME}

rm -f assessment_vm.sh
