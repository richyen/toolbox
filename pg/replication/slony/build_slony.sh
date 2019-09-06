#!/bin/bash

docker exec -it slony1 systemctl start edb-as-10
docker exec -it slony1 /docker/0_slony_install.sh
docker exec -it slony1 /docker/1_slony_setup.sh
docker exec -it slony1 /docker/2_slonik_setup.sh
docker exec -it slony1 /docker/3_slon_setup.sh
docker exec -it slony1 /docker/4_subscribe.sh
