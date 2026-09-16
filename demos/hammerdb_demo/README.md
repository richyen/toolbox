# HammerDB TPROC-C Demo

Simple quickstart showing how to stand up [HammerDB](https://www.hammerdb.com/)
against PostgreSQL, build the TPROC-C (TPC-C-like) schema, and run a short
benchmark — demonstrating the build process and CLI commands involved.

Runs on two containers:
- `pg` — `postgres:18`, the benchmark target
- `hammerdb` — `ubuntu:22.04` with HammerDB downloaded/installed via `Dockerfile`

### Setup
1. Start both containers with `docker compose up -d --build`
1. Open a shell on the client: `docker compose exec hammerdb bash`
1. From `/opt/hammerdb`, confirm HammerDB is installed: `./hammerdbcli` (type `quit` to exit)

### Build the TPROC-C schema
1. From `/opt/hammerdb`, run the build auto-script:
   ```
   ./hammerdbcli auto demo-scripts/build.tcl
   ```
1. This connects to `pg` as the `postgres` superuser, creates the `tpcc`
   database/user, and loads 5 warehouses of TPC-C data using 4 virtual users
1. Verify the schema landed by connecting with `psql`:
   ```
   PGPASSWORD=tpcc psql -h pg -U tpcc -d tpcc -c '\dt'
   ```

### Run the TPROC-C workload
1. Still from `/opt/hammerdb`, run the driver auto-script:
   ```
   ./hammerdbcli auto demo-scripts/run.tcl
   ```
1. This creates 4 virtual users, runs a 1-minute rampup + 2-minute timed
   TPROC-C test, and prints transactions-per-minute (TPM) results to the log
1. Explain each `diset`/`dbset` line in `demo-scripts/*.tcl` as talking points:
   - `dbset db pg` / `dbset bm TPC-C` — select the DB driver and benchmark
   - `diset connection ...` — how HammerDB finds the target Postgres instance
   - `diset tpcc pg_count_ware` — schema scale (warehouses)
   - `vuset vu` / `vucreate` / `vurun` — virtual user (client) concurrency

### Optional: interactive GUI-style walkthrough
HammerDB's CLI (`hammerdbcli`) mirrors the GUI wizard 1:1 — the same
`dbset`/`diset` options shown above are what the GUI's "Options" dialogs set
under the hood, useful if walking through the GUI in a separate session.

### Cleanup
`docker compose down -v`
