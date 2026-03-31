#!/bin/bash
# Runs inside initdb — postgres is temporarily up, running as $POSTGRES_USER.
set -e

# Allow replication connections from any host in the Docker network (demo only).
echo "host replication replicator 0.0.0.0/0 trust" >> "$PGDATA/pg_hba.conf"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER replicator WITH REPLICATION LOGIN PASSWORD 'replicator';
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
    -c "SELECT pg_reload_conf();"

echo "[primary] Replicator user created; pg_hba.conf updated."
