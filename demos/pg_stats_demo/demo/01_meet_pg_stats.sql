-- ============================================================
-- Demo 1 (slide 7): Meeting pg_stats
-- ============================================================
-- Goal: show that Postgres has a summary of each column with
-- a different "fingerprint": cardinality, null fraction,
-- physical correlation.
--
-- Expected output:
--   state       : n_distinct = 50,         correlation near 1.0
--                 (we inserted state-grouped)
--   city        : n_distinct around 20000, correlation near 0.0
--   signup_date : n_distinct around 1825,  correlation near 1.0
-- ------------------------------------------------------------

\echo
\echo '--- pg_stats fingerprint for the customers table ---'

SELECT attname,
       n_distinct,
       null_frac,
       correlation
FROM pg_stats
WHERE schemaname = 'public'
  AND tablename  = 'customers'
ORDER BY attname;
