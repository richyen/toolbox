#!/bin/bash
set -e

# Start rsyncd daemon so the relay container can pull archived WAL files.
rsync --daemon --config=/etc/rsyncd.conf
echo "[primary] rsyncd started on port 873 (serving /archive)"

# Delegate everything else to the official postgres entrypoint.
# Extra -c flags enable WAL archiving.
exec /usr/local/bin/docker-entrypoint.sh postgres \
    -c wal_level=replica \
    -c archive_mode=on \
    -c "archive_command=cp %p /archive/%f" \
    -c archive_timeout=60 \
    -c max_wal_senders=5 \
    -c listen_addresses='*'
