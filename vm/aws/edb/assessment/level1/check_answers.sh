#!/bin/bash

PGDATA=/var/lib/pgsql/11/data
PGPORT=5432
PGUSER=postgres
DBNAME=edb

# Verify they created edbstore user
[[ $( psql -p${PGPORT} -Atc "SELECT count(*) FROM pg_roles WHERE rolname = 'edbstore'" postgres ) -ge 1 ]] && echo "edbstore user created -- PASS"

# Verify they created edb database
[[ $( psql -p${PGPORT} -Atc 'select 1' ${DBNAME} ) -eq 1 ]] && echo "edb Database Access -- PASS"

# Verify they loaded edbstore.sql
[[ $( psql -p${PGPORT} -Atc "SELECT count(*) FROM public.products" ${DBNAME} ) -eq 10000 ]] && echo "edbstore tables added -- PASS"

# Verify they fixed column mame
[[ $( psql -p${PGPORT} -Atc "SELECT count(*) FROM public.job_grd WHERE highest_sal NOTNULL" ${DBNAME} ) -eq 4 ]] && echo "highest_sal col fixed -- PASS"

# Verify they created cheap_products table
[[ $( psql -p${PGPORT} -Atc "SELECT count(*) FROM public.cheap_products WHERE price NOTNULL" ${DBNAME} ) -gt 100 ]] && echo "cheap_products table added -- PASS"

# Verify they created most_sales table
[[ $( psql -p${PGPORT} -Atc "SELECT count(*) FROM public.most_sales WHERE title NOTNULL" ${DBNAME} ) -gt 100 ]] && echo "cheap_products table added -- PASS"

# Verify prices changed
 [[ $( psql -p${PGPORT} -Atc "SELECT price=25.99 FROM public.products WHERE prod_id = 1" ${DBNAME} ) == 't' ]] && echo "cheap_products table added -- PASS"

# Verify they created sales table
[[ $( psql -p${PGPORT} -Atc "SELECT count(*) FROM public.sales" ${DBNAME} ) -gt 1 ]] && echo "edbstore tables added -- PASS"

# Verify they downloaded update_data.sh
[[ -f /tmp/update_data.sh ]] && echo "update_data.sh script added -- PASS"

# Verify update_data was run

# Verify update_data was edited correctly

# Verify they created pgbench database
[[ $( psql -p${PGPORT} -Atc 'select 1' pgbench ) -eq 1 ]] && echo "pgbench Database Access -- PASS"

# Verify they created benchuser user
[[ $( psql -p${PGPORT} -Atc "SELECT rolpassword FROM pg_authid WHERE rolname = 'benchuser'" pgbench ) == 'md5f141e18e8635983f5f719a405cf1a49d' ]] && echo "User benchuser created -- PASS"

# Verify bench_alias was created
[[ $( grep -c bench_alias /etc/pgbouncer/pgbouncer.ini ) -gt 0 ]] && echo "bench_alias created -- PASS"

# Verify that userlist.txt is correct
[[ $( md5sum /etc/pgbouncer/userlist.txt | grep -c 93487a28a1f478180cdefeaad1e95aa1 ) -gt 0 ]] && echo "userlist.txt is correct -- PASS"

# Verify that pgbouncer is running
[[ $( pgrep -c pgbouncer ) -gt 0 ]] && echo "pgbouncer is running -- PASS"

# Verify that pgbadger was downloaded
[[ $( find /tmp -name "pgbadger.html" | wc -l ) -gt 0 ]] && echo "/tmp/pgbadger.html exists -- PASS"
