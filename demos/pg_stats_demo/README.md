# pg_stats demo — Docker harness

This directory contains a fully reproducible Docker setup that
generates the tables, statistics, and query plans referenced in
[`posette_pg_stats_20min_script.md`](../posette_pg_stats_20min_script.md).

The goal is twofold:

1. Let you **verify** every number that appears on the slides
   (MCV frequencies, row estimates, the Cheyenne+WY blow-up).
2. Give you a **live psql** to fall back on if a conference
   audience asks "can you run that again?".

---

## Layout

```
pg_stats_demo/
├── docker-compose.yml
├── init/
│   ├── 01_schema.sql          -- creates the customers table
│   └── 02_data.sql            -- inserts ~1,000,000 rows
└── demo/
    ├── 01_meet_pg_stats.sql        -- slide 7
    ├── 02_mcv_skew.sql             -- slides 8-10
    ├── 03_histograms.sql           -- slides 11-13
    ├── 04_correlated_columns.sql   -- slides 14-15
    ├── 05_fix_with_extended_stats.sql -- slides 16-18
    └── run_all.sh                  -- run every demo end-to-end
```

The `init/` scripts run automatically the **first time** the
container starts (that's how the official `postgres` image works).
The `demo/` scripts are mounted read-only into the container at
`/demo/` and are meant to be run interactively.

---

## Start it

```bash
cd _talks/pg_stats_demo
docker compose up -d

# wait for healthcheck to go green (init takes ~15s)
docker compose ps
```

The host port is **5433** so it won't fight an existing local
Postgres on 5432.

## Run a demo

Drop into psql inside the container:

```bash
docker compose exec pg psql -U postgres -d pgstats_demo
```

Then run a script from inside psql:

```sql
\i /demo/01_meet_pg_stats.sql
\i /demo/02_mcv_skew.sql
\i /demo/03_histograms.sql
\i /demo/04_correlated_columns.sql
\i /demo/05_fix_with_extended_stats.sql
```

Or run everything from your host shell:

```bash
./demo/run_all.sh
```

## Tear down

```bash
docker compose down -v
```

(`-v` removes the data volume, so the next `up` re-runs the init
scripts.)

---

## What each demo shows

### 01 — Meeting `pg_stats` (slide 7)

A single `SELECT` against `pg_stats` that prints `n_distinct`,
`null_frac`, and `correlation` for all three columns. With the
default seed you should see roughly:

| attname     | n_distinct | correlation |
|-------------|-----------:|------------:|
| state       |       50   |       ~0.07 |
| city        |     ~10000 |       ~0.01 |
| signup_date |     ~1822  |        1.00 |

Notes:

- `n_distinct` for `city` looks small (~10,000) even though the
  data really contains ~20,000 distinct cities. That's because
  `n_distinct` is **estimated from a sample**; with 30,000 rows
  sampled and many cities, the estimator is conservative. Run
  `SELECT count(DISTINCT city) FROM customers` to see the true
  number.
- The slide quotes `correlation = 0.81` for `state`. This harness
  fully shuffles state values across the table so the planner
  must honestly choose between Seq Scan and Index Scan in
  demo 02; that drops state correlation to near zero. The
  narrative on the slide is unaffected.

### 02 — MCVs and skew (slides 8-10)

Prints the top 10 entries of `most_common_vals` for `state`,
then disables bitmap scans (so the planner has to choose
between a pure Seq Scan and a pure Index Scan, matching the
slides), and runs two `EXPLAIN ANALYZE`s:

- `state = 'CA'` → **Seq Scan**, rows estimate ~166,000
- `state = 'WY'` → **Index Scan**, rows estimate ~4,000

Finally it computes the estimate by hand from the MCV frequency
so the audience can connect the planner's number to the value
in `pg_stats`. The MCV frequencies you'll see are roughly:

| state | mcv_freq | estimated rows |
|-------|---------:|---------------:|
| CA    |    ~0.17 |       ~166,000 |
| TX    |    ~0.12 |       ~115,000 |
| NY    |    ~0.09 |        ~86,000 |
| ...   |          |                |
| WY    |  ~0.0041 |         ~4,000 |

### 03 — Histograms (slides 11-13)

Prints the first 8 histogram boundaries for `signup_date`,
`EXPLAIN`s a 4-month range query, then bumps the statistics
target to 1000 and `EXPLAIN`s the same query so the audience
sees the estimate sharpen (from ~67,765 to ~67,044 against an
actual of 66,978 in the test run). Finally it resets the
target.

### 04 — The correlated-columns blow-up (slides 14-15)

Manually computes the naïve independence-assumption estimate
from `pg_stats`:

```
P(state='WY')         ≈ 0.0041
P(city='Cheyenne')    ≈ 0.0038
estimate              ≈ 0.0041 * 0.0038 * 1,000,000 ≈ 15
```

Then runs `EXPLAIN ANALYZE` to show the planner producing
exactly that estimate (`rows=15`) while the actual row count is
~3,820. The slide quotes 8 and 4012; with this seeded data you
will see ~15 vs ~3,820. The **order-of-magnitude blow-up
(~250×)** is the point, and it is reproducible.

### 05 — Extended statistics (slides 16-18)

Creates a `CREATE STATISTICS ... (dependencies, ndistinct, mcv)`
object on `(city, state)`, re-`ANALYZE`s, dumps the captured
data from `pg_statistic_ext_data`, and re-runs the same plan.

The captured functional dependency looks like:

```
functional_dependencies | {"2 => 3": 0.994700}
ndistinct               | {"2, 3": 10136}
```

That `0.994700` is "if you know `city`, you know `state` 99.47%
of the time" — exactly the relationship that broke the
independence assumption. The new plan shows `rows=4100` against
an actual `rows=3822`, i.e. within 7%.

---

## Tuning the harness

All of the magic numbers live in `init/02_data.sql`:

| What                                | Where                                      |
|-------------------------------------|--------------------------------------------|
| Total row count                     | `* 1000000` in the `floor(...)` expression |
| MCV percentages                     | `w` column of `state_weights`              |
| How much Cheyenne dominates WY      | `primary_share` for the `WY` row           |
| How many cities per state           | `(random() * 400)` in the city expression  |
| Date range / `n_distinct(signup_date)` | `rn / 549` and the `DATE '2020-01-01'` base |
| Physical correlation for `state`    | the `ORDER BY` inside `expanded`           |

Tweak one knob at a time and re-run `docker compose down -v &&
docker compose up -d` to regenerate.

---

## Postgres version

The image is `postgres:17`. Extended statistics with the `mcv`
kind requires PG 12+; everything in these demos works on PG 14
or newer.
