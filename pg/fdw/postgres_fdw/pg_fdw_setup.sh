#!/bin/bash

docker exec -it pg1 pgbench -iU postgres postgres
docker exec -it pg2 yum -y install postgresql11-contrib
docker exec -it pg2 psql -c "create extension postgres_fdw" postgres postgres
docker exec -it pg2 psql -c "CREATE SERVER foreign_server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'pg1', port '5432', dbname 'postgres')" postgres postgres
docker exec -it pg2 psql -c "CREATE USER MAPPING FOR postgres SERVER foreign_server OPTIONS (user 'postgres', password 'password')" postgres postgres
docker exec -it pg2 psql -c "CREATE FOREIGN TABLE foreign_table (aid integer NOT NULL, bid integer, abalance integer, filler text) SERVER foreign_server OPTIONS (schema_name 'public', table_name 'pgbench_accounts')"
docker exec -it pg2 psql -c "SELECT * FROM foreign_table LIMIT 10"
