#!/usr/bin/env bash
# Convenience wrapper: run every demo script in order against the
# pgstats_demo container, redirecting psql output to stdout.
set -euo pipefail

CONTAINER="${CONTAINER:-pgstats_demo}"
PSQL=(docker exec -i "$CONTAINER" psql -U postgres -d pgstats_demo -X -v ON_ERROR_STOP=1)

for f in \
    /demo/01_meet_pg_stats.sql \
    /demo/02_mcv_skew.sql \
    /demo/03_histograms.sql \
    /demo/04_correlated_columns.sql \
    /demo/05_fix_with_extended_stats.sql ; do
    echo
    echo "================================================================"
    echo "  $f"
    echo "================================================================"
    "${PSQL[@]}" -f "$f"
done
