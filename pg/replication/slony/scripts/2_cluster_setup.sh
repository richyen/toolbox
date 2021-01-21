#!/bin/sh

. /docker/environment

slonik <<_EOF_
  #--
  # define the namespace the replication system uses in our example it is
  # slony_example
  #--
  cluster name = $CLUSTERNAME;

  #--
  # admin conninfo's are used by slonik to connect to the nodes one for each
  # node on each side of the cluster, the syntax is that of PQconnectdb in
  # the C-API
  # --
  node 1 admin conninfo = 'dbname=$NODE1DBNAME host=$NODE1HOST user=$REPLICATIONUSER';
  node 2 admin conninfo = 'dbname=$NODE2DBNAME host=$NODE2HOST user=$REPLICATIONUSER';
  node 3 admin conninfo = 'dbname=$NODE3DBNAME host=$NODE3HOST user=$REPLICATIONUSER';

  #--
  # init the first node.  This creates the schema
  # _$CLUSTERNAME containing all replication system specific database
  # objects.

  #--
  init cluster ( id=1, comment = 'Master Node');

  #--
  # Slony-I organizes tables into sets.  The smallest unit a node can
  # subscribe is a set.  The following commands create one set containing
  # all 4 pgbench tables.  The master or origin of the set is node 1.
  #--
  create set (id=1, origin=1, comment='All pgbench tables');
  set add table (set id=1, origin=1, id=1, fully qualified name = 'public.pgbench_accounts', comment='accounts table');
  set add table (set id=1, origin=1, id=2, fully qualified name = 'public.pgbench_branches', comment='branches table');
  set add table (set id=1, origin=1, id=3, fully qualified name = 'public.pgbench_tellers', comment='tellers table');
  set add table (set id=1, origin=1, id=4, fully qualified name = 'public.pgbench_history', comment='history table');

  #--
  # Create the second and third nodes, tell the 3 nodes how to connect to
  # each other and how they should listen for events.
  #--

  store node (id=2, comment = 'Standby node1', event node=1);
  store node (id=3, comment = 'Standby node2', event node=1);
  store path (server = 1, client = 2, conninfo='dbname=$NODE1DBNAME host=$NODE1HOST user=$REPLICATIONUSER');
  store path (server = 1, client = 3, conninfo='dbname=$NODE1DBNAME host=$NODE1HOST user=$REPLICATIONUSER');
  store path (server = 2, client = 1, conninfo='dbname=$NODE2DBNAME host=$NODE2HOST user=$REPLICATIONUSER');
  store path (server = 2, client = 3, conninfo='dbname=$NODE2DBNAME host=$NODE2HOST user=$REPLICATIONUSER');
  store path (server = 3, client = 2, conninfo='dbname=$NODE3DBNAME host=$NODE3HOST user=$REPLICATIONUSER');
  store path (server = 3, client = 1, conninfo='dbname=$NODE3DBNAME host=$NODE3HOST user=$REPLICATIONUSER');
_EOF_
