#!/bin/bash
set -e

ARCHIVE_DIR=/archive
PRIMARY_RSYNC="rsync://primary/archive/"
SYNC_INTERVAL=60

echo "[relay] Waiting for primary rsyncd …"
until rsync --list-only --timeout=5 rsync://primary/archive/ > /dev/null 2>&1; do
    sleep 3
done
echo "[relay] Primary rsyncd is ready."

echo "[relay] Performing initial WAL sync from primary …"
rsync -av --timeout=30 "$PRIMARY_RSYNC" "$ARCHIVE_DIR/"
echo "[relay] Initial sync complete."

# Serve the local archive to the standby container.
rsync --daemon --config=/etc/rsyncd.conf
echo "[relay] rsyncd started on port 873 (serving $ARCHIVE_DIR)"

# Pull new WAL files from the primary every 60 seconds.
echo "[relay] Starting sync loop (every ${SYNC_INTERVAL}s) …"
while true; do
    sleep "$SYNC_INTERVAL"
    echo "[relay] $(date -u '+%Y-%m-%dT%H:%M:%SZ') — syncing WAL from primary …"
    rsync -av --timeout=30 "$PRIMARY_RSYNC" "$ARCHIVE_DIR/" 2>&1 | tail -5
done
