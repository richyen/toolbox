# OSDL-DBT demos

These Compose projects put an OSDL DBT kit client beside an isolated
PostgreSQL 18 target. Each kit is a separate benchmark project with its own
tools and setup requirements; this shared client image builds the selected
kit from its upstream CMake source. The kits are command-line tools, not the
unrelated dbt data-transformation product.

| Directory | Workload | Additional input |
| --- | --- | --- |
| `dbt2/` | TPC-C-like OLTP; separate RTE and database-client roles | None |
| `dbt3/` | TPC-H-like DSS / analytics | TPC-H Tools, downloaded separately |
| `dbt5/` | TPC-E brokerage-house OLTP | TPC-E EGen toolkit, obtained separately |
| `dbt7/` | TPC-DS DSS / analytics | TPC-DS tools, obtained separately |

## Start a demo

From the selected directory, for example `dbt2`:

```sh
docker compose up -d --build
docker compose exec dbt bash
```

The target is reachable from the client as `pg:5432`, with the database, user,
and password shown in that directory's Compose file. The default host port is
5433 to avoid conflicts with a local PostgreSQL server; set `PGPORT` when
starting Compose to choose another host port. The
client and target containers are kept running so you can configure and invoke
the kit interactively. Results are written to the selected directory's
`results/` folder. Stop and remove the target and its data with:

```sh
docker compose down -v
```

## Kit-specific setup

- **dbt2:** build the schema with `dbt2 build pgsql` (it uses the `PG*`
  environment variables), then run the workload against the separate `pg`
  container. `dbt2 run` does not read `PGHOST` and defaults to `localhost`, and
  `--db-host` alone makes it SSH to the database host, so pass `--dbaas`:
  `dbt2 run --dbaas --db-host=pg --db-port=5432 --db-user=postgres -d 300 pgsql /results/dbt2`.
  Use a fresh results directory for each run. Its client architecture separates
  Remote Terminal Emulators (RTEs), which emulate terminal operators, from
  database clients.
- **dbt3:** download and unpack the TPC-H Tools yourself into `dbt3/tpch-tools/`
  (mounted read-only at `/tools/tpch`). Build them for PostgreSQL with
  `dbt3-build-dbgen pgsql /tools/tpch`, then run
  `dbt3-run --tpchtools=/tools/tpch pgsql /results/dbt3`. The documented
  default is scale factor 1 and includes load, power, and throughput phases.
- **dbt5:** obtain and unpack the TPC EGen toolkit into `dbt5/egen/` (mounted
  at `/tools/egen`), then build the minimum-sized database with
  `dbt5 build --tpcetools=/tools/egen pgsql` and run a short test with
  `dbt5 run -d 120 pgsql /results/dbt5`.
- **dbt7:** obtain the TPC-DS tools and place them in `dbt7/tpcds-tools/`
  (mounted read-only at `/tools/tpcds`). Set `DSHOME=/tools/tpcds`, then run
  `dbt7-run --tpcdstools="$DSHOME" psql /results/dbt7`.

Consult each upstream kit's documentation before running its workload;
connection profiles, database setup, and external-tool layouts can vary by
release. The dbt3, dbt5, and dbt7 commands above are untested here, and like
dbt2 they may default to a database on `localhost` rather than the `pg`
container, so check each tool's `--help` for host options. Some build/load
commands create or replace benchmark databases. These
examples keep that work inside disposable containers and do not connect to
databases on the host.

For meaningful measurements, set `DBT_REF` in each Compose build configuration
to a reviewed upstream commit rather than tracking `main`. Follow the
referenced benchmarking guide's methodology: choose scale relative to RAM,
warm up before measurement, measure steady state across a concurrency ladder,
repeat runs, and report the exact kit revision, scale, configuration, and
results. Use the kit's own metrics (for example, dbt2 NOTPM); these
TPC-derived tools and short demo runs do not produce official TPC results.
Observe applicable TPC fair-use policies.

Upstream projects and documentation:

- [dbt2](https://github.com/osdldbt/dbt2)
- [dbt3](https://github.com/osdldbt/dbt3)
- [dbt5](https://github.com/osdldbt/dbt5)
- [dbt7](https://github.com/osdldbt/dbt7)
