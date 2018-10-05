#!/bin/bash

I_NAME='ppas95:latest'

PGB_NAME='pgb'
docker rm -f ${PGB_NAME}
docker run --privileged=true --publish-all=true --interactive=false --tty=true -p 6432:6432 -v `pwd | xargs echo -n`:/conf --hostname=${PGB_NAME} --detach=true --name=${PGB_NAME} ${I_NAME}

for C_NAME in pg1 pg2
do
  docker rm -f ${C_NAME}
  docker run --privileged=true --publish-all=true --interactive=false --tty=true -v `pwd | xargs echo -n`:/conf --hostname=${C_NAME} --detach=true --name=${C_NAME} ${I_NAME}
  I=`docker inspect ${C_NAME} | grep IPAddress | cut -f4 -d'"' | sort -u | grep 1 | xargs echo -n`
  docker exec ${PGB_NAME} bash -c "echo ${I} ${C_NAME} >> /etc/hosts"
  docker exec -it ${C_NAME} psql -c "ALTER USER enterprisedb with password 'abc123'"
done

docker exec -it pg1 psql -c "CREATE USER foouser with password 'abc123'"
docker exec -it pg2 psql -c "CREATE USER baruser with password 'abc123'"
docker exec ${PGB_NAME} rpm -ivh http://yum.enterprisedb.com/edbrepos/edb-repo-latest.noarch.rpm
docker exec ${PGB_NAME} sed -i "s/<username>:<password>/${YUMUSERNAME}:${YUMPASSWORD}/" /etc/yum.repos.d/edb.repo
docker exec ${PGB_NAME} yum --enablerepo=enterprisedb-tools -y install edb-pgbouncer17
docker exec ${PGB_NAME} cp /conf/edb-pgbouncer-1.7.ini /etc/sysconfig/edb/pgbouncer1.7/
docker exec ${PGB_NAME} sed -i "s/username1/foouser/" /etc/sysconfig/edb/pgbouncer1.7/userlist.txt
docker exec ${PGB_NAME} sed -i "s/username2/baruser/" /etc/sysconfig/edb/pgbouncer1.7/userlist.txt
docker exec ${PGB_NAME} sed -i "s/username3/enterprisedb/" /etc/sysconfig/edb/pgbouncer1.7/userlist.txt
docker exec ${PGB_NAME} sed -i "s/password1/md519f71067fc0d06d9255e66dcedf01481/" /etc/sysconfig/edb/pgbouncer1.7/userlist.txt
docker exec ${PGB_NAME} sed -i "s/password2/md54706b23c45e6df784dc3c13cf38fe8a7/" /etc/sysconfig/edb/pgbouncer1.7/userlist.txt
docker exec ${PGB_NAME} sed -i "s/password3/md56f64fa1993897e20128090e6b8ebe281/" /etc/sysconfig/edb/pgbouncer1.7/userlist.txt
docker exec ${PGB_NAME} /etc/init.d/edb-pgbouncer-1.7 start
