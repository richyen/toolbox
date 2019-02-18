#!/bin/bash

VER='3.3'
IMAGE_NAME="efm:${VER}"
INSTALLDIR="/usr/edb/efm-${VER}"

if [[ ${1} == 'destroy' ]]
then
	printf "\e[0;31m==== Destroying existing EFM cluster ====\n\e[0m"
  docker-compose down
  exit 0
fi

printf "\e[0;33m==== Building containers for EFM cluster ====\n\e[0m"
docker-compose up -d

# Set up master
printf "\e[0;32m>>> SETTING UP MASTER DATABASE\n\e[0m"
docker exec -it efm-master bash --login -c "${INSTALLDIR}/bin/set_as_master.sh"

printf "\e[0;32m>>> REGISTERING STANDBY1 INTO EFM\n\e[0m"
# Register standby
docker exec -t efm-master ${INSTALLDIR}/bin/efm allow-node efm 10.111.220.22
docker exec -t efm-master ${INSTALLDIR}/bin/efm allow-node efm 10.111.220.31
docker exec -t efm-master ${INSTALLDIR}/bin/efm allow-node efm 10.111.220.32

# Set up standby
printf "\e[0;32m>>> SETTING UP STREAMING REPLICATION\n\e[0m"
docker exec -t efm-standby sed -i "s/\`hostname -i\`/10.111.220.22/" ${INSTALLDIR}/bin/set_as_standby.sh
docker exec -t efm-standby bash --login -c "${INSTALLDIR}/bin/set_as_standby.sh 10.111.220.21"

printf "\e[0;32m>>> REGISTERING STANDBY2 INTO EFM\n\e[0m"
# Set up standby
printf "\e[0;32m>>> SETTING UP STREAMING REPLICATION\n\e[0m"
docker exec -t dr-master sed -i "s/\`hostname -i\`/10.111.220.31/" ${INSTALLDIR}/bin/set_as_standby.sh
docker exec -t dr-master bash --login -c "${INSTALLDIR}/bin/set_as_standby.sh 10.111.220.21"

printf "\e[0;32m>>> REGISTERING STANDBY3 INTO EFM\n\e[0m"
# Set up standby
printf "\e[0;32m>>> SETTING UP STREAMING REPLICATION\n\e[0m"
docker exec -t dr-standby sed -i "s/\`hostname -i\`/10.111.220.32/" ${INSTALLDIR}/bin/set_as_standby.sh
docker exec -t dr-standby bash --login -c "${INSTALLDIR}/bin/set_as_standby.sh 10.111.220.21"

# Verify replication is working
printf "\e[0;33m==== Verifying Streaming Replication Functionality ====\n\e[0m"
docker exec -t efm-master bash --login -c "psql -ac 'CREATE TABLE efm_test (id serial primary key, filler text)' edb enterprisedb"
sleep 5
docker exec -t efm-standby bash --login -c "psql -ac 'SELECT * FROM efm_test' edb enterprisedb"
docker exec -t dr-standby bash --login -c "psql -ac 'SELECT * FROM efm_test' edb enterprisedb"
docker exec -t efm-master bash --login -c "psql -ac 'INSERT INTO efm_test VALUES (generate_series(1,10), md5(random()::text))' edb enterprisedb"
sleep 5
docker exec -t efm-standby bash --login -c "psql -ac 'SELECT * FROM efm_test' edb enterprisedb"
docker exec -t dr-standby bash --login -c "psql -ac 'SELECT * FROM efm_test' edb enterprisedb"

# Register witness
printf "\e[0;32m>>> REGISTERING WITNESS INTO EFM\n\e[0m"
WITNESS_IP=`docker exec -it efm-witness ifconfig | grep Bcast | awk '{ print $2 }' | cut -f2 -d':' | xargs echo -n`
docker exec -t efm-master ${INSTALLDIR}/bin/efm allow-node efm ${WITNESS_IP}

# Set up witness
printf "\e[0;32m>>> STARTING UP WITNESS EFM PROCESS\n\e[0m"
docker exec -t efm-witness ${INSTALLDIR}/bin/set_as_witness.sh

# Show status
docker exec -it efm-master ${INSTALLDIR}/bin/efm cluster-status efm
