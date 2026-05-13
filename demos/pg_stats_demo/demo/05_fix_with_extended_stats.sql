-- ============================================================
-- Demo 5 (slides 16-18): Fix with CREATE STATISTICS
-- ============================================================
-- Goal: tell Postgres that (city, state) are correlated, run
-- ANALYZE, and watch the estimate jump from "off by ~200x" to
-- "essentially correct".
-- ------------------------------------------------------------

\echo
\echo '--- BEFORE: estimate is based on the independence assumption ---'
EXPLAIN
SELECT * FROM customers
WHERE city = 'Cheyenne' AND state = 'WY';

\echo
\echo '--- Teach Postgres about the dependency between city and state ---'
DROP STATISTICS IF EXISTS customers_city_state;
CREATE STATISTICS customers_city_state (dependencies, ndistinct, mcv)
    ON city, state FROM customers;

ANALYZE customers;

\echo
\echo '--- What kinds of extended stats Postgres captured ---'
SELECT statistics_name, attnames, kinds
FROM pg_stats_ext
WHERE tablename = 'customers';

\echo
\echo '--- The dependency strengths Postgres learned ---'
SELECT s.stxname,
       sd.stxddependencies AS functional_dependencies,
       sd.stxdndistinct    AS ndistinct
FROM   pg_statistic_ext      s
JOIN   pg_statistic_ext_data sd ON sd.stxoid = s.oid
WHERE  s.stxname = 'customers_city_state';

\echo
\echo '--- AFTER: estimate now reflects the joint distribution ---'
EXPLAIN (ANALYZE, BUFFERS, COSTS)
SELECT * FROM customers
WHERE city = 'Cheyenne' AND state = 'WY';

\echo
\echo '--- To re-run the demo from scratch: ---'
\echo '    DROP STATISTICS customers_city_state;'
\echo '    ANALYZE customers;'
