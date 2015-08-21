#!/bin/bash

. /Users/richyen/Code/pg/edb/ppas_and_docker/docker_functions
for i in 1 2 3 4 5 6; do docker rm -f xdb$i & done; docker rm -f xdb
for i in 1 2 3 4 5 6; do create_container xdb$i xdb5:6.6 & done; create_container xdb xdb5:6.6
sleep 10
docker ps -a | grep xdb | awk '{ print $17 }' | xargs -I% docker inspect % | grep -i ipadd | grep -v Second | cut -f4 -d'"'

