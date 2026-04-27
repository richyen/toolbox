#!/bin/bash

PUB_NAME="testpub"
SUB_NAME="testsub"
DBNAME="pglogical_test"

# Create publication database
docker exec -u postgres pg1 psql -c "CREATE DATABASE ${DBNAME}"
docker exec -u postgres pg1 pgbench -i ${DBNAME}
docker exec -u postgres pg1 psql -c "CREATE PUBLICATION ${PUB_NAME} FOR ALL TABLES" ${DBNAME}

# Create subscription database and copy schema from publisher
docker exec -u postgres pg2 psql -c "CREATE DATABASE ${DBNAME}"
docker exec -u postgres pg2 bash -c "pg_dump -h pg1 -s ${DBNAME} | psql ${DBNAME}"

# Create subscription
docker exec -u postgres pg2 psql -c "CREATE SUBSCRIPTION ${SUB_NAME} CONNECTION 'host=pg1 dbname=${DBNAME}' PUBLICATION ${PUB_NAME}" ${DBNAME}

# Test
docker exec -u postgres pg1 pgbench -t 100 ${DBNAME}
docker exec -u postgres pg1 psql -c "UPDATE pgbench_accounts SET filler = 'new filler' WHERE aid = 1" ${DBNAME}
echo "Waiting for replication to sync..."
sleep 2
docker exec -u postgres pg2 psql -c "SELECT * FROM pgbench_accounts WHERE aid = 1" ${DBNAME}
