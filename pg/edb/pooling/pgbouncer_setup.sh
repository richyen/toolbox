#!/bin/bash

IP=${1}

if [[ "${IP}x" == "x" ]]
then
  echo "usage: $0 <target_db_ip_address>"
  exit 1
fi

PGB_VERSION="edb-pgbouncer19"
PGB_SERVICE="edb-pgbouncer-1.9"
CONF_DIR="/etc/edb/pgbouncer1.9"
CONF_FILE="${PGB_SERVICE}.ini"
LOG_FILE="/var/log/edb/pgbouncer1.9/${PGB_SERVICE}.log"
SUPERUSER="enterprisedb"

# verify target database connectivity
export PGPASSWORD='abc123'
psql -h ${IP} -U ${SUPERUSER} -c "select 'password worked'"

PASSWORD_HASH=`psql -h ${IP} -U ${SUPERUSER} -Atc "select passwd from pg_shadow where usename = '${SUPERUSER}'"`

# install pgbouncer
yum -y --enablerepo=enterprisedb-tools --enablerepo=enterprisedb-dependencies install ${PGB_VERSION}

# configure pgbouncer
sed -e "s@^listen_addr = 127.0.0.1@listen_addr = *@g" \
 -e "s@^listen_port = [0-9]\+@listen_port = 6432@g" \
 -e "s@^auth_type = [a-zA-Z0-9]\+@auth_type = hba@g" \
 -e "s@^;auth_hba_file =@auth_hba_file = ${CONF_DIR}/bouncer_hba.conf@g" \
 -e "s@^admin_users = \(.\+\)@admin_users = \1, ${SUPERUSER}@g" \
 -e "s@^stats_users = \(.\+\)@stats_users = \1, ${SUPERUSER}@g" \
 -e "s@^pool_mode = [a-zA-Z0-9]\+@pool_mode = session@g" \
 -e "s@^max_client_conn = [0-9]\+@max_client_conn = 2000@g" \
 -i ${CONF_DIR}/${CONF_FILE}

# create databases for pgbouncer
sed "/^\[databases\]/a  prodb = host=${IP} port=5432 dbname=edb pool_size=50" -i ${CONF_DIR}/${CONF_FILE}

# create bouncer_hba
echo "host  all  all  0.0.0.0/0 trust" >> ${CONF_DIR}/bouncer_hba.conf

# set password
echo "\"${SUPERUSER}\" \"${PASSWORD_HASH}\"" >> ${CONF_DIR}/userlist.txt

# start pgbouncer
service ${PGB_SERVICE} start

# test connection
psql -h 127.0.0.1 -p 6432 -U ${SUPERUSER} -d pgbouncer -c "show config" | head -n5
psql -h 127.0.0.1 -p 6432 -U ${SUPERUSER} -d prodb -c "select 1" | head -n5

# use desired mask
sed -i "s/0.0.0.0\/0/127.0.0.1\/0/" ${CONF_DIR}/bouncer_hba.conf
psql -h 127.0.0.1 -p 6432 -U ${SUPERUSER} -d pgbouncer -c "RELOAD"
sleep 5

# test connection again
psql -h 127.0.0.1 -p 6432 -U ${SUPERUSER} -d pgbouncer -c "show config" | head -n5
psql -h 127.0.0.1 -p 6432 -U ${SUPERUSER} -d prodb -c "select 1" | head -n5

# show warning/error in log
cat ${LOG_FILE}
