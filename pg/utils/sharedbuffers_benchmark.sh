#!/bin/bash

set -e
psql -c 'alter system set autovacuum to off'
psql -c "alter system set maintenance_work_mem to '32GB'"

export PGDATABASE=pgbench
createdb ${PGDATABASE}
for s in 1 10 100 1000 1500 2000; do
  pgbench -i -s ${s}
  psql -c "pg_size_pretty(pg_database_size('${PGDATABASE}'))" | tee -a /fdw_demo/benchmark_output.txt

  for c in `seq 10 10 100`; do
    for i in 1 4 8 16 24 32 48 64; do
      for t in 60 300 600; do
        echo "running ${c} connections for ${t} at ${i} on size ${s}" | tee -a /fdw_demo/benchmark_output.txt
        psql -c "alter system set shared_buffers to '${i}GB'"
        su - enterprisedb -c "pg_ctl -D ${PGDATA} -mf restart"
        pgbench -n -M prepared -c${c} -j${c} -S -T${t} -P1 | tee -a /fdw_demo/benchmark_output.txt
      done
    done
  done
done
