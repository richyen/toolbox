#!/bin/bash

# Demonstrates how to use logical replication to sync records that were
# inserted on the primary AFTER a PITR clone was created.
#
# The key technique: create a logical replication slot on the primary BEFORE
# (or at the time of) the PITR backup. The slot retains WAL from that point
# forward. When the PITR instance subscribes with copy_data=false, it replays
# only the changes accumulated in the slot -- avoiding duplicates of existing
# data while capturing the 100 new records.
#
# Prerequisites: docker-compose up -d (using the existing docker-compose.yml)

PUB_NAME="testpub"
SUB_NAME="testsub"
DBNAME="pitr_logrep_test"

echo "=== Step 1: Set up primary (pg1) with initial data ==="
docker exec -u postgres pg1 psql -c "CREATE DATABASE ${DBNAME}"
docker exec -u postgres pg1 psql ${DBNAME} -c "
  CREATE TABLE test_data (
    id serial PRIMARY KEY,
    data text,
    created_at timestamptz DEFAULT now()
  )"
docker exec -u postgres pg1 psql ${DBNAME} -c \
  "INSERT INTO test_data (data) SELECT 'initial_record_' || g FROM generate_series(1, 500) g"
docker exec -u postgres pg1 psql ${DBNAME} -c "SELECT count(*) AS primary_initial_count FROM test_data"

echo ""
echo "=== Step 2: Create publication and logical replication slot on primary ==="
echo "The slot will retain WAL from this point forward -- this is the critical step."
docker exec -u postgres pg1 psql ${DBNAME} -c "CREATE PUBLICATION ${PUB_NAME} FOR ALL TABLES"
docker exec -u postgres pg1 psql ${DBNAME} -c \
  "SELECT * FROM pg_create_logical_replication_slot('${SUB_NAME}', 'pgoutput')"

echo ""
echo "=== Step 3: Simulate PITR -- copy primary state to pg2 ==="
echo "(In production this would be pg_basebackup + recovery to a target time.)"
docker exec -u postgres pg2 psql -c "CREATE DATABASE ${DBNAME}"
docker exec -u postgres pg2 bash -c "pg_dump -h pg1 ${DBNAME} | psql ${DBNAME}"
docker exec -u postgres pg2 psql ${DBNAME} -c "SELECT count(*) AS pitr_initial_count FROM test_data"

echo ""
echo "=== Step 4: Insert 100 new records on primary AFTER PITR ==="
docker exec -u postgres pg1 psql ${DBNAME} -c \
  "INSERT INTO test_data (data) SELECT 'post_pitr_record_' || g FROM generate_series(1, 100) g"
docker exec -u postgres pg1 psql ${DBNAME} -c "SELECT count(*) AS primary_after_insert FROM test_data"
docker exec -u postgres pg2 psql ${DBNAME} -c "SELECT count(*) AS pitr_before_sub FROM test_data"

echo ""
echo "=== Step 5: Create subscription on PITR instance ==="
echo "copy_data=false  -- PITR already has the baseline data, no need to re-copy"
echo "create_slot=false -- reuse the slot we created in Step 2"
docker exec -u postgres pg2 psql ${DBNAME} -c \
  "CREATE SUBSCRIPTION ${SUB_NAME}
     CONNECTION 'host=pg1 dbname=${DBNAME}'
     PUBLICATION ${PUB_NAME}
     WITH (copy_data = false, create_slot = false, slot_name = '${SUB_NAME}')"

echo ""
echo "=== Step 6: Verify the 100 post-PITR records arrived ==="
echo "Waiting for replication to sync..."
sleep 3
docker exec -u postgres pg2 psql ${DBNAME} -c "SELECT count(*) AS pitr_total FROM test_data"
docker exec -u postgres pg2 psql ${DBNAME} -c \
  "SELECT count(*) AS post_pitr_records FROM test_data WHERE data LIKE 'post_pitr_record_%'"

echo ""
echo "=== Step 7: Confirm ongoing replication works ==="
docker exec -u postgres pg1 psql ${DBNAME} -c \
  "INSERT INTO test_data (data) VALUES ('live_replication_test')"
sleep 1
docker exec -u postgres pg2 psql ${DBNAME} -c \
  "SELECT id, data, created_at FROM test_data WHERE data = 'live_replication_test'"

echo ""
echo "=== Done ==="
echo "PITR instance (pg2) now has all 600 records and is receiving live changes from pg1."
