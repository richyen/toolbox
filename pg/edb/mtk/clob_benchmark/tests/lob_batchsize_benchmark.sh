#!/bin/bash

echo "tests starting at `date`"
  for lbs in `seq 1 20`
  do
    echo "inner loop $lbs starting at `date`"
    docker exec -it pg_host  psql -c "drop schema hr cascade"
    docker exec -it -u enterprisedb pg_host bash --login -c "/usr/edb/migrationtoolkit/bin/runMTK.sh -copyViaDBLinkOra -tables FOOLOB -replaceNullChar x -lobBatchSize ${lbs}000 -verbose on HR"
    docker exec -it pg_host psql -c "select count(*) from hr.foolob"
    echo "inner loop $lbs finished at `date`"
  done
echo "completely done at `date`"
