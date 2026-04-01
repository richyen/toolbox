#!/bin/bash
# ============================================================
# WAL-Shipping Demo — pgbench flow primary → relay → standby
# Usage: ./demo.sh
# ============================================================
set -eo pipefail

PRI="docker exec pg_primary psql -U postgres -d postgres"
STB="docker exec pg_standby psql -U postgres -d postgres"

sep() {
    echo
    echo "============================================================"
    printf "  %s\n" "$1"
    echo "============================================================"
}

# ── 1. Wait for primary ──────────────────────────────────────
sep "1. Waiting for primary"
until docker exec pg_primary pg_isready -U postgres -q 2>/dev/null; do
    printf "  primary not ready yet …\r"; sleep 3
done
echo "  Primary is ready."

# ── 2. Wait for standby ──────────────────────────────────────
sep "2. Waiting for standby (base backup + recovery start can take ~2 min)"
TIMEOUT=300; ELAPSED=0
until docker exec pg_standby pg_isready -U postgres -q 2>/dev/null; do
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "  ERROR: standby did not become ready within ${TIMEOUT}s."
        exit 1
    fi
    printf "  Standby not ready yet (%ds / %ds) …\r" "$ELAPSED" "$TIMEOUT"
    sleep 5; ELAPSED=$((ELAPSED + 5))
done
echo "  Standby is ready.                                     "

# ── 3. Confirm archiving + hot_standby ──────────────────────
sep "3. Archiving configuration on primary"
$PRI -x -c "
SELECT archived_count,
       last_archived_wal,
       last_archived_time,
       failed_count,
       last_failed_wal
FROM   pg_stat_archiver;"

# ── 4. Check standby recovery status ──────────────────────────
sep "4. Standby recovery status"
$STB -c "
SELECT pg_is_in_recovery()      AS in_recovery,
       pg_last_wal_replay_lsn() AS replay_lsn,
       now() - pg_last_xact_replay_timestamp()
                                AS replay_lag;"

# ── 5. Row counts before benchmark ──────────────────────────
sep "5. Row counts BEFORE pgbench run"
echo "--- Primary ---"
$PRI -c "
SELECT relname AS table, n_live_tup AS rows
FROM   pg_stat_user_tables
WHERE  schemaname = 'public'
ORDER  BY relname;"

echo "--- Standby (read-only) ---"
$STB -c "
SELECT relname AS table, n_live_tup AS rows
FROM   pg_stat_user_tables
WHERE  schemaname = 'public'
ORDER  BY relname;"

# ── 6. Run pgbench ───────────────────────────────────────────
sep "6. Running pgbench on primary  (5 clients × 90 seconds)"
docker exec pg_primary pgbench -U postgres -d postgres -c 5 -T 90 -P 10

# Force archive of the current (possibly partially-filled) WAL segment.
echo
echo "  Forcing WAL segment switch + CHECKPOINT on primary …"
$PRI -q -c "SELECT pg_switch_wal();"
$PRI -q -c "CHECKPOINT;"

# ── 7. Poll for standby to catch up ─────────────────────────
sep "7. Polling for standby to catch up  (up to 3 minutes)"
TIMEOUT=180; ELAPSED=0; SYNCED=false
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    P=$($PRI -t -c "SELECT count(*) FROM pgbench_history;" 2>/dev/null | tr -d ' \n') || P=0
    S=$($STB -t -c "SELECT count(*) FROM pgbench_history;" 2>/dev/null | tr -d ' \n') || S=0
    printf "  [%3ds]  primary pgbench_history: %-7s  standby pgbench_history: %s\n" \
        "$ELAPSED" "$P" "$S"
    if [ "$P" -gt 0 ] && [ "$P" = "$S" ]; then
        SYNCED=true; break
    fi
    sleep 10; ELAPSED=$((ELAPSED + 10))
done

echo
if $SYNCED; then
    echo "  SUCCESS — standby has fully caught up with primary!"
else
    echo "  NOTE — standby has not quite caught up yet."
    echo "  The relay sync fires every 60 s; wait a moment and re-run the"
    echo "  final query block below, or check: docker logs pg_relay"
fi

# ── 8. Final comparison ──────────────────────────────────────
sep "8. Final row-count comparison"
echo "--- Primary ---"
$PRI -c "
SELECT 'pgbench_accounts' AS table, count(*) AS rows FROM pgbench_accounts
UNION ALL
SELECT 'pgbench_tellers',           count(*)          FROM pgbench_tellers
UNION ALL
SELECT 'pgbench_branches',          count(*)          FROM pgbench_branches
UNION ALL
SELECT 'pgbench_history',           count(*)          FROM pgbench_history;"

echo "--- Standby (read-only) ---"
$STB -c "
SELECT 'pgbench_accounts' AS table, count(*) AS rows FROM pgbench_accounts
UNION ALL
SELECT 'pgbench_tellers',           count(*)          FROM pgbench_tellers
UNION ALL
SELECT 'pgbench_branches',          count(*)          FROM pgbench_branches
UNION ALL
SELECT 'pgbench_history',           count(*)          FROM pgbench_history;"

# ── 9. Archiver + WAL file stats ────────────────────────────
sep "9. Archiver stats on primary"
$PRI -c "
SELECT archived_count, last_archived_wal, last_archived_time, failed_count
FROM   pg_stat_archiver;"

# ── 10. Check WAL file counts in each container ────────────────────────────
sep "10. WAL file counts in each archive"
echo "  Primary  /archive : $(docker exec pg_primary  ls /archive | wc -l) files"
echo "  Relay    /archive : $(docker exec pg_relay    ls /archive | wc -l) files"
echo "  Standby  /archive : $(docker exec pg_standby  ls /archive | wc -l) files"

echo
echo "Demo complete."
