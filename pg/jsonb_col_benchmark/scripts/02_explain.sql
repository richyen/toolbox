\set ON_ERROR_STOP on
\pset tuples_only on

-- Warm the buffer cache before capturing plans
SELECT count(*) FROM t_gin      WHERE data @> '{"user_id": 5234}';
SELECT count(*) FROM t_gin_path WHERE data @> '{"user_id": 5234}';
SELECT count(*) FROM t_expr     WHERE cast(data->>'user_id' AS INT) = 5234;
SELECT count(*) FROM t_gen      WHERE user_id = 5234;
SELECT count(*) FROM t_bare     WHERE cast(data->>'user_id' AS INT) = 5234;

\echo ''
\echo '--- GIN (jsonb_ops) + containment operator ---'
\echo 'Query: SELECT id FROM t_gin WHERE data @> \'{"user_id": 5234}\';'
EXPLAIN (ANALYZE) SELECT id FROM t_gin WHERE data @> '{"user_id": 5234}';

\echo ''
\echo '--- GIN (jsonb_path_ops) + containment operator ---'
\echo 'Query: SELECT id FROM t_gin_path WHERE data @> \'{"user_id": 5234}\';'
EXPLAIN (ANALYZE) SELECT id FROM t_gin_path WHERE data @> '{"user_id": 5234}';

\echo ''
\echo '--- Expression index ---'
\echo 'Query: SELECT id FROM t_expr WHERE cast(data->>\'user_id\' AS INT) = 5234;'
EXPLAIN (ANALYZE) SELECT id FROM t_expr WHERE cast(data->>'user_id' AS INT) = 5234;

\echo ''
\echo '--- Generated column B-tree ---'
\echo 'Query: SELECT id FROM t_gen WHERE user_id = 5234;'
EXPLAIN (ANALYZE) SELECT id FROM t_gen WHERE user_id = 5234;

\echo ''
\echo '--- Seq scan baseline: no index (t_bare) ---'
\echo 'Query: SELECT id FROM t_bare WHERE cast(data->>\'user_id\' AS INT) = 5234;'
EXPLAIN (ANALYZE) SELECT id FROM t_bare WHERE cast(data->>'user_id' AS INT) = 5234;

\echo ''
\echo '--- GIN present but incompatible operator -- expect seq scan ---'
\echo 'Query: SELECT id FROM t_gin WHERE cast(data->>\'user_id\' AS INT) = 5234;'
EXPLAIN (ANALYZE) SELECT id FROM t_gin WHERE cast(data->>'user_id' AS INT) = 5234;

\echo ''
\echo '--- Composite index range query on generated columns ---'
\echo 'Query: SELECT id FROM t_gen WHERE event_type = \'event_42\' AND ts > 1700000000;'
EXPLAIN (ANALYZE) SELECT id FROM t_gen WHERE event_type = 'event_42' AND ts > 1700000000;

\pset tuples_only off
