#!/bin/bash

# Slony libs need to be installed on every server that is going to participate
docker exec slony1 /docker/0_slony_install.sh
docker exec slony2 /docker/0_slony_install.sh

# Start up databases
docker exec slony1 systemctl start edb-as-10
docker exec slony2 systemctl start edb-as-10

# Set up subscriptions
docker exec slony1 /docker/1_db_setup.sh
docker exec slony1 /docker/2_cluster_setup.sh
docker exec slony1 /docker/3_slon_startup.sh # This step may need to be run manually bc of TTY issues
docker exec slony1 /docker/4_subscribe.sh
