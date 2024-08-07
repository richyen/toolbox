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
yum -y -q install sudo repmgr_${PGVERSION}
# systemctl enable postgresql-${PGVERSION}
echo "PATH=/usr/pgsql-${PGVERSION}/bin:\${PATH}" >> ~postgres/.bash_profile
echo "PGDATA=/var/lib/pgsql/${PGVERSION}/data" >> ~postgres/.bash_profile

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
  echo "data_directory='${PGDATA}'" >> ${REPMGR_CONF}
  echo "conninfo='host=10.0.5.101 port=5432 user=repmgr dbname=repmgr connect_timeout=2'" >> ${REPMGR_CONF}
  echo "log_file='/var/log/repmgr/11/repmgr-11.log'" >> ${REPMGR_CONF}
  echo "pg_bindir='/usr/pgsql-11/bin'" >> ${REPMGR_CONF}
  echo "promote_command='/usr/pgsql-11/bin/repmgr standby promote -f /etc/repmgr/11/repmgr.conf'" >> ${REPMGR_CONF}
  echo "follow_command='/usr/pgsql-11/bin/repmgr standby follow -f /etc/repmgr/11/repmgr.conf'" >> ${REPMGR_CONF}
  echo "service_start_command='sudo systemctl start postgresql-11'" >> ${REPMGR_CONF}
  echo "service_stop_command='sudo systemctl stop postgresql-11'" >> ${REPMGR_CONF}
  echo "service_restart_command='sudo systemctl restart postgresql-11'" >> ${REPMGR_CONF}
  echo "service_reload_command='sudo systemctl reload postgresql-11'" >> ${REPMGR_CONF}


  ## Register master node to repmgr
  su - postgres -c "repmgr -f ${REPMGR_CONF} primary register"
  su - postgres -c "repmgr -f ${REPMGR_CONF} cluster show"

  ## Create some data
  psql repmgr -c "CREATE TABLE foo (id int, name text)"
  psql repmgr -c "INSERT INTO foo VALUES (generate_series(1,100000),'bar')"

  # Verify replication worked
  psql -h 10.0.5.101 repmgr -c "SELECT count(*), 'should be 100,000' FROM foo"
  psql repmgr -c "INSERT INTO foo VALUES (generate_series(100001,200000),'bar')"
  sleep 10;
  psql -h 10.0.5.102 repmgr -c "SELECT count(*), 'should be 200,000' FROM foo"
fi

if [[ $( hostname ) == 'pg2' ]]; then
  ## Configure repmgr for standby node
  echo "node_id=2" > ${REPMGR_CONF}
  echo "node_name=node2" >> ${REPMGR_CONF}
  echo "data_directory='${PGDATA}'" >> ${REPMGR_CONF}
  echo "conninfo='host=10.0.5.102 port=5432 user=repmgr dbname=repmgr connect_timeout=2'" >> ${REPMGR_CONF}
  echo "log_file='/var/log/repmgr/11/repmgr-11.log'" >> ${REPMGR_CONF}
  echo "pg_bindir='/usr/pgsql-11/bin'" >> ${REPMGR_CONF}
  echo "promote_command='/usr/pgsql-11/bin/repmgr standby promote -f /etc/repmgr/11/repmgr.conf'" >> ${REPMGR_CONF}
  echo "follow_command='/usr/pgsql-11/bin/repmgr standby follow -f /etc/repmgr/11/repmgr.conf'" >> ${REPMGR_CONF}
  echo "service_start_command='sudo systemctl start postgresql-11'" >> ${REPMGR_CONF}
  echo "service_stop_command='sudo systemctl stop postgresql-11'" >> ${REPMGR_CONF}
  echo "service_restart_command='sudo systemctl restart postgresql-11'" >> ${REPMGR_CONF}
  echo "service_reload_command='sudo systemctl reload postgresql-11'" >> ${REPMGR_CONF}

  R=$( psql -h 10.0.5.101 -Atc "select count(*) FROM foo" repmgr postgres 2>/dev/null )
  C=${?}
  while [[ ${C} -ne 0 ]]; do
    echo "Waiting for pg1 to be up"
    R=$( psql -h 10.0.5.101 -Atc "select count(*) FROM foo" repmgr postgres 2>/dev/null )
    C=${?}
    sleep 1
  done

  # Clone the master node into the standby node
  su - postgres -c "repmgr -h 10.0.5.101 -U repmgr -d repmgr -f ${REPMGR_CONF} standby clone"

  systemctl start postgresql-${PGVERSION}

  # Register master node to repmgr
  su - postgres -c "repmgr -f ${REPMGR_CONF} standby register"
  sleep 5;
  su - postgres -c "repmgr -f ${REPMGR_CONF} cluster show"
fi
