#!/bin/bash

export CLUSTERNAME=slony_example
export MASTERDBNAME=pgbench
export SLAVEDBNAME=pgbenchslave
export MASTERHOST=127.0.0.1
export SLAVEHOST=127.0.0.1
export REPLICATIONUSER=enterprisedb
export PGBENCHUSER=enterprisedb

slon $CLUSTERNAME "dbname=$MASTERDBNAME user=$REPLICATIONUSER host=$MASTERHOST" &
slon $CLUSTERNAME "dbname=$SLAVEDBNAME user=$REPLICATIONUSER host=$SLAVEHOST" &
