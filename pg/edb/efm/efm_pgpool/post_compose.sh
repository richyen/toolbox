#!/bin/bash

EFM_VER=3.2
MASTER_IP=172.22.77.50
SLAVE1_IP=172.22.77.51
SLAVE2_IP=172.22.77.52
WITNESS_IP=172.22.77.53

# Set up replication
docker exec -it master psql -c "ALTER USER enterprisedb WITH PASSWORD 'abc123'"
docker exec -it master service edb-as-10 restart # ensure latest params are loaded

for SLAVE_CONT in slave1 slave2
do
  docker exec -it ${SLAVE_CONT} service edb-as-10 stop
  docker exec -it ${SLAVE_CONT} rm -rf /var/lib/edb/as10/data
  docker exec -it ${SLAVE_CONT} sudo -u enterprisedb /usr/edb/as10/bin/pg_basebackup -RP -p 5432 -h ${MASTER_IP} -D /var/lib/edb/as10/data
  docker exec -it ${SLAVE_CONT} bash -c "echo \"trigger_file = '/tmp/trigger'\" >> /var/lib/edb/as10/data/recovery.conf"
  docker exec -it ${SLAVE_CONT} bash -c "echo \"recovery_target_timeline = 'latest'\" >> /var/lib/edb/as10/data/recovery.conf"
  docker exec -it ${SLAVE_CONT} service edb-as-10 start
done

# Set up EFM master
docker exec -it master sed -i -e "s/bind.address=/bind.address=${MASTER_IP}:5430/" /etc/edb/efm-${EFM_VER}/efm.properties
docker exec -it master service efm-3.2 start
docker exec -it master /usr/edb/efm-3.2/bin/efm allow-node efm ${SLAVE1_IP}
docker exec -it master /usr/edb/efm-3.2/bin/efm allow-node efm ${SLAVE2_IP}

# Set up EFM witness
docker exec -it witness psql -c "ALTER USER enterprisedb WITH PASSWORD 'abc123'"
docker exec -it witness chown enterprisedb:enterprisedb /tmp/efm-scripts/follow_master.sh
docker exec -it witness sed -i -e "s/is.witness=.*/is.witness=true/" /etc/edb/efm-${EFM_VER}/efm.properties
docker exec -it witness sed -i -e "s/bind.address=/bind.address=${WITNESS_IP}:5430/" /etc/edb/efm-${EFM_VER}/efm.properties
docker exec -it witness service efm-3.2 start

# Set up EFM slaves
docker exec -it slave1 sed -i -e "s/bind.address=/bind.address=${SLAVE1_IP}:5430/" /etc/edb/efm-${EFM_VER}/efm.properties
docker exec -it slave2 sed -i -e "s/bind.address=/bind.address=${SLAVE2_IP}:5430/" /etc/edb/efm-${EFM_VER}/efm.properties
docker exec -it slave1 service efm-3.2 start
docker exec -it slave2 service efm-3.2 start

# Set up pgpool
docker exec -it witness service edb-pgpool-3.6 start

docker exec -it master /usr/edb/efm-3.2/bin/efm cluster-status efm
docker exec -it witness /usr/edb/as10/bin/psql -p9999 -c "show pool_nodes"
