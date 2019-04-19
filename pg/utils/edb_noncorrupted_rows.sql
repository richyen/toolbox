-- edb_noncorrupted_rows - returns non-corrupted rows from a table.
--
-- It tries to fetch each tuple using ctid. If it cannot fetch the tuple
-- it ignores the same and continues.  This function can be used as following
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
--
-- Please note that, this function has the following assumtions:
-- 1. The block size is 8192 bytes.
-- 2. Maximum tuples per page is 291 (See definition of MaxHeapTuplesPerPage)

create or replace function edb_noncorrupted_rows(_tbl regclass) returns setof record as $$
declare
	x record; --return parameter
	i text;
	rel_size int;
	max_tuples_per_page int;
	num_blocks int;
	total_tuples int;
begin

EXECUTE format('select pg_relation_size(''%s'')', _tbl) into rel_size;
num_blocks := (rel_size/8192);
max_tuples_per_page := 291;
total_tuples := num_blocks * max_tuples_per_page;

-- loop through ctid lists ranging from (0, 1) to (num_blocks - 1, max_tuples_per_page)
for i in select concat('(',concat(concat_ws(',',g / max_tuples_per_page, (g % max_tuples_per_page)+1),')'))::text from generate_series(0, total_tuples) g
loop
	begin
		EXECUTE format('select * from %s where ctid = ''%s''::tid', _tbl, i) into strict x;
		return next x;
	exception
	when others then
		RAISE LOG 'Error Name:% ctid: %',SQLERRM, i;
	end;
end loop;
end$$ language plpgsql;
