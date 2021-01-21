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
   node 1 admin conninfo = 'dbname=$NODE1DBNAME host=$NODE1HOST user=$REPLICATIONUSER';
   node 2 admin conninfo = 'dbname=$NODE2DBNAME host=$NODE2HOST user=$REPLICATIONUSER';
   node 3 admin conninfo = 'dbname=$NODE3DBNAME host=$NODE3HOST user=$REPLICATIONUSER';

   # ----
   # Node 2,3 subscribe set 1
   # ----
   subscribe set ( id = 1, provider = 1, receiver = 2, forward = no);
   subscribe set ( id = 1, provider = 1, receiver = 3, forward = no);
_EOF_
