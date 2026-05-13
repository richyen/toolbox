-- ============================================================
-- Demo 4 (slides 14-15): The correlated-columns blow-up
-- ============================================================
-- Goal: show that with only per-column stats, Postgres uses the
-- INDEPENDENCE ASSUMPTION:
--
--     rows = P(city='Cheyenne') * P(state='WY') * total_rows
--
-- and arrives at a wildly low estimate, because Cheyenne is
-- only in WY.
-- ------------------------------------------------------------

\echo
\echo '--- Per-column frequencies the planner is multiplying ---'

WITH s_state AS (
    SELECT unnest(most_common_vals::text::text[])  AS v,
           unnest(most_common_freqs)               AS f
    FROM pg_stats WHERE tablename='customers' AND attname='state'
),
s_city AS (
    SELECT unnest(most_common_vals::text::text[])  AS v,
           unnest(most_common_freqs)               AS f
    FROM pg_stats WHERE tablename='customers' AND attname='city'
),
totals AS (SELECT reltuples AS n FROM pg_class WHERE relname='customers')
SELECT
    (SELECT f FROM s_state WHERE v='WY')                                  AS p_state_wy,
    (SELECT f FROM s_city  WHERE v='Cheyenne')                            AS p_city_cheyenne,
    (SELECT n FROM totals)                                                AS total_rows,
    round((
        (SELECT f FROM s_state WHERE v='WY') *
        (SELECT f FROM s_city  WHERE v='Cheyenne') *
        (SELECT n FROM totals)
    )::numeric, 0)                                                        AS naive_estimate;

\echo
\echo '--- The actual plan (note rows estimate vs actual rows) ---'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT * FROM customers
WHERE city = 'Cheyenne' AND state = 'WY';

\echo
\echo '--- For comparison: actual count of matching rows ---'
SELECT count(*) AS actual_matches
FROM customers
WHERE city = 'Cheyenne' AND state = 'WY';
