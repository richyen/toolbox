#!/bin/bash

docker-compose down
docker-compose up -d
docker exec -t pg1 /docker/install_repmgr.sh &
docker exec -t pg2 /docker/install_repmgr.sh
