-- Create Faker FDW
CREATE SERVER faker_srv FOREIGN DATA WRAPPER multicorn OPTIONS (wrapper 'faker_fdw.FakerForeignDataWrapper');
CREATE SCHEMA fake;
CREATE FOREIGN TABLE fake.person (ssn varchar, name varchar, phone_number varchar, address text) SERVER faker_srv OPTIONS (max_results '100');
ALTER FOREIGN TABLE fake.person OPTIONS ( add seed '1234' );

-- Load data into SQL for later FDW access
CREATE FOREIGN TABLE sqlite_call_log (source_number text, target_number text, duration_secs int) SERVER sqlite_server OPTIONS (table 'call_log');
INSERT INTO sqlite_call_log (SELECT to_char(random() * 10000000000, 'FM"("000") "000"-"0000'), to_char(random() * 10000000000, 'FM"("000") "000"-"0000'), (random() * 100)::int from generate_series(1,10000));
DROP FOREIGN TABLE sqlite_call_log;
