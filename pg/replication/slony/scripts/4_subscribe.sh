#!/bin/sh

. /docker/environment

slonik <<_EOF_
   # ----
   # This defines which namespace the replication system uses
   # ----
   cluster name = $CLUSTERNAME;

   # ----
   # Admin conninfo's are used by the slonik program to connect
   # to the node databases.  So these are the PQconnectdb arguments
   # that connect from the administrators workstation (where
   # slonik is executed).
   # ----
   node 1 admin conninfo = 'dbname=$MASTERDBNAME host=$MASTERHOST user=$REPLICATIONUSER';
   node 2 admin conninfo = 'dbname=$SLAVEDBNAME host=$SLAVEHOST user=$REPLICATIONUSER';

   # ----
   # Node 2 subscribes set 1
   # ----
   subscribe set ( id = 1, provider = 1, receiver = 2, forward = no);
_EOF_
