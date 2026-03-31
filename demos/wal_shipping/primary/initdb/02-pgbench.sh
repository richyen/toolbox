#!/bin/bash
# Initialise pgbench tables on the primary (scale factor 10 ≈ 1 M account rows).
set -e

echo "[primary] Initialising pgbench (scale=10) …"
pgbench -U "$POSTGRES_USER" -d "$POSTGRES_DB" -i -s 10
echo "[primary] pgbench initialisation complete."
