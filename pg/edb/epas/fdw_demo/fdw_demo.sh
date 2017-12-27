#!/bin/bash

# Clean up
docker rm -f oracle pgsql

# Create Oracle container
docker run --privileged=true --publish-all=true --interactive=false --tty=true -v ${PWD}:/fdw_demo --hostname=oracle --detach=true --name=oracle wnameless/oracle-xe-11g:latest

# Create tables on the Oracle side
docker exec -t oracle bash --login -c "echo 'export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe' >> /etc/profile"
docker exec -t oracle bash --login -c "echo 'export PATH=\$ORACLE_HOME/bin:\$PATH' >> /etc/profile"
docker exec -t oracle bash --login -c "echo 'export ORACLE_SID=XE' >> /etc/profile"
sh fdw_demo_generate_data.sh > fdw_demo_data.sql
docker exec -t oracle bash --login -c "sqlplus -S system/oracle < /fdw_demo/fdw_demo_ora_schema.sql"
docker exec -t oracle bash --login -c "sqlplus -S system/oracle < /fdw_demo/fdw_demo_data.sql"
rm -f fdw_demo_data.sql

# Create PG container
docker rm -f pgsql
docker run --privileged=true --publish-all=true --interactive=false --tty=true -v ${PWD}:/fdw_demo --hostname=pgsql  --detach=true --name=pgsql ppas95:latest
docker exec -t pgsql yum -y install unzip git libaio
docker exec -t pgsql yum -y groupinstall "Development Tools"

# Install Oracle Instant Client and SDK
### This is a manual step if instantclient-basic-linux.x64-11.2.0.4.0.zip is not already downloaded
### Get Instant Client from http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html
# unzip /fdw_demo/instantclient-basic-linux.x64-11.2.0.4.0.zip
# unzip /fdw_demo/instantclient-sdk-linux.x64-11.2.0.4.0.zip
docker exec -t pgsql mkdir -p /u01/app/oracle/product/11.2.0/xe/lib
docker exec -t pgsql bash --login -c "cp /fdw_demo/instantclient_11_2/lib* /u01/app/oracle/product/11.2.0/xe/lib"
docker exec -t pgsql mkdir -p mkdir -p /u01/app/oracle/product/11.2.0/xe/rdbms/public
docker exec -t pgsql bash --login -c "cp /fdw_demo/instantclient_11_2/sdk/include/*.h /u01/app/oracle/product/11.2.0/xe/rdbms/public"
docker exec -t pgsql bash --login -c "echo 'export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe' >> /etc/bashrc"
docker exec -t pgsql bash --login -c "echo 'export PATH=\$ORACLE_HOME/bin:\$PATH' >> /etc/bashrc"
docker exec -t pgsql bash --login -c "echo 'export ORACLE_SID=XE' >> /etc/bashrc"

# XXX Yes, this is very ugly...
docker exec -t pgsql ln -s /u01/app/oracle/product/11.2.0/xe/lib/libclntsh.so.11.1 /u01/app/oracle/product/11.2.0/xe/lib/libclntsh.so
docker exec -t pgsql ln -s /u01/app/oracle/product/11.2.0/xe/lib/libclntsh.so.11.1 /lib64
docker exec -t pgsql ln -s /u01/app/oracle/product/11.2.0/xe/lib/libclntsh.so /lib64
docker exec -t pgsql ln -s /u01/app/oracle/product/11.2.0/xe/lib/libnnz11.so /lib64

# Create FDWs and test
ORA_IP=`docker exec -it oracle ifconfig | grep Bcast | awk '{ print $2 }' | cut -f2 -d':' | xargs echo -n`
sed -i "s/whatismyip/$ORA_IP/" fdw_tests.sql
docker exec -t pgsql git clone https://github.com/laurenz/oracle_fdw.git

# TODO: These commands below don't really work--should be done manually from a Bash prompt
docker exec -t pgsql make -C /oracle_fdw
docker exec -t pgsql make -C /oracle_fdw install
docker exec -t pgsql bash --login -c "psql < /fdw_demo/fdw_tests.sql"
