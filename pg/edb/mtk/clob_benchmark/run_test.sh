#!/bin/bash

echo "tests starting at `date`"
increment=500000
for rs in 1000 2000 4000 8000 16000
do
  echo "row size $rs starting at `date`"
  docker exec -t ora_host bash --login -c "sqlplus -S system/oracle < /docker/deleterows.sql"
  for nr in `seq 500000 ${increment} 5000000`
  do
    echo "inner loop $nr/$rs starting at `date`"
    docker exec -it pg_host  psql -c "drop schema hr cascade"
    echo "incrementing $increment for row size $rs at `date`"
    docker exec -t  ora_host bash --login -c "/docker/add_data.sh ${increment} ${rs}"
    docker exec -it -u enterprisedb pg_host bash --login -c "/usr/edb/migrationtoolkit/bin/runMTK.sh -copyViaDBLinkOra -tables FOOLOB -replaceNullChar x -verbose on HR"
    docker exec -it pg_host psql -c "select count(*) from hr.foolob"
    echo "inner loop $nr/$rs finished at `date`"
  done
  echo "row size ${rs} finished at `date`"
done
echo "completely done at `date`"
