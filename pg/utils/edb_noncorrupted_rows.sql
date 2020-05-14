-- edb_noncorrupted_rows - returns non-corrupted rows from a table.
--
-- It tries to fetch each tuple using ctid. If it cannot fetch the tuple
-- it logs a message and continues.  This function can be used as following
-- to create a new table from the non-corrupted rows.
--
-- BEGIN;
-- LOCK corrupted_table;
-- CREATE TABLE replace_corrupted_table AS
-- SELECT * FROM edb_noncorrupted_rows('corrupted_table'::regclass) as
-- f (schema of corrupted_table);
-- ALTER TABLE corrupted_table RENAME TO corrupted_table_old;
-- ALTER TABLE replace_corrupted_table RENAME TO corrupted_table;
-- COMMIT;

create or replace function edb_noncorrupted_rows(_tbl regclass) returns setof record as $$
declare
  x record;
  ct text;
begin
  -- loop through ctid lists ranging from (0, 0) to (num_blocks, max_tuples_per_page)
  -- Assume maximum tuples per page is 292 (See definition of MaxHeapTuplesPerPage)
  FOR ct IN EXECUTE format($q$
      SELECT '(' || b || ','|| generate_series(0,292) || ')' AS generated_tid
        FROM generate_series(0, pg_relation_size('%I'::regclass)/current_setting('block_size')::integer) b
    $q$, _tbl)
    LOOP
    begin
      EXECUTE 'SELECT * FROM ' || _tbl::regclass || ' where ctid::text = $1' into strict x USING ct;
      return next x;
    exception
    when others then
      RAISE LOG 'Error Name:% ctid: %',SQLERRM, ct;
    end;
  end loop;
return;
end$$ language plpgsql;
