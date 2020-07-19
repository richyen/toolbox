#!/bin/bash

# Install -contrib on db2
if [[ ${HOSTNAME} == 'pg2' ]]; then
  echo "Installing -contrib"
  yum -y install postgresql${PGMAJOR}-contrib
fi

# Start up postgres on all containers
su - postgres -c "pg_ctl -D /var/lib/pgsql/${PGMAJOR}/data start"

# Create demo schema
if [[ ${HOSTNAME} == 'pg1' ]]; then
  pgbench -iU postgres postgres
else
  psql -c "create extension postgres_fdw" postgres postgres
  psql -c "CREATE SERVER foreign_server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'pg1', port '5432', dbname 'postgres')" postgres postgres
  psql -c "CREATE USER MAPPING FOR postgres SERVER foreign_server OPTIONS (user 'postgres', password 'password')" postgres postgres
  psql -c "CREATE FOREIGN TABLE foreign_table (aid integer NOT NULL, bid integer, abalance integer, filler text) SERVER foreign_server OPTIONS (schema_name 'public', table_name 'pgbench_accounts')"
  psql -c "SELECT * FROM foreign_table LIMIT 10"
fi

# Keep things running
tail -f /dev/null
