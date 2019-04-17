#!/bin/bash

# SETUP INSTRUCTIONS
# 1. docker-compoase up -d
# 2. set ORACLE_HOME, PATH, ORACLE_SID environment variables in ora_host container
# 3. stop edb-as-11 in pg_host container
# 4. log into pg_host container as enterprisedb and start manually with pg_ctl (so it picks up the ORACLE environment variables)
# 5. run ora_setup.sql to create tables

docker exec -t ora_host bash --login -c "echo 'export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe' >> /etc/profile"
docker exec -t ora_host bash --login -c "echo 'export PATH=\$ORACLE_HOME/bin:\$PATH' >> /etc/profile"
docker exec -t ora_host bash --login -c "echo 'export ORACLE_SID=XE' >> /etc/profile"
docker exec -t ora_host bash --login -c "sqlplus -S system/oracle < /docker/ora_setup.sql"

docker exec -t pg_host bash --login -c "chown enterprisedb:enterprisedb /usr/edb/migrationtoolkit/etc/toolkit.properties"
