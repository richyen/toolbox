#!/bin/bash

VER=${1}
set -x

if [[ ${VER} -eq 6 ]]
then
  psql -c "select * from _edb_replicator_pub.xdb_pub_replog where EXTRACT (day FROM age(current_timestamp, start_time)) <= 1 order by start_time desc" # for XDB 6.0
else
  psql -c "select * from _edb_replicator_pub.erep_pub_replog where EXTRACT (day FROM age(current_timestamp, start_time)) <= 1 order by start_time desc;" xdb_ctl # for XDB 5.1
fi
