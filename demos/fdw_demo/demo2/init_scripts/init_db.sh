#!/bin/bash

# Install Faker
# pip install Faker
# pip install https://github.com/guedes/faker_fdw/archive/v0.2.4.zip

# Create SQLite database
sqlite3 /tmp/call_log.db "CREATE TABLE call_log (source_number varchar(15), target_number varchar(15), duration_secs int)"
sqlite3 /tmp/call_log.db "INSERT INTO call_log VALUES ('(510) 742-4273','(559) 299-4906',33)"
chmod 777 /tmp/call_log.db

# Create FDWs
psql -c "create extension mysql_fdw" postgres postgres && \
psql -c "create extension sqlite_fdw" postgres postgres && \
psql -c "CREATE SERVER mysql_server FOREIGN DATA WRAPPER mysql_fdw options (host 'mysql');" postgres postgres && \
psql -c "CREATE USER MAPPING FOR postgres SERVER mysql_server OPTIONS (username 'root', password 'example');" postgres postgres && \
psql -c "CREATE SERVER sqlite_server FOREIGN DATA WRAPPER sqlite_fdw options (database '/tmp/call_log.db');" postgres postgres && \
psql -c "GRANT USAGE ON FOREIGN SERVER sqlite_server TO postgres" postgres postgres

# Load up DDL and generate seed data
psql < /docker/demo_ddl.sql
