#!/bin/bash

# Sample script to set up pgbouncer with bouncer_hba

docker rm -f mydb mybouncer
docker run --privileged=true --publish-all=true --interactive=false --tty=true -v /Users/${USER}/Desktop:/Desktop --hostname=mydb --detach=true --name=mydb epas96
sleep 10
docker exec -it mydb psql -c "alter user enterprisedb with password 'abc123'"
docker exec -it mydb sed -i "s/trust/md5/g" /var/lib/edb/as9.6/data/pg_hba.conf
docker exec -it mydb sed -i "s/^#log_filename.*'/log_filename = 'enterprisedb-%Y-%m-%d.log'/" /var/lib/edb/as9.6/data/postgresql.conf
docker exec -it mydb psql -c "select pg_reload_conf()"
docker run --privileged=true --publish-all=true --interactive=false --tty=true -v /Users/${USER}/Desktop:/Desktop --hostname=mybouncer --detach=true --name=mybouncer postgres-9.6
RAW_IP=`docker inspect mydb | grep '"IPAddress"' | head -n 1 | cut -f4 -d'"'`
IP=`echo -n ${RAW_IP}`
docker exec -it mybouncer /Desktop/pgbouncer_setup.sh ${IP}
