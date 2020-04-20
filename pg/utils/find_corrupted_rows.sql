-- edb_corrupted_rows - returns corrupted rows from a table.
-- Basically does the opposite of edb_noncorrupted_rows
--
-- It tries to fetch each tuple using ctid. If it cannot fetch the tuple,
-- it adds the ctid to the edb_corrupted_rows table and continues.
--
-- Please note that, this function has the following assumptions:
-- 1. The block size is 8192 bytes.
-- 2. Maximum tuples per page is 291 (See definition of MaxHeapTuplesPerPage)

BEGIN TRANSACTION;

CREATE TABLE edb_corrupted_rows(schemaname TEXT,
								tablename TEXT,
								t_ctid TID,
								sqlstate TEXT,
								sqlerrm TEXT);

CREATE OR REPLACE FUNCTION check_table_row_corruption(schemaname TEXT, tablename TEXT) RETURNS VOID AS $$
DECLARE
    rec RECORD;
    tmp RECORD;
    t_ctid TID;
    tmp_text TEXT;
BEGIN
    FOR rec IN EXECUTE 'SELECT ctid
                        FROM ' || quote_ident(schemaname) || '.' || quote_ident(tablename)
        LOOP
    BEGIN
        t_ctid := rec.ctid;
        BEGIN
            EXECUTE 'SELECT * FROM '
                    || quote_ident(schemaname) || '.' || quote_ident(tablename)
                    || ' WHERE ctid = ''' || t_ctid || '''::tid'
                INTO STRICT tmp;

            tmp_text := tmp::text;
        EXCEPTION WHEN OTHERS THEN
	    BEGIN
          INSERT INTO edb_corrupted_rows VALUES(schemaname, tablename, t_ctid, SQLSTATE::text, SQLERRM::text);
        COMMIT;
	    END;
        END;
    END;
    END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMIT TRANSACTION;
