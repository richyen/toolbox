#!/bin/bash

# Install -contrib on db2
if [[ ${HOSTNAME} == 'pg' ]]; then
  yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  yum -y install centos-release-scl-rh
  yum -y install postgresql13-devel centos-release-scl-rh llvm-devel vim git mariadb-devel
  yum -y groupinstall development
  yum -y install postgresql${PGMAJOR}-contrib
  su - postgres -c "pg_ctl -D /var/lib/pgsql/${PGMAJOR}/data start"
  git clone https://github.com/enterprisedb/mysql_fdw.git
  cd mysql_fdw && make USE_PGXS=1 && make USE_PGXS=1 install
  psql -c "create extension mysql_fdw" postgres postgres
  psql -c "CREATE SERVER mysql_server FOREIGN DATA WRAPPER mysql_fdw options (host 'mysql');" postgres postgres
  psql -c "CREATE USER MAPPING FOR postgres SERVER mysql_server OPTIONS (username 'root', password 'example');" postgres postgres
  psql -c "CREATE FOREIGN TABLE fdw_test (time_zone_id int, use_leap_seconds boolean) server mysql_server options (dbname 'mysql', table_name 'time_zone');" postgres postgres
  psql -c "select * from fdw_test;"
fi

# Keep things running
tail -f /dev/null
