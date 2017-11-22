#!/bin/bash

export PGPORT=5432
export PGUSER=enterprisedb
export PGDATABASE=edb
export PGHOST=127.0.0.1

D1=`date`

# Give everyone a 10% raise
for empno in `psql -Atc "SELECT empno FROM emp"`
  do
  psql -c "UPDATE emp SET sal = sal * 1.1 WHERE empno = ${empno}"
done

# Populate the sales table
psql -c "UPDATE sales SET salesperson = e.empno FROM (select distinct (empno % 13) + 1 as idx, * from emp) e WHERE (sales.id % 13) = e.idx"
MAXID=`psql -Atc "SELECT max(id) FROM sales"`
for id in `seq 1 ${MAXID}`
  do
  psql -qc "UPDATE sales SET customer_name = (SELECT 'Customer of ' || empno FROM emp WHERE empno = sales.salesperson)"
done

D2=`date`
echo "Start time: ${D1}"
echo "End time: ${D2}"
