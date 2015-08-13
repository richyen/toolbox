#!/bin/bash

if [[ $1 == "w" ]]
then
  psql -h ${MDN_IP} -c "update pgbench_accounts set filler = md5(now()::text) where aid = 1" edb
else
  for i in ${OTHER_MASTER_IPS}; do psql -h ${i} -c "select * from pgbench_accounts where aid = 1" edb; done
fi
