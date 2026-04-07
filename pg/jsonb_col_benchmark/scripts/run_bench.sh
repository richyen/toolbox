#!/usr/bin/env bash
# Runs inside the benchmark container. Orchestrates all SQL scripts and prints
# results in labeled sections suitable for copy-pasting into the blog post.
# Output goes to stdout (visible in docker compose logs) and, if /results is
# mounted, also to a timestamped file there.
set -euo pipefail

PSQL="psql -v ON_ERROR_STOP=1 --no-psqlrc -P pager=off"

# If /results is mounted, tee everything to a timestamped file there.
if [ -d /results ]; then
    OUTFILE="/results/benchmark_pg${PG_VERSION:-unknown}_$(date +%Y%m%d_%H%M%S).txt"
    exec > >(tee "$OUTFILE") 2>&1
    echo "(Results also saved to $OUTFILE)"
fi

# Separator helper
sep() { echo ""; echo "============================================================"; echo "$1"; echo "============================================================"; }

sep "PostgreSQL JSONB Indexing Benchmark"
$PSQL -c "SELECT version();"
echo "Run date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

sep "1. SETUP: Creating tables, loading 50k rows, building indexes"
$PSQL -f /scripts/01_setup.sql

sep "2. EXPLAIN ANALYZE: One representative plan per approach (warm cache)"
$PSQL -f /scripts/02_explain.sql

sep "3. QUERY BENCHMARK: 20 iterations, warm cache (avg/min/max ms)"
$PSQL -f /scripts/03_query_bench.sql

sep "4. STORAGE: Table and index sizes"
$PSQL -f /scripts/04_storage.sql

sep "5. INSERT BENCHMARK: 5 trials x 5,000 rows each (avg/min/max ms)"
$PSQL -f /scripts/05_insert_bench.sql

sep "Benchmark complete."
