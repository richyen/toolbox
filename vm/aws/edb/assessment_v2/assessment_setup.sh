#!/bin/bash

### Provision a VM for assessment

### TODO: Set accordingly
SSH_PUB_KEY="######"

### Environment
export PGUSER=postgres
export PGDATABASE=postgres
export PGDATA="/var/lib/pgsql/10/data"
export PGHOME="/var/lib/pgsql"
export PGINSTALL="/usr/pgsql-10/bin"
export PATH="${PGINSTALL}:${PATH}"

### Monitor command history
echo "export HISTTIMEFORMAT=\"%Y-%m-%d %T \"" >> /etc/bashrc
echo "PROMPT_COMMAND='history -a >(tee -a ~/.bash_history | logger -t \"\$USER[\$\$] \$SSH_CONNECTION\")'" >> /etc/bashrc

rpm -ivh https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-redhat10-10-2.noarch.rpm
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install vim sudo git postgresql10-server pgbouncer

### Prepare user
mkdir ${PGHOME}/.ssh
echo ${SSH_PUB_KEY} >> ${PGHOME}/.ssh/authorized_keys
chmod 700 ${PGHOME}/.ssh
chmod 600 ${PGHOME}/.ssh/authorized_keys
chown -R postgres:postgres ${PGHOME}
echo 'postgres    ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers
echo "export PATH=${PATH}" >> /etc/profile

### Initialize new database
rm -rf ${PGDATA}
sudo -lu postgres ${PGINSTALL}/initdb -D ${PGDATA}
sudo -lu postgres ${PGINSTALL}/pg_ctl -D ${PGDATA} -l ${PGDATA}/logfile start
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

chown -R pgbouncer:pgbouncer /etc/pgbouncer
echo '"benchuser" "md5f141e18e8635983f5f719a405cf1a49d"' > /tmp/userlist.txt
