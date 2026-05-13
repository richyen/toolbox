-- ============================================================
-- Demo 2 (slides 8-10): Most Common Values and skew
-- ============================================================
-- Goal: prove that the planner picks Seq Scan for state='CA'
-- and Index Scan for state='WY' because it KNOWS, from the
-- MCV list, that CA is common and WY is rare.
-- ------------------------------------------------------------

\echo
\echo '--- Most Common Values for state ---'

SELECT
    unnest(most_common_vals::text::text[])   AS state,
    unnest(most_common_freqs)                AS frequency
FROM pg_stats
WHERE tablename = 'customers' AND attname = 'state'
LIMIT 10;

-- We disable bitmap scans for this demo so the planner has to choose
-- between a pure Seq Scan and a pure Index Scan, which is the contrast
-- the slides show. (With bitmap scans enabled, Postgres picks Bitmap
-- Heap Scan in both cases; same lesson, less dramatic visual.)
SET enable_bitmapscan = off;

\echo
\echo '--- Plan for a COMMON state (expect Seq Scan, big rows estimate) ---'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT * FROM customers WHERE state = 'CA';

\echo
\echo '--- Plan for a RARE state (expect Index Scan, tiny rows estimate) ---'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT * FROM customers WHERE state = 'WY';

\echo
\echo '--- Why? Look at the MCV frequency for each value: ---'
SELECT
    v AS state,
    f AS mcv_frequency,
    round((f * (SELECT reltuples FROM pg_class WHERE relname = 'customers'))::numeric, 0)
        AS estimated_rows
FROM (
    SELECT unnest(most_common_vals::text::text[])   AS v,
           unnest(most_common_freqs)                AS f
    FROM pg_stats
    WHERE tablename = 'customers' AND attname = 'state'
) s
WHERE v IN ('CA', 'WY');

RESET enable_bitmapscan;
