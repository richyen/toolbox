#!/bin/bash
set -e

PGDATA=/var/lib/postgresql/data
ARCHIVE_DIR=/archive
PRIMARY_HOST="${PRIMARY_HOST:-primary}"
REPLICATION_USER="${REPLICATION_USER:-replicator}"
REPLICATION_PASS="${REPLICATION_PASS:-replicator}"

# ── 1. Wait for relay rsyncd to be available ──────────────────
echo "[standby] Waiting for relay rsyncd …"
until rsync --list-only --timeout=5 rsync://relay/archive/ > /dev/null 2>&1; do
    echo "[standby] Relay not ready yet; retrying …"
    sleep 5
done
echo "[standby] Relay rsyncd is ready."

# ── 2. Base backup (once) ─────────────────────────────────────
if [ ! -f "$PGDATA/PG_VERSION" ]; then

    echo "[standby] Taking base backup from $PRIMARY_HOST …"

    take_backup() {
        rm -rf "$PGDATA"
        mkdir -p "$PGDATA"
        chmod 700 "$PGDATA"
        PGPASSWORD="$REPLICATION_PASS" pg_basebackup \
            -h "$PRIMARY_HOST" \
            -U "$REPLICATION_USER" \
            -D "$PGDATA" \
            --wal-method=none \
            --checkpoint=fast \
            -P
    }

    until take_backup; do
        echo "[standby] Base backup failed; retrying in 5 s …"
        sleep 5
    done
    echo "[standby] Base backup complete."

    # ── Append standby settings to postgresql.conf ──────────────
    # Single-quoted heredoc prevents shell from expanding %f / %p.
    cat >> "$PGDATA/postgresql.conf" <<'PGCONF'

# -------------------------------------------------------
# WAL-shipping standby — added by entrypoint.sh
# -------------------------------------------------------
hot_standby        = on
restore_command    = '/usr/local/bin/restore_wal.sh %f %p'
primary_conninfo   = ''
PGCONF

    # standby.signal puts PostgreSQL into continuous-recovery (standby) mode.
    touch "$PGDATA/standby.signal"

    # Fix ownership so the postgres user can read/write everything.
    chown -R postgres:postgres "$PGDATA"
    echo "[standby] Configuration written; standby.signal created."
fi

# ── 3. Background WAL sync from relay every 60 seconds ───────
(
    echo "[standby] Background WAL sync loop started (every 60 s)."
    while true; do
        sleep 60
        echo "[standby] $(date -u '+%Y-%m-%dT%H:%M:%SZ') — syncing WAL cache from relay …"
        rsync -av --timeout=30 rsync://relay/archive/ "$ARCHIVE_DIR/" 2>&1 | tail -5
    done
) &

# ── 4. Start PostgreSQL in standby mode ───────────────────────
echo "[standby] Starting PostgreSQL 18 in hot-standby mode …"
exec gosu postgres postgres -D "$PGDATA"
