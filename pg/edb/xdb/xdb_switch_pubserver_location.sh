#!/bin/bash

# Step 0 -- Set up replication cluster
# ./xdb_mmr_demo.sh 6

echo Step 1 -- Verify replication is working
docker exec -it xdb6-1 psql -c "select filler from pgbench_accounts where aid = 10"
docker exec -it xdb6-2 psql -c "update pgbench_accounts set filler = 'Change #1' where aid = 10"
sleep 5
docker exec -it xdb6-1 psql -c "select filler from pgbench_accounts where aid = 10"

echo Step 2 -- Stop pubserver
docker exec -it xdb6-1 /etc/init.d/edb-xdbpubserver stop

echo Step 3 -- Verify replication is interrupted
docker exec -it xdb6-2 psql -c "update pgbench_accounts set filler = 'Change #2' where aid = 10"
sleep 5
docker exec -it xdb6-1 psql -c "select filler from pgbench_accounts where aid = 10"

echo Step 4 -- Set up new host for running pubserver, and start pubserver
docker exec -it xdb6-2 sh -c "echo host=\$( hostname -i ) > /etc/edb-repl.conf"
docker exec -it xdb6-2 sh -c "echo user=enterprisedb >> /etc/edb-repl.conf"
docker exec -it xdb6-2 sh -c "echo port=5432 >> /etc/edb-repl.conf"
docker exec -it xdb6-2 sh -c "echo password=Cz0Ccyegvs8\\= >> /etc/edb-repl.conf"
docker exec -it xdb6-2 sh -c "echo type=enterprisedb >> /etc/edb-repl.conf"
docker exec -it xdb6-2 sh -c "echo database=edb >> /etc/edb-repl.conf"
docker exec -it xdb6-2 sh -c "echo admin_password=Cz0Ccyegvs8\\= >> /etc/edb-repl.conf"
docker exec -it xdb6-2 sh -c "echo admin_user=enterprisedb >> /etc/edb-repl.conf"

docker exec -it xdb6-2 /etc/init.d/edb-xdbpubserver start

echo Step 5 -- Verify replication has resumed
sleep 10
docker exec -it xdb6-1 psql -c "select filler from pgbench_accounts where aid = 10"

echo Step 6 -- Verify replication is working
docker exec -it xdb6-2 psql -c "update pgbench_accounts set filler = 'Change #3' where aid = 10"
sleep 10
docker exec -it xdb6-1 psql -c "select filler from pgbench_accounts where aid = 10"

echo Step 7 -- Switch back
docker exec -it xdb6-2 /etc/init.d/edb-xdbpubserver stop
docker exec -it xdb6-1 /etc/init.d/edb-xdbpubserver start

echo Step 8 -- Verify replication still works
sleep 10
docker exec -it xdb6-1 psql -c "select filler from pgbench_accounts where aid = 10"
docker exec -it xdb6-2 psql -c "update pgbench_accounts set filler = 'Change #4' where aid = 10"
sleep 10
docker exec -it xdb6-1 psql -c "select filler from pgbench_accounts where aid = 10"
