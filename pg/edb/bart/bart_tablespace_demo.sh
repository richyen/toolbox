#!/bin/bash

# Create containers
BARTNAME='bart'
PPASNAME='pg'
docker rm -f ${BARTNAME} ${PPASNAME}
docker run --privileged=true --publish-all=true --interactive=false --tty=true -v /Users/${USER}/Desktop:/Desktop --detach=true --name=${BARTNAME} bart:1.1
docker run --privileged=true --publish-all=true --interactive=false --tty=true -v /Users/${USER}/Desktop:/Desktop --detach=true --name=${PPASNAME} ppas95:latest

# Set up bart.cfg
IP=`docker exec -it ${PPASNAME} ifconfig eth0 | grep "inet addr" | awk '{ print $2 }' | cut -f2 -d':'`
docker exec -it ${BARTNAME} sed -i "s/host = 127.0.0.1/host = ${IP}/" /usr/edb-bart-1.1/etc/bart.cfg
docker exec -it ${BARTNAME} sed -i "s/^\[BART\]//" /usr/edb-bart-1.1/etc/bart.cfg
docker exec -it ${BARTNAME} sed -i "s/^#\[BART\].*/\[BART\]/" /usr/edb-bart-1.1/etc/bart.cfg

# Create data and tablespaces
docker exec -it ${PPASNAME} mkdir -p /tmp/pgtbspc/space1
docker exec -it ${PPASNAME} mkdir -p /tmp/pgtbspc/space2
docker exec -it ${PPASNAME} mkdir -p /tmp/pgtbspc/space3
docker exec -it ${PPASNAME} chown -R enterprisedb:enterprisedb /tmp/pgtbspc
docker exec -it ${PPASNAME} pgbench -i -s2
docker exec -it ${PPASNAME} psql -c "create user repuser replication"
docker exec -it ${PPASNAME} psql -c "create tablespace s1 location '/tmp/pgtbspc/space1'"
docker exec -it ${PPASNAME} psql -c "create tablespace s2 location '/tmp/pgtbspc/space2'"
docker exec -it ${PPASNAME} psql -c "create tablespace s3 location '/tmp/pgtbspc/space3'"
docker exec -it ${PPASNAME} psql -c "alter table pgbench_history set tablespace s1"
docker exec -it ${PPASNAME} psql -c "alter table pgbench_tellers set tablespace s2"
docker exec -it ${PPASNAME} psql -c "alter table pgbench_accounts set tablespace s3"

# Try a backup
docker exec -it ${BARTNAME} su enterprisedb -c "/usr/edb-bart-1.1/bin/bart backup -s EPAS9x -Ft"

echo "This should be zero"
docker exec -it accertify_bart ls /tmp | grep pgtbspc | wc -l
docker exec -it accertify_bart ls -R /tmp/bart_backups
docker exec -it accertify_bart rm -rf /tmp/pgtbspc

# Test backup with xlog-method = stream + format = plain
docker exec -it ${BARTNAME} sed -i "s/^#xlog-method.*defaults to fetch.*/xlog-method = stream/" /usr/edb-bart-1.1/etc/bart.cfg
docker exec -it ${BARTNAME} su enterprisedb -c "/usr/edb-bart-1.1/bin/bart backup -s EPAS9x -Fp"

echo "This should be zero"
docker exec -it accertify_bart ls /tmp | grep pgtbspc | wc -l
docker exec -it accertify_bart rm -rf /tmp/pgtbspc

