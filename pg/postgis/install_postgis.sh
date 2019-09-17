#!/bin/bash

# First, do docker-compose up -d on a centos7/postgres-10:latest image

PGVERNUM=10

yum -y install epel-release
yum -y install postgresql${PGVERNUM}-contrib.x86_64 postgis24_${PGVERNUM}

systemctl start postgresql-10

psql -c "CREATE EXTENSION postgis" template1 postgres
psql -c "CREATE EXTENSION postgis_topology" template1 postgres
psql -c "CREATE EXTENSION fuzzystrmatch" template1 postgres
psql -c "CREATE EXTENSION postgis_tiger_geocoder" template1 postgres

# createdb -U postgres postgis_test
