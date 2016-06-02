#!/bin/bash

set -x
# psql -c "select * from _edb_replicator_pub.erep_pub_database" xdb_ctl # for XDB 5.1
psql -c "select * from _edb_replicator_pub.xdb_pub_database" # for XDB 6.0
