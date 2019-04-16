#!/bin/bash

I_NAME='postgres-11:latest'

# Set up databases
for C_NAME in pg1 pg2
do
  docker rm -f ${C_NAME}
  docker run --privileged=true --publish-all=true --interactive=false --tty=true --hostname=${C_NAME} --detach=true --name=${C_NAME} ${I_NAME}
  docker exec -it ${C_NAME} psql -c "ALTER USER postgres with password 'abc123'"
done

docker exec -it pg1 psql -c "CREATE USER foouser with password 'abc123'"
docker exec -it pg2 psql -c "CREATE USER foouser with password 'abc123'"
docker exec -it pg1 psql -c "CREATE USER baruser with password 'bar123'"
docker exec -it pg2 psql -c "CREATE USER baruser with password 'bar890'"
docker exec -it pg1 psql -c "CREATE OR REPLACE FUNCTION user_search(uname TEXT) returns table(usename name, passwd text)as \$\$ SELECT usename, passwd FROM pg_shadow WHERE usename=\$1  \$\$ language sql SECURITY DEFINER;"
docker exec -it pg2 psql -c "CREATE OR REPLACE FUNCTION user_search(uname TEXT) returns table(usename name, passwd text)as \$\$ SELECT usename, passwd FROM pg_shadow WHERE usename=\$1  \$\$ language sql SECURITY DEFINER;"

# Set up pgbouncer
PGB_NAME='pgb'
docker rm -f ${PGB_NAME}
docker run --privileged=true --publish-all=true --interactive=false --tty=true -p 6432:6432 --link pg1:pg1 --link pg2:pg2 --hostname=${PGB_NAME} --detach=true --name=${PGB_NAME} ${I_NAME}

# install PGDG if not already installed
# docker exec ${PGB_NAME} rpm -ivh https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-6-x86_64/pgdg-redhat-repo-latest.noarch.rpm

docker exec ${PGB_NAME} yum -y install pgbouncer
docker cp pgbouncer.ini ${PGB_NAME}:/etc/pgbouncer/pgbouncer.ini
docker exec ${PGB_NAME} bash -c "echo 'foouser:md519f71067fc0d06d9255e66dcedf01481' > /etc/pgbouncer/userlist.txt"
docker exec ${PGB_NAME} /etc/init.d/pgbouncer start

sleep 5

set -x
PGPASSWORD=bar123 psql -h 127.0.0.1 -p 6432 -U baruser -Atc "SELECT 'success'" foodb
PGPASSWORD=bar123 psql -h 127.0.0.1 -p 6432 -U baruser -Atc "SELECT 'success'" bardb
PGPASSWORD=bar890 psql -h 127.0.0.1 -p 6432 -U baruser -Atc "SELECT 'success'" bardb
