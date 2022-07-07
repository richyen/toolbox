#!/bin/bash

## Set environment variables
PGVERSION=11
export PGUSER=postgres
export PGDATABASE=postgres
export PGDATA="/var/lib/pgsql/${PGVERSION}/data"
export REPMGR_CONF=/etc/repmgr/${PGVERSION}/repmgr.conf

## Install postgres and repmgr
yum install -y -q https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install -y -q postgresql${PGVERSION}-server
yum -y -q install repmgr_${PGVERSION}
# systemctl enable postgresql-${PGVERSION}
echo "PATH=/usr/pgsql-${PGVERSION}/bin:\${PATH}" >> ~${PGUSER}/.bash_profile
echo "PGDATA=/var/lib/pgsql/${PGVERSION}/data" >> ~${PGUSER}/.bash_profile

if [[ $( hostname ) == 'pg1' ]]; then
  ## Configure postgres
  /usr/pgsql-${PGVERSION}/bin/postgresql-${PGVERSION}-setup initdb
  sed -i "s/#listen_addresses.*/listen_addresses = '*'/" ${PGDATA}/postgresql.conf
  sed -i "s/#hot_standby = off/hot_standby = on/" ${PGDATA}/postgresql.conf
  sed -i "s/#wal_log_hints.*/wal_log_hints = on/" ${PGDATA}/postgresql.conf
  sed -i "s/32/0/g" ${PGDATA}/pg_hba.conf
  sed -i "s/peer/trust/" ${PGDATA}/pg_hba.conf
  sed -i "s/ident/trust/" ${PGDATA}/pg_hba.conf
  systemctl start postgresql-${PGVERSION}

  ## Create repmgr user and database (for demo)
  createuser -s repmgr
  createdb repmgr -O repmgr

  ## Configure repmgr for master node
  echo "node_id=1" > ${REPMGR_CONF}
  echo "node_name=node1" >> ${REPMGR_CONF}
  echo "conninfo='host=pg1 port=5432 user=repmgr dbname=repmgr connect_timeout=2'" >> ${REPMGR_CONF}
  echo "data_directory='${PGDATA}'" >> ${REPMGR_CONF}

  ## Register master node to repmgr
  su - ${PGUSER} -c "repmgr -f ${REPMGR_CONF} primary register"
  su - ${PGUSER} -c "repmgr -f ${REPMGR_CONF} cluster show"

  ## Create some data
  psql repmgr -c "CREATE EXTENSION repmgr"
  psql repmgr -c "CREATE TABLE foo (id int, name text)"
  psql repmgr -c "INSERT INTO foo VALUES (generate_series(1,100000),'bar')"
fi

if [[ $( hostname ) == 'pg2' ]]; then
  ## Configure repmgr for standby node
  echo "node_id=2" > ${REPMGR_CONF}
  echo "node_name=node2" >> ${REPMGR_CONF}
  echo "conninfo='host=pg2 port=5432 user=repmgr dbname=repmgr connect_timeout=2'" >> ${REPMGR_CONF}
  echo "data_directory='${PGDATA}'" >> ${REPMGR_CONF}

  R=$( psql -h pg1 -Atc "select count(*) FROM foo" repmgr ${PGUSER} 2>/dev/null )
  C=${?}
  while [[ ${C} -ne 0 ]]; do
    echo "Waiting for pg1 to be up"
    R=$( psql -h pg1 -Atc "select count(*) FROM foo" repmgr ${PGUSER} 2>/dev/null )
    C=${?}
    sleep 1
  done

  # Clone the master node into the standby node
  su - ${PGUSER} -c "repmgr -h pg1 -U repmgr -d repmgr -f ${REPMGR_CONF} standby clone"

  systemctl start postgresql-${PGVERSION}

  # Register master node to repmgr
  su - ${PGUSER} -c "repmgr -f ${REPMGR_CONF} standby register"
  sleep 5;
  su - ${PGUSER} -c "repmgr -f ${REPMGR_CONF} cluster show"
fi
