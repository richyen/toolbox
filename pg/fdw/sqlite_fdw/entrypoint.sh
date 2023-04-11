#!/bin/bash

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install centos-release-scl-rh
yum -y install postgresql13-devel centos-release-scl-rh llvm-devel vim git sqlite-devel
yum -y groupinstall development
yum -y install postgresql${PGMAJOR}-contrib
su - postgres -c "pg_ctl -D /var/lib/pgsql/${PGMAJOR}/data start"
git clone https://github.com/pgspider/sqlite_fdw.git
cd sqlite_fdw && make USE_PGXS=1 && make USE_PGXS=1 install
sqlite3 /tmp/sqlite_fdw.db "CREATE TABLE person (id int, name text, dob text)"
sqlite3 /tmp/sqlite_fdw.db "INSERT INTO person VALUES (1, 'John Doe', '2020-01-01')"
psql -c "create extension sqlite_fdw" postgres postgres
psql -c "CREATE SERVER sqlite_server FOREIGN DATA WRAPPER sqlite_fdw options (database '/tmp/sqlite_fdw.db');" postgres postgres
psql -c "GRANT USAGE ON FOREIGN SERVER sqlite_server TO postgres" postgres postgres
psql -c "CREATE FOREIGN TABLE fdw_test (id int, name text, dob text) SERVER sqlite_server OPTIONS (table 'person')" postgres postgres
psql -c "select * from fdw_test;"

# Keep things running
tail -f /dev/null
