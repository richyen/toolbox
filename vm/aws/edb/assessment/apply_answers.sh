#!/bin/bash

PGPORT=5432
PGVERSION=11
PGDATA="/var/lib/pgsql/${PGVERSION}/data"
PGINSTALL="/usr/pgsql-${PGVERSION}/bin"
PATH="${PGINSTALL}:${PATH}"
DBNAME=edb

# 1. Connect to postgres@<ip_address> with the ssh key that you provided earlier
# 2. Create a user named edbstore with password "enterprisedb"
psql -p ${PGPORT} -c "CREATE USER edbstore WITH PASSWORD 'enterprisedb'"

# 3. Create a database named "edb"
psql -p ${PGPORT} -c "CREATE DATABASE ${DBNAME}"

# 4. Locate the file /tmp/edbstore.sql and load it into the edb database you just created
psql -p ${PGPORT} ${DBNAME} < /tmp/edbstore.sql

# 5. Connect to the edb database and rename the third column in the job_grd table to "highest_sal"
psql -p ${PGPORT} -c "ALTER TABLE job_grd RENAME COLUMN higest_sal TO highest_sal" ${DBNAME}

# 6. Write a query that joins the categories and products tables, then prints out the title, category name, and price of all products with price less than 20.  Store the output of this query into a table called cheap_products
psql -p ${PGPORT} -c "SELECT p.title, c.categoryname, p.price INTO cheap_products FROM products p JOIN categories c ON p.category=c.category WHERE price < 20;" ${DBNAME}

# 7. Using the inventory table, write a query that lists the product titles which have the most sales, and store the output into a table called most_sales
psql -p ${PGPORT} -c "SELECT p.title, sales INTO most_sales FROM inventory i JOIN products p ON i.prod_id=p.prod_id ORDER BY sales DESC;" ${DBNAME}

# 8. Update the products table to reflect a 10% price discount on the items with more than 400 in stock
psql -p ${PGPORT} -c "UPDATE products SET price = price * 0.9 FROM inventory i WHERE products.prod_id=i.prod_id AND quan_in_stock > 400;" ${DBNAME}

# 9. Create a table named sales with 5 columns: a unique sale ID number (called "id"), salesperson ID number (called "salesperson"), a customer name (called "customer_name"), date of sale (called "sale_date"), sale amount (called "sale_amount")
psql -p ${PGPORT} -c "CREATE TABLE sales (id INTEGER, salesperson INTEGER, customer_name TEXT, sale_date TIMESTAMP, sale_amount INTEGER);" ${DBNAME}

# 10. Use the "curl" program to download the following script and save it to /tmp/update_data.sh: https://gist.githubusercontent.com/richyen/3d4b1dca76a8216356e800456f36e410/raw/8a16e180abb2a5f9e7b52efd8e1dcbbcd6924222/update_data.sh
curl -s "https://gist.githubusercontent.com/richyen/3d4b1dca76a8216356e800456f36e410/raw/8a16e180abb2a5f9e7b52efd8e1dcbbcd6924222/update_data.sh" > /tmp/update_data.sh

# 11. Run /tmp/update_data.sh and save the timestamps to a file
sh /tmp/update_data.sh

# 12. Fix /tmp/update_data.sh so that it runs faster
## TODO: Add command

# 13. Run /tmp/update_data.sh and save the timestamps to a file
## TODO: Add command

# 14. Create a database named "pgbench"
psql -p ${PGPORT} -c "CREATE DATABASE pgbench"

# 15. Create a user named benchuser with password "bench123" and grant it the ability to connect to the pgbench database
psql -p ${PGPORT} -c "CREATE USER benchuser WITH PASSWORD 'bench123'"

# 16. Create an alias in /etc/pgbouncer/pgbouncer.ini named "bench_alias" which will connect to host 127.0.0.1, port 5432, database pgbench using user benchuser and password bench123 (HINT, you may want to use the forcedb alias as a template)
## TODO: Add command

# 17. In /etc/pgbouncer/pgbouncer.ini, set listen_addresses to *, auth_type to md5, pool_mode to transaction
## TODO: Add command

# 18. Copy /tmp/userlist.txt to /etc/pgbouncer/userlist.txt
cp /tmp/userlist.txt /etc/pgbouncer/userlist.txt

# 19. Start up pgbouncer by becoming the pgbouncer user and issuing "pgbouncer -d /etc/pgbouncer/pgbouncer.ini"
systemctl start pgbouncer

# 20. Run the following command: pgbench -i -U benchuser -p 6432 -h 127.0.0.1 pgbench_alias
pgbench -i -U benchuser -p 6432 -h 127.0.0.1 pgbench_alias

# 21. Run the following command: pgbench -t 100000  -U benchuser -C -p 6432 -h 127.0.0.1 pgbench_alias
pgbench -t 100000  -U benchuser -C -p 6432 -h 127.0.0.1 pgbench_alias

# 22. Clone the git repository at https://github.com/darold/pgbadger.git
git clone https://github.com/darold/pgbadger.git

# 23. Run ./pgbadger -f stderr /var/lib/pgsql/<your_pg_version>/data/log/*
${PWD}/pgbadger -f stderr ${PGDATA}/log/* > /tmp/pgbadger.html

# 24. Open the resulting HTML file in a browser and determine the number of sessions belonging to the "benchuser" user (look under the "Table" tab in "Sessions Per User").  Save this number to a file
