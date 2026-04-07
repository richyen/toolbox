\set ON_ERROR_STOP on

-- Table and index sizes per approach
SELECT
    relname                                          AS table_name,
    pg_size_pretty(pg_table_size(oid))               AS table_size,
    pg_size_pretty(pg_indexes_size(oid))             AS index_size,
    pg_size_pretty(pg_total_relation_size(oid))      AS total_size
FROM pg_class
WHERE relname IN ('t_bare', 't_expr', 't_gin', 't_gin_path', 't_gen')
  AND relkind = 'r'
ORDER BY relname;

-- Individual index sizes
SELECT
    i.relname                                  AS index_name,
    t.relname                                  AS on_table,
    pg_size_pretty(pg_relation_size(i.oid))    AS index_size
FROM pg_class     t
JOIN pg_index     x ON t.oid = x.indrelid
JOIN pg_class     i ON i.oid = x.indexrelid
WHERE t.relname IN ('t_expr', 't_gin', 't_gin_path', 't_gen')
  AND i.relkind = 'i'
ORDER BY t.relname, i.relname;
