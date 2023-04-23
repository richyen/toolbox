CREATE EXTENSION postgres_fdw;

CREATE SERVER foreign_server
       FOREIGN DATA WRAPPER postgres_fdw
       OPTIONS (
         host 'pg1',
         port '5432',
         dbname 'postgres'
       );

CREATE USER MAPPING
       FOR postgres
       SERVER foreign_server
       OPTIONS (
         user 'postgres',
         password 'password'
       );

CREATE FOREIGN TABLE foreign_table (
         aid integer NOT NULL,
         bid integer,
         abalance integer,
         filler text
       )
       SERVER foreign_server
       OPTIONS (
         schema_name 'public',
         table_name 'pgbench_accounts'
       );

SELECT * FROM foreign_table LIMIT 10;
