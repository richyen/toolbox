#!/bin/bash

# Install -contrib on db2
if [[ ${HOSTNAME} == 'pg2' ]]; then
  echo "Installing -contrib"
  yum -y install postgresql${PGMAJOR}-contrib
fi

# Start up postgres on all containers
su - postgres -c "pg_ctl -D /var/lib/pgsql/${PGMAJOR}/data start"

# Create demo schema
if [[ ${HOSTNAME} == 'pg1' ]]; then
  pgbench -iU postgres postgres
fi

# Keep things running
tail -f /dev/null
