#!/bin/bash

docker exec -it bucardo1 systemctl start postgresql-10
docker exec -it bucardo2 systemctl start postgresql-10
docker exec -it bucardo1 /docker/setup_bucardo.sh
