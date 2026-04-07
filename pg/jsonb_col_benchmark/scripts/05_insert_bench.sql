\set ON_ERROR_STOP on

-- Generates a single realistic JSONB event row
CREATE OR REPLACE FUNCTION gen_row() RETURNS jsonb LANGUAGE sql AS $$
    SELECT jsonb_build_object(
        'user_id',    (random() * 10000)::INT,
        'event_type', 'event_' || (random() * 100)::INT,
        'timestamp',  extract(epoch FROM now())::BIGINT,
        'session_id', 'sess_' || md5(random()::TEXT),
        'ip_address', '10.0.' || (random()*255)::INT || '.' || (random()*255)::INT,
        'action', jsonb_build_object(
            'type',      CASE WHEN random() > 0.5 THEN 'click' ELSE 'view' END,
            'target_id', (random() * 100000)::INT
        ),
        'device', jsonb_build_object(
            'type', CASE WHEN random() > 0.6 THEN 'mobile'
                         WHEN random() > 0.3 THEN 'tablet' ELSE 'desktop' END,
            'os',   CASE WHEN random() > 0.6 THEN 'iOS'
                         WHEN random() > 0.3 THEN 'Android' ELSE 'Windows' END,
            'screen_width', (1024 + random() * 1920)::INT
        )
    );
$$;

-- Times N inserts against target_table, then rolls back so table size stays stable.
-- Returns elapsed milliseconds.
CREATE OR REPLACE FUNCTION time_inserts(target_table text, n int)
RETURNS numeric LANGUAGE plpgsql AS $$
DECLARE
    t0 timestamptz;
    t1 timestamptz;
BEGIN
    t0 := clock_timestamp();
    EXECUTE format(
        'INSERT INTO %I (data) SELECT gen_row() FROM generate_series(1, %s)',
        target_table, n
    );
    t1 := clock_timestamp();
    RAISE EXCEPTION 'rollback_marker';  -- roll back the inserts
    RETURN 0;
EXCEPTION WHEN OTHERS THEN
    RETURN round(extract(epoch FROM (t1 - t0)) * 1000, 1);
END;
$$;

-- 5 trials x 5,000 inserts per approach
SELECT
    tbl                    AS approach,
    round(avg(ms), 1)      AS avg_ms,
    round(min(ms), 1)      AS min_ms,
    round(max(ms), 1)      AS max_ms
FROM (
    SELECT 'GIN jsonb_ops'          AS tbl, time_inserts('t_gin',      5000) AS ms FROM generate_series(1,5)
    UNION ALL
    SELECT 'GIN jsonb_path_ops'     AS tbl, time_inserts('t_gin_path', 5000) AS ms FROM generate_series(1,5)
    UNION ALL
    SELECT 'Expression index'       AS tbl, time_inserts('t_expr',     5000) AS ms FROM generate_series(1,5)
    UNION ALL
    SELECT 'Generated column btree' AS tbl, time_inserts('t_gen',      5000) AS ms FROM generate_series(1,5)
    UNION ALL
    SELECT 'No index (bare)'        AS tbl, time_inserts('t_bare',     5000) AS ms FROM generate_series(1,5)
) sub
GROUP BY tbl
ORDER BY avg_ms;
