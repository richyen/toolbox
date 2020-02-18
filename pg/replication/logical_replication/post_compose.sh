#!/bin/bash

PGVERSION=11
PGDATA="/var/lib/pgsql/${PGVERSION}/data"
SVC="postgresql-${PGVERSION}"

# (Un)comment to toggle between community and EDBAS
#ver="edb"
if [[ "${ver}" == "edb" ]]
then
  PGDATA="/var/lib/edb/as${PGVERSION}/data"
  SVC="edb-as-${PGVERSION}"
fi

PUB_NAME="testpub"
SUB_NAME="testsub"
DBNAME="pglogical_test"

# Start up PG
docker exec -it pg1 sed -i "s/^#*wal_level.*/wal_level=logical/" ${PGDATA}/postgresql.conf
docker exec -it -u postgres pg1 pg_ctl start
docker exec -it pg2 sed -i "s/^#*wal_level.*/wal_level=logical/" ${PGDATA}/postgresql.conf
docker exec -it -u postgres pg2 pg_ctl start

# Create publication database
docker exec -it pg1 psql -c "CREATE DATABASE ${DBNAME}"
docker exec -it pg1 pgbench -i ${DBNAME}
docker exec -it pg1 psql -c "CREATE PUBLICATION ${PUB_NAME} FOR ALL TABLES" ${DBNAME}

# Create subscription database
docker exec -it pg2 psql -c "CREATE DATABASE ${DBNAME}"
docker exec -it pg2 psql -c "CREATE TABLE foo (id int, name text)" ${DBNAME}
docker exec -it pg2 bash -c "pg_dump -h pg1 -s ${DBNAME} | psql ${DBNAME}"

# Create subscription
docker exec -it pg2 psql -c "CREATE SUBSCRIPTION ${SUB_NAME} CONNECTION 'host=pg1 dbname=${DBNAME}' PUBLICATION ${PUB_NAME}" ${DBNAME}

# Test
docker exec -it pg1 pgbench -t 100 ${DBNAME}
docker exec -it pg1 psql -c "UPDATE pgbench_accounts set filler = 'new filler' where aid = 1" ${DBNAME}
docker exec -it pg2 psql -c "SELECT * FROM pgbench_accounts WHERE aid = 1" ${DBNAME}
