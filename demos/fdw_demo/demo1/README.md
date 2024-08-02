Basic `postgres_fdw` demo, using `pgbench`

Runs on two Rocky Linux 9 containers

### Basic demo of setup
1. Start both containers with `docker compose up`
1. Open `bash` shell for `pg1`
1. Show that `pg1` has `pgbench` schema already installed
1. Open `bash` shell for `pg2`
1. Show that `pg2` has no tables or data
1. Explain the contents of `fdw_ddl.sql` and demonstrate creation of FDW elements by running `fdw.ddl.sql` on `pg2`

### Intermediate steps for demo
1. Perform DML on `foreign_table` with: `UPDATE foreign_table SET bid = aid`
1. Connect to `pg1` and show that `pgbench_accounts` has been updated

### Advanced steps for demo
1. Demonstrate that it is not possible to create FK on `pg2` foreign tables (i.e., run on `pg2`: `create table mytable (id serial, ft int references foreign_table(aid));`)
1. Demonstrate that it is not possible to index foreign tables on `pg2` (i.e., run on `pg_2`: `create index myindex on foreign_table(aid);`)
1. Run `EXPLAIN (VERBOSE, ANALYZE) SELECT * FROM foreign_table WHERE bid = 1` on `pg2`
1. Point out timing of pushed-down query
1. RUN `CREATE INDEX foo ON pgbench_accounts (bid)` on `pg1`
1. Run `EXPLAIN (VERBOSE, ANALYZE) SELECT * FROM foreign_table WHERE bid = 1` on `pg2`
1. Point out timing of pushed-down query
