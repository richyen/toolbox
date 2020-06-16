#!/bin/bash

PGDATA=/var/lib/db
PGPORT=5555
REPPORT=7654
DBNAME=test_db

# Verify they figured out how to fix $PGDATA permissions
[[ $( ls -l /var/lib | grep -v dbus | grep db | awk '{ print $1 }' ) =~ 'drwx------' ]] && echo "PGDATA fix -- PASS"

# Verify they figured out how to fix WAL dir permissions
[[ $( ls -l /db | grep wal | awk '{ print $1 }' ) =~ 'drwx------' ]] && echo "WAL fix -- PASS"

# Verify they figured out how to start up the database
[[ $( psql -p${PGPORT} -Atc 'select 1' ) -eq 1 ]] && echo "DB Access -- PASS"

# Verify they dumped the database
[[ $( wc -l /tmp/databases.dump | awk '{ print $1 }' ) == '173572' ]] && echo "DB Backup -- PASS"

# Verify they created the two temp tables
[[ $( psql -p${PGPORT} -Atc "SELECT count(*) FROM public.customers_without_orders" ${DBNAME} ) -eq 11004 ]] && echo "Temp table 1 created -- PASS"
[[ $( psql -p${PGPORT} -Atc "SELECT count(*) FROM public.incorrect_orders" ${DBNAME} ) -eq 15 ]] && echo "Temp table 2 created -- PASS"

# Verify they fixed the orders.totalmount column
[[ $( psql -p${PGPORT} -Atc "SELECT count(*) FROM myshop.orders WHERE (netamount + tax) <> totalamount" ${DBNAME} ) -eq 0 ]] && echo "Orders table fixed -- PASS"

# Verify they changed app_user password
[[ $( psql -p${PGPORT} -Atc "SELECT rolpassword FROM pg_authid WHERE rolname = 'app_user'" ${DBNAME} ) == 'md5bdd0ff02831aabc7c42a5e4e14f4fa9b' ]] && echo "User password change -- PASS"

# Verify that the app_user permissions are restored
[[ $( psql -p${PGPORT} -Atc "select count(*) from pg_class where relacl::text ilike '%app_user%';" ${DBNAME} ) -gt 10 ]] && echo "Restored permissions to app_user -- PASS"

# Verify they created a replication user
[[ $( psql -p${PGPORT} -Atc "SELECT count(*) FROM pg_roles WHERE rolreplication and not rolsuper" ${DBNAME} ) -ge 1 ]] && echo "Replication user created -- PASS"

# Verify they set up replication on port ${REPPORT}
[[ $( psql -p${REPPORT} -Atc "SELECT pg_is_in_recovery()" ) == 't' ]] && echo "Replication cluster created -- PASS"

# Verify they figured out how to make query faster with a vacuum and analyze
[[ $( psql -p${PGPORT} -Atc "SELECT count(*) FROM pg_stat_user_tables WHERE last_analyze NOTNULL AND last_vacuum NOTNULL" ${DBNAME} ) -gt 0 ]] && echo "Tables vacuumed and analyzed -- PASS"

# Verify they figured out how to make query faster with a vacuum and analyze
[[ $( psql -p${PGPORT} -Atc "SHOW random_page_cost" ${DBNAME} ) -lt 5000 ]] && echo "random_page_cost fixed -- PASS"

# Verify tablespace was created
[[ $( psql -p${PGPORT} -Atc "select count(*) from pg_tablespace where spcname = 'expansion_tbspc';" ) -eq 1 ]] && echo "Tablespace created -- PASS"

# Verify table was moved to new tablespace
[[ $( psql -p${PGPORT} -Atc "select t.spcname from pg_class c join pg_tablespace t on c.reltablespace=t.oid where relname = 'improvement_plan';" ${DBNAME} ) == 'expansion_tbspc' ]] && echo "Tablespace created -- PASS"
