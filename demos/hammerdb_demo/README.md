# HammerDB PostgreSQL Demo

Simple quickstart showing how to stand up [HammerDB](https://www.hammerdb.com/)
against PostgreSQL, build a TPROC-C (TPC-C-derived) or TPROC-H (TPC-H-derived)
schema, and run a short sample workload — demonstrating the build process and
CLI commands involved. HammerDB's TPROC workloads are fair-use derivatives, not
TPC-compliant benchmarks, and their results are not comparable with published
TPC results.

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
Build the schema first; the workload connects as the `tpcc` role and expects
the `tpcc` database to exist. The script checks this connection before
starting virtual users and points to the build step if it is unavailable.

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

### Build the TPROC-H schema
The analytical sample uses its own `tpch` database and user, separate from
TPROC-C. Scale Factor (SF) 1 generates about 1 GB of raw data; building it
takes longer than the small TPROC-C example.

1. From `/opt/hammerdb`, run:
   ```
   ./hammerdbcli auto demo-scripts/build-tproch.tcl
   ```
1. The script connects as the PostgreSQL superuser, creates the `tpch`
   database/user, and builds SF 1 using one loader thread.
1. Verify the schema:
   ```
   PGPASSWORD=tpch psql -h pg -U tpch -d tpch -c '\dt'
   ```

### Run the TPROC-H workload
TPC-H-style query tests run to completion rather than for a fixed timed
interval. HammerDB's Power Test runs one query stream; its Throughput Test uses
two streams at SF 1. Each sample below runs one query set:

1. Run the single-stream Power Test:
   ```
   ./hammerdbcli auto demo-scripts/run-tproch-power.tcl
   ```
1. Then run the two-stream Throughput Test:
   ```
   ./hammerdbcli auto demo-scripts/run-tproch-throughput.tcl
   ```
1. Compare the per-query times using their geometric mean; HammerDB recommends
   this instead of calculating the official TPC-H QphH metric. For a
   conservative TPC-H-style comparison, repeat each configuration twice and
   report the slower result. These short examples are demonstrations, not
   compliant TPC-H runs. `pg_verbose true` prints query timing details for
   reviewing the run output.
1. Explain the `diset`/`dbset` lines in `demo-scripts/*tproch*.tcl`:
   - `dbset db pg` / `dbset bm TPC-H` — select the database driver and workload
   - `diset connection ...` — connect HammerDB to the PostgreSQL target
   - `diset tpch pg_scale_fact` — set the dataset scale factor
   - `vuset vu` — set the number of query streams (one per HammerDB virtual user)

### Optional: interactive GUI-style walkthrough
HammerDB's CLI (`hammerdbcli`) mirrors the GUI wizard 1:1 — the same
`dbset`/`diset` options shown above are what the GUI's "Options" dialogs set
under the hood, useful if walking through the GUI in a separate session.

### Cleanup
`docker compose down -v`
