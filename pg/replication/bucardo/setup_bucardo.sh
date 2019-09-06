#!/bin/bash

set -e

B1=10.111.220.11
B2=10.111.220.12

# Build and install bucardo
yum -y install epel-release
yum -y install bucardo_10

# Initialize databases
pgbench -h ${B1} -i
pgbench -h ${B2} -i

# Start up bucardo
bucardo install --batch -d postgres -U postgres -P abc123 -h ${B1} -p 5432
bucardo add database bucardo1 dbname=postgres port=5432 host=${B1} user=postgres
bucardo add database bucardo2 dbname=postgres port=5432 host=${B2} user=postgres
bucardo add all tables db=bucardo1 -T pgbench_history --herd=alpha
bucardo add all tables db=bucardo1 -t pgbench_history --herd=beta
bucardo add sync sync1 relgroup=alpha db=bucardo1:source,bucardo2:target
bucardo add sync sync2 relgroup=beta  db=bucardo1:source,bucardo2:fullcopy
bucardo start

# Test
echo "Values should match"
psql -h ${B1} -Aatc "select count(*) from pgbench_accounts where filler = 'test'"
psql -h ${B2} -Atc "select count(*) from pgbench_accounts where filler = 'test'"
psql -h ${B1} -Aatc "SELECT count(*) FROM pgbench_history"
psql -h ${B2} -Atc "SELECT count(*) FROM pgbench_history"

psql -h ${B1} -Atc "UPDATE pgbench_accounts set filler = 'test' where aid = 1"

echo "Values should NOT match"
psql -h ${B1} -Aatc "select count(*) from pgbench_accounts where filler = 'test'"
psql -h ${B2} -Atc "select count(*) from pgbench_accounts where filler = 'test'"

pgbench -h ${B1} -T 10

echo "Values should NOT match"
psql -h ${B1} -Aatc "SELECT count(*) FROM pgbench_history"
psql -h ${B2} -Atc "SELECT count(*) FROM pgbench_history"

bucardo kick sync2

echo "Values should match"
psql -h ${B1} -Aatc "select count(*) from pgbench_accounts where filler = 'test'"
psql -h ${B2} -Atc "select count(*) from pgbench_accounts where filler = 'test'"
sleep 5
psql -h ${B1} -Aatc "SELECT count(*) FROM pgbench_history"
psql -h ${B2} -Atc "SELECT count(*) FROM pgbench_history"
