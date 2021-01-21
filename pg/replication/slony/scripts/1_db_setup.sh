#!/bin/bash

. /docker/environment

createdb -O $PGBENCHUSER -h $NODE1HOST $NODE1DBNAME
createdb -O $PGBENCHUSER -h $NODE2HOST $NODE2DBNAME
createdb -O $PGBENCHUSER -h $NODE3HOST $NODE3DBNAME
pgbench -i -s 1 -U $PGBENCHUSER -h $NODE1HOST $NODE1DBNAME
psql -U $PGBENCHUSER -h $NODE1HOST -d $NODE1DBNAME -c "begin; alter table pgbench_history add column id serial; update pgbench_history set id = nextval('pgbench_history_id_seq'); alter table pgbench_history add primary key(id); commit;"

psql -h $NODE1HOST -c "CREATE LANGUAGE plpgsql" $NODE1DBNAME

pg_dump -s -U $REPLICATIONUSER -h $NODE1HOST $NODE1DBNAME | psql -U $REPLICATIONUSER -h $NODE2HOST $NODE2DBNAME
pg_dump -s -U $REPLICATIONUSER -h $NODE1HOST $NODE1DBNAME | psql -U $REPLICATIONUSER -h $NODE3HOST $NODE3DBNAME

pgbench -s 1 -c 5 -t 1000 -U $PGBENCHUSER -h $NODE1HOST $NODE1DBNAME &
