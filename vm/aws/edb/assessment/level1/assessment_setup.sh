#!/bin/bash

### Provision a VM for assessment

### Environment
export PGUSER=postgres
export PGDATABASE=postgres
export PGVERSION=11
export PGDATA="/var/lib/pgsql/${PGVERSION}/data"
export PGHOME="/var/lib/pgsql"
export PGINSTALL="/usr/pgsql-${PGVERSION}/bin"
export PATH="${PGINSTALL}:${PATH}"

if [[ -z ${USEDOCKER} ]]; then
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
  echo 'postgres    ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers
  echo "export PATH=${PATH}" >> /etc/profile
fi

### Initialize new database
rm -rf ${PGDATA}/*
sudo -iu postgres ${PGINSTALL}/initdb -D ${PGDATA} --auth-host=password
sudo -iu postgres ${PGINSTALL}/pg_ctl -D ${PGDATA} -l ${PGDATA}/logfile start
psql -c "ALTER SYSTEM SET log_statement TO 'all'"
psql -c "ALTER SYSTEM SET log_min_duration_statement TO 0"
psql -c "ALTER SYSTEM SET log_checkpoints TO on"
psql -c "ALTER SYSTEM SET log_connections TO on"
psql -c "ALTER SYSTEM SET log_disconnections TO on"
psql -c "ALTER SYSTEM SET log_lock_waits TO on"
psql -c "ALTER SYSTEM SET log_temp_files TO 0"
psql -c "ALTER SYSTEM SET log_autovacuum_min_duration TO 0"
psql -c "ALTER SYSTEM SET log_line_prefix TO '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h'"
psql -c "SELECT pg_reload_conf()"

yum -y -q install pgbouncer
chown -R pgbouncer:pgbouncer /etc/pgbouncer
echo '"benchuser" "md5f141e18e8635983f5f719a405cf1a49d"' > /tmp/userlist.txt
curl -s "https://raw.githubusercontent.com/richyen/toolbox/master/vm/aws/edb/assessment/edbstore.sql" > /tmp/edbstore.sql
### update_data.sh located at https://gist.githubusercontent.com/richyen/3d4b1dca76a8216356e800456f36e410/raw/8a16e180abb2a5f9e7b52efd8e1dcbbcd6924222/update_data.sh

echo "test environment ready"

/docker/apply_answers.sh
/docker/check_answers.sh
### For Docker entrypoint
[[ -z ${USEDOCKER} ]] && exit
tail -f /dev/null
