#!/bin/bash

PGMAJOR=10
EFM_VER=3.9
MASTER_IP=172.22.77.50
SLAVE1_IP=172.22.77.51
SLAVE2_IP=172.22.77.52
WITNESS_IP=172.22.77.53

# Set up replication
docker exec -it master psql -c "ALTER USER enterprisedb WITH PASSWORD 'abc123'"
docker exec -it master service edb-as-${PGMAJOR} restart # ensure latest params are loaded

for SLAVE_CONT in slave1 slave2
do
  docker exec -it ${SLAVE_CONT} service edb-as-${PGMAJOR} stop
  docker exec -it ${SLAVE_CONT} rm -rf /var/lib/edb/as${PGMAJOR}/data
  docker exec -it ${SLAVE_CONT} sudo -u enterprisedb /usr/edb/as${PGMAJOR}/bin/pg_basebackup -RP -p 5432 -h ${MASTER_IP} -D /var/lib/edb/as${PGMAJOR}/data
  docker exec -it ${SLAVE_CONT} bash -c "echo \"trigger_file = '/tmp/trigger'\" >> /var/lib/edb/as${PGMAJOR}/data/recovery.conf"
  docker exec -it ${SLAVE_CONT} bash -c "echo \"recovery_target_timeline = 'latest'\" >> /var/lib/edb/as${PGMAJOR}/data/recovery.conf"
  docker exec -it ${SLAVE_CONT} service edb-as-${PGMAJOR} start
done

# Set up EFM master
docker exec -it master sed -i -e "s/bind.address=/bind.address=${MASTER_IP}:5430/" /etc/edb/efm-${EFM_VER}/efm.properties
docker exec -it master service edb-efm-${EFM_VER} start
docker exec -it master /usr/edb/efm-${EFM_VER}/bin/efm allow-node efm ${SLAVE1_IP}
docker exec -it master /usr/edb/efm-${EFM_VER}/bin/efm allow-node efm ${SLAVE2_IP}

# Set up EFM witness
docker exec -it witness psql -c "ALTER USER enterprisedb WITH PASSWORD 'abc123'"
docker exec -it witness chown enterprisedb:enterprisedb /tmp/efm-scripts/follow_master.sh
docker exec -it witness sed -i -e "s/is.witness=.*/is.witness=true/" /etc/edb/efm-${EFM_VER}/efm.properties
docker exec -it witness sed -i -e "s/bind.address=/bind.address=${WITNESS_IP}:5430/" /etc/edb/efm-${EFM_VER}/efm.properties
docker exec -it witness service edb-efm-${EFM_VER} start

# Set up EFM slaves
docker exec -it slave1 sed -i -e "s/bind.address=/bind.address=${SLAVE1_IP}:5430/" /etc/edb/efm-${EFM_VER}/efm.properties
docker exec -it slave2 sed -i -e "s/bind.address=/bind.address=${SLAVE2_IP}:5430/" /etc/edb/efm-${EFM_VER}/efm.properties
docker exec -it slave1 service edb-efm-${EFM_VER} start
docker exec -it slave2 service edb-efm-${EFM_VER} start

# Set up pgpool
docker exec -it witness service edb-pgpool-3.6 start

docker exec -it master /usr/edb/efm-${EFM_VER}/bin/efm cluster-status efm
docker exec -it witness /usr/edb/as${PGMAJOR}/bin/psql -p9999 -c "show pool_nodes"
