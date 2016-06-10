#!/bin/bash

VER=${1}
# set -x
if [[ ${VER} -eq 6 ]]
then
  psql -c "select * from _edb_replicator_pub.xdb_pub_database" # for XDB 6.0
else
  psql -c "select * from _edb_replicator_pub.erep_pub_database" xdb_ctl # for XDB 5.1
fi
