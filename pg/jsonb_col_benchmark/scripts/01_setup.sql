\set ON_ERROR_STOP on

-- ---------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------
CREATE TABLE t_bare (
    id   BIGSERIAL PRIMARY KEY,
    data JSONB NOT NULL
);

CREATE TABLE t_expr (
    id   BIGSERIAL PRIMARY KEY,
    data JSONB NOT NULL
);

CREATE TABLE t_gin (
    id   BIGSERIAL PRIMARY KEY,
    data JSONB NOT NULL
);

CREATE TABLE t_gin_path (
    id   BIGSERIAL PRIMARY KEY,
    data JSONB NOT NULL
);

CREATE TABLE t_gen (
    id         BIGSERIAL PRIMARY KEY,
    data       JSONB   NOT NULL,
    user_id    INT     GENERATED ALWAYS AS ((data->>'user_id')::INT)      STORED,
    event_type TEXT    GENERATED ALWAYS AS (data->>'event_type')          STORED,
    ts         BIGINT  GENERATED ALWAYS AS ((data->>'timestamp')::BIGINT) STORED,
    action     TEXT    GENERATED ALWAYS AS (data->'action'->>'type')      STORED
);

-- ---------------------------------------------------------------
-- Seed data: 50,000 realistic JSONB event documents
-- ---------------------------------------------------------------
INSERT INTO t_bare (data)
SELECT jsonb_build_object(
    'user_id',    (random() * 10000)::INT,
    'event_type', 'event_' || (random() * 100)::INT,
    'timestamp',  (extract(epoch FROM now()) - random() * 86400 * 30)::BIGINT,
    'session_id', 'sess_' || md5(random()::TEXT),
    'ip_address', (random()*255)::INT || '.' || (random()*255)::INT || '.'
                  || (random()*255)::INT || '.' || (random()*255)::INT,
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
) FROM generate_series(1, 50000);

INSERT INTO t_expr     (data) SELECT data FROM t_bare;
INSERT INTO t_gin      (data) SELECT data FROM t_bare;
INSERT INTO t_gin_path (data) SELECT data FROM t_bare;
INSERT INTO t_gen      (data) SELECT data FROM t_bare;

-- ---------------------------------------------------------------
-- Indexes
-- Note: index names use table prefixes because index names are
-- schema-scoped; the blog post examples simplify to idx_user_id
-- etc. since they show a single unified events table.
-- ---------------------------------------------------------------

-- Expression index approach
CREATE INDEX idx_expr_user_id ON t_expr (cast(data->>'user_id' AS INT));

-- GIN approaches
CREATE INDEX idx_gin      ON t_gin      USING GIN (data);
CREATE INDEX idx_gin_path ON t_gin_path USING GIN (data jsonb_path_ops);

-- Generated column B-tree indexes
CREATE INDEX idx_gen_user_id    ON t_gen (user_id);
CREATE INDEX idx_gen_event_type ON t_gen (event_type);
CREATE INDEX idx_gen_ts         ON t_gen (ts);
CREATE INDEX idx_gen_action     ON t_gen (action);

-- ---------------------------------------------------------------
-- Gather statistics so the planner has accurate estimates
-- ---------------------------------------------------------------
ANALYZE t_bare, t_expr, t_gin, t_gin_path, t_gen;

SELECT relname AS table_name, reltuples::BIGINT AS estimated_rows
FROM pg_class
WHERE relname IN ('t_bare','t_expr','t_gin','t_gin_path','t_gen')
ORDER BY relname;
