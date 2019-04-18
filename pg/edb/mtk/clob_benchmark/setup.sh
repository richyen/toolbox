#!/bin/bash

# SETUP INSTRUCTIONS
# 1. docker-compoase up -d
# 3. stop edb-as-11 in pg_host container
# 4. log into pg_host container as enterprisedb and start manually with pg_ctl (so it picks up the ORACLE environment variables)
# 5. run ora_setup.sql to create tables

#docker-compose down
#docker-compose up -d

docker exec -u enterprisedb -t pg_host bash --login -c "pg_ctl -D /var/lib/edb/as11/data -mf stop"
docker exec -u enterprisedb -t pg_host bash --login -c "pg_ctl -D /var/lib/edb/as11/data -l /tmp/logfile start"

while [[ `docker ps -a | grep ora_host | grep -c healthy` -ne 1 ]]
do
  echo "waiting for ora_host to come up"
  sleep 1
done

docker exec -t ora_host bash --login -c "sqlplus -S sys/Oradoc_db1 as sysdba < /docker/ora_setup.sql"
