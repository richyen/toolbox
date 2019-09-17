#!/bin/bash

PGVERNUM=10
USE_EDB=0

yum -y install epel-release
if [[ ${USE_EDB} -eq 1 ]]
then
  yum -y --enablerepo=enterprisedb-tools --enablerepo=enterprisedb-dependencies --enablerepo=edbas${PGVERNUM} install edb-as${PGVERNUM}-postgis-core.x86_64
  if [[ `cat /etc/*release* | grep "^cpe" | cut -f5 -d ':'` -eq 7 ]]
    systemctl start edb-as-${PGVERNUM}
  fi
else
  yum -y install postgresql${PGVERNUM}-contrib.x86_64 postgis24_${PGVERNUM}
  if [[ `cat /etc/*release* | grep "^cpe" | cut -f5 -d ':'` -eq 7 ]]
    systemctl start postgresql-${PGVERNUM}
  fi
fi


psql -c "CREATE EXTENSION postgis" template1
psql -c "CREATE EXTENSION postgis_topology" template1
psql -c "CREATE EXTENSION fuzzystrmatch" template1
psql -c "CREATE EXTENSION postgis_tiger_geocoder" template1

createdb postgis_test

psql -c "select PostGIS_full_version()" postgis_test
