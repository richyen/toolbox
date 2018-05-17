-- Invoke with:
-- \copy (select get_raw_page_deep('<table_name>', <block_num>)) to '/tmp/raw_page_out.sql' with csv;

CREATE OR REPLACE FUNCTION get_raw_page_deep(p_relname text, p_blockno int8)
RETURNS bytea
STRICT PARALLEL SAFE
LANGUAGE plpgsql
AS $body$
DECLARE
    v_segment_size CONSTANT int4 := (SELECT setting::int4 FROM pg_settings WHERE name = 'segment_size');
    v_block_size CONSTANT int4 := (SELECT setting::int4 FROM pg_settings WHERE name = 'block_size');
    v_segno int4 = p_blockno / v_segment_size;
    v_segoff int4 = p_blockno % v_segment_size;
    v_path text;
BEGIN
    v_path := pg_relation_filepath(p_relname);
    IF v_segno > 0 THEN
       v_path := v_path || '.' || v_segno;
    END IF;
    RETURN pg_read_binary_file(v_path, v_segoff * v_block_size, v_block_size, false);
END;
$body$;
