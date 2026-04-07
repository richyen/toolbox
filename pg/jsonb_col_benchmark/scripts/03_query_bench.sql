\set ON_ERROR_STOP on

-- Timing helper: run a query N times, return avg/min/max in ms
CREATE OR REPLACE FUNCTION time_query(query text, iterations int DEFAULT 20)
RETURNS TABLE(avg_ms numeric, min_ms numeric, max_ms numeric)
LANGUAGE plpgsql AS $$
DECLARE
    t0      timestamptz;
    t1      timestamptz;
    times   numeric[] := '{}';
    elapsed numeric;
BEGIN
    FOR i IN 1..iterations LOOP
        t0 := clock_timestamp();
        EXECUTE query;
        t1 := clock_timestamp();
        elapsed := round(extract(epoch FROM (t1 - t0)) * 1000, 3);
        times   := times || elapsed;
    END LOOP;
    RETURN QUERY
        SELECT round(avg(v), 3), round(min(v), 3), round(max(v), 3)
        FROM unnest(times) v;
END;
$$;

-- Warm the buffer cache
SELECT count(*) FROM t_gin      WHERE data @> '{"user_id": 5234}';
SELECT count(*) FROM t_gin_path WHERE data @> '{"user_id": 5234}';
SELECT count(*) FROM t_expr     WHERE cast(data->>'user_id' AS INT) = 5234;
SELECT count(*) FROM t_gen      WHERE user_id = 5234;

-- Run 20 iterations per approach
SELECT approach, avg_ms, min_ms, max_ms
FROM (
    SELECT 'GIN jsonb_ops + @>'      AS approach, avg_ms, min_ms, max_ms
    FROM time_query('SELECT id FROM t_gin WHERE data @> ''{"user_id": 5234}''')
    UNION ALL
    SELECT 'GIN jsonb_path_ops + @>' AS approach, avg_ms, min_ms, max_ms
    FROM time_query('SELECT id FROM t_gin_path WHERE data @> ''{"user_id": 5234}''')
    UNION ALL
    SELECT 'Expression index'        AS approach, avg_ms, min_ms, max_ms
    FROM time_query('SELECT id FROM t_expr WHERE cast(data->>''user_id'' AS INT) = 5234')
    UNION ALL
    SELECT 'Generated column B-tree' AS approach, avg_ms, min_ms, max_ms
    FROM time_query('SELECT id FROM t_gen WHERE user_id = 5234')
) q
ORDER BY avg_ms;
