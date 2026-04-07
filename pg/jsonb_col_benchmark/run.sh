#!/usr/bin/env bash
# Runs the benchmark suite and tees output to a timestamped file in ./results/
# Usage:
#   ./run.sh                    # default PG version (18.2)
#   PG_VERSION=17 ./run.sh      # specific version
set -euo pipefail

VERSION=${PG_VERSION:-18.2}
mkdir -p results
OUTFILE="results/benchmark_pg${VERSION}_$(date +%Y%m%d_%H%M%S).txt"

echo "Running benchmark for PostgreSQL ${VERSION}..."
echo "Results will be saved to: ${OUTFILE}"
echo ""

PG_VERSION=${VERSION} docker compose up --abort-on-container-exit 2>&1 | tee "${OUTFILE}"

echo ""
echo "Done. Results saved to: ${OUTFILE}"
