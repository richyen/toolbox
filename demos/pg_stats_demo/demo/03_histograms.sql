-- ============================================================
-- Demo 3 (slides 11-13): Histograms and ranges
-- ============================================================
-- Goal: show how histogram_bounds turns a range predicate into
-- a row estimate, then show the SET STATISTICS knob.
-- ------------------------------------------------------------

\echo
\echo '--- First 8 histogram boundaries for signup_date ---'
\echo '    (default target = 100 buckets, each ~1% of rows)'

SELECT (unnest(histogram_bounds::text::date[]))::date AS bucket_bound
FROM pg_stats
WHERE tablename = 'customers' AND attname = 'signup_date'
LIMIT 8;

\echo
\echo '--- Range query, default statistics target ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM customers
WHERE signup_date BETWEEN DATE '2020-04-01' AND DATE '2020-07-31';

\echo
\echo '--- Raise the statistics target -> finer-grained histogram ---'
ALTER TABLE customers ALTER COLUMN signup_date SET STATISTICS 1000;
ANALYZE customers (signup_date);

\echo
\echo '--- Check how many histogram boundaries we now have ---'
SELECT array_length(histogram_bounds::text::date[], 1) AS num_bounds
FROM pg_stats
WHERE tablename = 'customers' AND attname = 'signup_date';

\echo
\echo '--- Same range query, finer histogram ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM customers
WHERE signup_date BETWEEN DATE '2020-04-01' AND DATE '2020-07-31';

\echo
\echo '--- Reset the statistics target back to default ---'
ALTER TABLE customers ALTER COLUMN signup_date SET STATISTICS -1;
ANALYZE customers (signup_date);
