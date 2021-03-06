#!/bin/bash

# Slony libs need to be installed on every server that is going to participate
docker exec slony1 /docker/scripts/0_slony_install.sh
docker exec slony2 /docker/scripts/0_slony_install.sh
docker exec slony3 /docker/scripts/0_slony_install.sh

# Start up databases
docker exec slony1 systemctl start postgresql-11
docker exec slony2 systemctl start postgresql-11
docker exec slony3 systemctl start postgresql-11

# Set up subscriptions
docker exec slony1 /docker/scripts/1_db_setup.sh
docker exec slony1 /docker/scripts/2_cluster_setup.sh
docker exec slony1 /docker/scripts/3_slon_startup.sh # This step may need to be run manually bc of TTY issues
docker exec slony1 /docker/scripts/4_subscribe.sh
