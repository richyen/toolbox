#!/bin/bash

. /docker/environment

slon $CLUSTERNAME "dbname=$NODE1DBNAME user=$REPLICATIONUSER host=$NODE1HOST" &
slon $CLUSTERNAME "dbname=$NODE2DBNAME user=$REPLICATIONUSER host=$NODE2HOST" &
slon $CLUSTERNAME "dbname=$NODE3DBNAME user=$REPLICATIONUSER host=$NODE3HOST" &
