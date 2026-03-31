#!/bin/bash
# restore_command script — called by PostgreSQL as:
#   restore_wal.sh %f %p
# where %f = WAL filename, %p = destination path.
#
# Strategy:
#   1. Serve from the local cache (/archive) when possible.
#   2. Fall back to fetching the specific file directly from the relay rsyncd.
#   3. Return 1 (failure) so PostgreSQL waits and retries later.

WAL_FILE="$1"
DEST_PATH="$2"
ARCHIVE_DIR=/archive

# 1 — Local cache hit
if [ -f "$ARCHIVE_DIR/$WAL_FILE" ]; then
    cp "$ARCHIVE_DIR/$WAL_FILE" "$DEST_PATH"
    exit 0
fi

# 2 — Direct fetch from relay rsyncd
if rsync --timeout=15 "rsync://relay/archive/$WAL_FILE" "$DEST_PATH" 2>/dev/null; then
    exit 0
fi

# 3 — Not available yet
exit 1
