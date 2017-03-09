#!/bin/bash

# Case 627422

export PGPASSWORD
export PGUSER=enterprisedb
export PGDATABASE=edb
export PGPORT=5444

# Need to create table bar with just one col, one row, that has a 32kB text entry
# Need to create table foo with serial and text cols first

for i in `seq 1 11`
do
  echo "starting insert iteration $i at `date`" >> /tmp/mem_tracking
  /opt/PostgresPlus/9.2AS/bin/psql -c "insert into foo values (generate_series(${i}000001,$(( i + 1 ))000000), (select description from bar limit 1))" 2>&1 >> /tmp/mem_tracking
  echo "starting backup iteration $i at `date`" >> /tmp/mem_tracking
  valgrind --tool=massif /opt/PostgresPlus/9.2AS/bin/pg_dump -Z3 -Fc -U enterprisedb -v -p 5444 -f "/tmp/DB_${i}.dmp" edb 2>&1 >> /tmp/mem_tracking
  echo "finished iteration $i at `date`" >> /tmp/mem_tracking
done

