#!/bin/bash

CONTAINER_NAME=l1
OS_USER=postgres
PGPORT=5555
PGVERSION=11
PGDATA="/var/lib/db"
PGHOME="/var/lib/pgsql"
PGINSTALL="/usr/pgsql-${PGVERSION}/bin"
PATH="${PGINSTALL}:${PATH}"
REPLICA=/mnt/replica
DBNAME=test_db

# 1. The database is down.  Please start up postgres to begin the recovery effort
chmod -R 700 ${PGDATA}
chmod 700 /db/wal
/usr/pgsql-11/bin/pg_ctl -l /tmp/logfile -D ${PGDATA} start

# 2. Now that the database is up, please take a pg_dump of all databases to avoid any future problems. Please save the file in /tmp/databases.dump
pg_dumpall -gp ${PGPORT} -f /tmp/globals.dump
pg_dumpall -p ${PGPORT} -f /tmp/databases.dump

# 3. For data validation, we want to find out how many orders have been lost.  Please write a query to find out how many customers do not have orders.  Run this query and save all the customer data of these order-less customers into a table called public.customers_without_orders
psql -p ${PGPORT} -c "select c.* into public.customers_without_orders from myshop.customers c left outer join myshop.orders o on c.customerid=o.customerid where orderdate is null;" ${DBNAME}

# 4. When the database crashed, some transactions became incorrect.  Identify the rows in the orders table that do not have the correct totals, and save them into a table called public.incorrect_orders ( you do not need to look at the products table, as the orders.netamount values include discounts not reflected in the products table -- basically, assume orders.netamount and orders.tax columns are correct ).  Then, fix the totalamount column in the original orders table
psql -p ${PGPORT} -c "select * into public.incorrect_orders from myshop.orders where (netamount + tax) <> totalamount;" ${DBNAME}
psql -p ${PGPORT} -c "update myshop.orders set totalamount = (netamount + tax) WHERE (netamount + tax) <> totalamount;" ${DBNAME}

# 5. Someone messed up the permissions for the app_user.  Please restore permissions for app_user so that it can at least SELECT from all tables in the database
psql -p ${PGPORT} -c "grant usage on schema myshop to app_user" ${DBNAME}
psql -p ${PGPORT} -c "grant SELECT ON ALL TABLES IN SCHEMA myshop to app_user" ${DBNAME}

# 6. While we attempt to recover the database, let's change the password of the application user to prevent accidental login.  Please change the password for app_user to 'abcnologin'
psql -p ${PGPORT} -c "ALTER USER app_user WITH PASSWORD 'abcnologin'"

# 7. Let's set up replication, so that there's always a copy of data available, in case of erroneous queries.  Please set up streaming replication at /mnt/replica, and have it listen for read-only queries at port 7654.  Use recovery_min_apply_delay = 600000 to make the standby wait 10 minutes before replaying any changes from the primary.  Do not use the superuser as the replication user.
createuser --replication -p ${PGPORT} repuser
psql -p ${PGPORT} -c "ALTER SYSTEM SET wal_keep_segments to 100"
psql -p ${PGPORT} -c "ALTER SYSTEM SET listen_addresses to '*'"
mv ${PGDATA}/pg_hba.conf /tmp/pg_hba.conf
cp /tmp/pg_hba.conf ${PGDATA}/pg_hba.conf
chmod 700 ${PGDATA}/pg_hba.conf
echo host replication repuser 0.0.0.0/0 trust >> ${PGDATA}/pg_hba.conf
pg_ctl -D ${PGDATA} -l /tmp/logfile restart
pg_basebackup -h 127.0.0.1 -U repuser -PR -p ${PGPORT} -D ${REPLICA}
chmod 700 ${REPLICA}
echo "recovery_min_apply_delay = 600000" >> ${REPLICA}/recovery.conf
sed -i "s/${PGPORT}/7654/" ${REPLICA}/postgresql.auto.conf
pg_ctl -D ${REPLICA} -l /tmp/rep_logfile start

# 8. The customer has identified popular products and would like to send a marketing email for a new promotion.  The following query to gets firstname, lastname, email, orderid, and title for customers who have ordered popular products.  Note: popular products are rows in the products table with sales > 20.  Please improve the performance of this query.  HINT: Use EXPLAIN ANALYZE to help you.  Tell us how you solved this by creating a table called public.improvement_plan and add a row of text with your explanation.
psql -p ${PGPORT} -c "explain analyze select firstname,lastname,email, o.orderid, title from myshop.customers c join myshop.orders o on c.customerid=o.customerid join myshop.orderlines ol on ol.orderid=o.orderid join myshop.products p on ol.prod_id=p.prod_id join myshop.inventory i on i.prod_id=p.prod_id where sales > 20;" ${DBNAME}
psql -p ${PGPORT} -c "vacuum verbose analyze" ${DBNAME}
psql -p ${PGPORT} -c "explain analyze select firstname,lastname,email, o.orderid, title from myshop.customers c join myshop.orders o on c.customerid=o.customerid join myshop.orderlines ol on ol.orderid=o.orderid join myshop.products p on ol.prod_id=p.prod_id join myshop.inventory i on i.prod_id=p.prod_id where sales > 20;" ${DBNAME}
psql -p ${PGPORT} -c "SELECT 'I vacuumed and analyzed' INTO public.improvement_plan;" ${DBNAME}

# 9. The following query used to use an index scan, but not anymore: select * from myshop.orders where orderid = 100.  Please fix it so that an index scan is used.
psql -p ${PGPORT} -c "ALTER SYSTEM SET random_page_cost to DEFAULT"

# 10. To anticipate future space requirements, please create a tablespace named "expansion_tbspc" and store it at /mnt/expansion. Move public.improvement_plan to this new tablespace
psql -p ${PGPORT} -c "CREATE TABLESPACE expansion_tbspc LOCATION '/mnt/expansion';"
psql -p ${PGPORT} -c "ALTER TABLE public.improvement_plan SET TABLESPACE expansion_tbspc" ${DBNAME}
