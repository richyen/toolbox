#!/bin/bash

export CLUSTERNAME=slony_example
export MASTERDBNAME=pgbench
export SLAVEDBNAME=pgbenchslave
export MASTERHOST=127.0.0.1
export SLAVEHOST=127.0.0.1
export REPLICATIONUSER=enterprisedb
export PGBENCHUSER=enterprisedb

createdb -O $PGBENCHUSER -h $MASTERHOST $MASTERDBNAME
createdb -O $PGBENCHUSER -h $SLAVEHOST $SLAVEDBNAME
pgbench -i -s 1 -U $PGBENCHUSER -h $MASTERHOST $MASTERDBNAME
psql -U $PGBENCHUSER -h $MASTERHOST -d $MASTERDBNAME -c "begin; alter table pgbench_history add column id serial; update pgbench_history set id = nextval('pgbench_history_id_seq'); alter table pgbench_history add primary key(id); commit;"

createlang -h $MASTERHOST plpgsql $MASTERDBNAME

pg_dump -s -U $REPLICATIONUSER -h $MASTERHOST $MASTERDBNAME | psql -U $REPLICATIONUSER -h $SLAVEHOST $SLAVEDBNAME

pgbench -s 1 -c 5 -t 1000 -U $PGBENCHUSER -h $MASTERHOST $MASTERDBNAME &
