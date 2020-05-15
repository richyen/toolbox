#!/bin/bash

### Provision a VM for assessment

# Take in env variable, or use commandline arg
#: "${SSH_PUB_KEY:=$1}"
#: "${SSH_PUB_KEY:?Need to set SSH_PUB_KEY}"
#echo "${SSH_PUB_KEY}"

### Environment
export PGUSER=postgres
export PGDATABASE=postgres
export PGVERSION=11
export PGDATA="/var/lib/db"
export PGHOME="/var/lib/pgsql"
export PGINSTALL="/usr/pgsql-${PGVERSION}/bin"
export PATH="${PGINSTALL}:${PATH}"

### Installation
rpm -ivh https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum -q -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -q -y install vim sudo postgresql${PGVERSION}-server

### Prepare user
mkdir ${PGHOME}/.ssh
echo ${SSH_PUB_KEY} >> ${PGHOME}/.ssh/authorized_keys
chmod 700 ${PGHOME}/.ssh
chmod 600 ${PGHOME}/.ssh/authorized_keys
chown -R postgres:postgres ${PGHOME}
restorecon -r -vv /var/lib/pgsql/.ssh    ### See https://ubuntuforums.org/showthread.php?t=1932058&s=00b938a71d52ba6c47b581befd8e71f6&p=12472161#post12472161

### Initialize new database
rm -rf ${PGDATA}/*
mkdir -p ${PGDATA}
chown postgres:postgres ${PGDATA}
sudo -iu postgres ${PGINSTALL}/initdb -D ${PGDATA}

### Move pg_wal and symlink
rm -rf /db/wal
mkdir -p /db
mv ${PGDATA}/pg_wal /db/wal
ln -s /db/wal ${PGDATA}/pg_wal

### Load up some data
sudo -iu postgres ${PGINSTALL}/pg_ctl -D ${PGDATA} -l ${PGDATA}/logfile start
createdb test_db
## Hide stuff in the myshop schema
psql -c "CREATE SCHEMA myshop" test_db
psql -c "ALTER SYSTEM SET autovacuum TO off"
psql -c "ALTER SYSTEM SET search_path TO myshop"
psql -c "SELECT pg_reload_conf()"
curl -s "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/edbstore.sql" \
  | sed -e "s/ public\./ myshop./" -e "s/edbstore/postgres/g"| psql test_db
psql -c "ALTER SYSTEM SET search_path TO DEFAULT"
psql -c "SELECT pg_reload_conf()"

### Configure database
psql -c "ALTER SYSTEM SET log_statement TO 'all'"
psql -c "ALTER SYSTEM SET wal_keep_segments to 1"
psql -c "ALTER SYSTEM SET logging_collector to off"
psql -c "ALTER SYSTEM SET log_directory to '/tmp'"
psql -c "ALTER SYSTEM SET log_filename to 'pg.log'"
psql -c "ALTER SYSTEM SET port to 5555"
sudo -iu postgres ${PGINSTALL}/pg_ctl -D ${PGDATA} stop

### Mangle permissions
chmod -R 755 ${PGDATA}
chmod 111 /db/wal
cat <<EOF  > ${PGINSTALL}/pg_hba.conf
local all all peer
EOF
chmod 444 ${PGINSTALL}/pg_hba.conf
rm -f ${PGDATA}/pg_hba.conf
ln -s ${PGINSTALL}/pg_hba.conf ${PGDATA}/pg_hba.conf

### Export environment vars; monitor command history
cat << EOF > /etc/profile.d/mytest.sh
export PATH=${PATH}
export PGUSER=${PGUSER}
export PGDATABASE=${PGDATABASE}
export HISTTIMEFORMAT="%Y-%m-%d %T "
shopt -s histappend
PROMPT_COMMAND='history -a >(tee -a ~/.bash_history | logger -t \"\$USER[\$\$] \$SSH_CONNECTION\")'
EOF

echo "test environment ready"

### For Docker entrypoint
# tail -f /dev/null
