Demonstrate ability to connect to MySQL and SQLite via FDW

1. Start up cluster with `docker compose up`
1. Demonstrate that data lives in mysql but not pg
1. Connect to `pg` container and create foreign table to mysql: `psql -c "CREATE FOREIGN TABLE mysql_phone_catalog (ssn text, name text, phone_number text, address text) SERVER mysql_server OPTIONS (dbname 'mysql_demo', table_name 'phone_catalog');" postgres postgres`
1. Insert data into mysql table via Postgres `insert into mysql_phone_catalog (SELECT * FROM fake.person limit 100);`
1. Load up SQLite `call_log` with `sqlite3 /tmp/call_log.db` -- view contents
1. Create sqlite_fdw with `CREATE FOREIGN TABLE sqlite_call_log (source_number text, target_number text, duration_secs int) SERVER sqlite_server OPTIONS (table 'call_log');`
1. Attempt to search with join across both tables:

```
WITH mysql_numbers AS (
       SELECT regexp_replace(regexp_replace(phone_number,'x.*','','g'),'[^0-9]','','g') AS numbers
         FROM mysql_phone_catalog
     ),
     sqlite_numbers AS (
       SELECT regexp_replace(source_number,'[^0-9]','','g') AS source,
              regexp_replace(target_number,'[^0-9]','','g') AS dest,
              duration_secs
         FROM sqlite_call_log
     )
SELECT s.*
  FROM mysql_numbers m
  JOIN sqlite_numbers s
    ON (s.source = m.numbers or s.dest = m.numbers);
```
