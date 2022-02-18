#!/bin/bash

if [[ `hostname` == 'pgb' ]]; then
  yum -y install pgbouncer
  cp /docker/pgbouncer.ini /etc/pgbouncer/pgbouncer.ini
  echo '"foouser" "md519f71067fc0d06d9255e66dcedf01481"' > /etc/pgbouncer/userlist.txt
  su - pgbouncer -c "pgbouncer -dq /etc/pgbouncer/pgbouncer.ini"

  sleep 5

  # this is the demo portion
  set -x
  PGPASSWORD=bar123 psql -h 127.0.0.1 -p 6432 -U baruser -Atc "SELECT 'success'" foodb
  PGPASSWORD=bar123 psql -h 127.0.0.1 -p 6432 -U baruser -Atc "SELECT 'success'" bardb
  PGPASSWORD=bar890 psql -h 127.0.0.1 -p 6432 -U baruser -Atc "SELECT 'success'" bardb
else
  su - postgres -c "pg_ctl start"
  psql -c "ALTER USER postgres with password 'abc123'"
  psql -c "CREATE USER foouser with password 'abc123'"
  psql -c "CREATE USER baruser with password 'bar123'"
  psql -c "CREATE OR REPLACE FUNCTION user_search(uname TEXT) returns table(usename name, passwd text)as \$\$ SELECT usename, passwd FROM pg_shadow WHERE usename=\$1  \$\$ language sql SECURITY DEFINER;"
fi

tail -f /dev/null
