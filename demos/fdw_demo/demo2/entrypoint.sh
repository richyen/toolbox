#!/bin/bash

# Start PG
su - postgres -c "pg_ctl -D $PGDATA start"

# Install Faker
pip install Faker
pip install https://github.com/guedes/faker_fdw/archive/v0.2.4.zip

# Create SQLite database
sqlite3 /tmp/call_log.db "CREATE TABLE call_log (source_number varchar(15), target_number varchar(15), duration_secs int)"
sqlite3 /tmp/call_log.db "INSERT INTO call_log VALUES ('(510) 742-4273','(559) 299-4906',33)"
chmod 777 /tmp/call_log.db

# Load up DDL and generate seed data
psql < /docker/demo_ddl.sql

# Keep things running
tail -f /dev/null
