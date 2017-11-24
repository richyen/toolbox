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
psql -c "INSERT INTO sales VALUES (generate_series(1001,2000),(SELECT max(empno) FROM emp),md5(random()), now() - random() * interval '1 year', (random()*100)::int);"
psql -c "UPDATE sales SET salesperson = e.empno, sale_amount = random() * 100 FROM (select distinct (empno % 13) + 1 as idx, * from emp) e WHERE (sales.id % 13) = e.idx"

# Set the customer name for each row based on the empno/salesperson
MAXID=`psql -Atc "SELECT max(id) FROM sales"`
for id in `seq 1 ${MAXID}`
  do
  psql -qc "UPDATE sales SET customer_name = (SELECT 'Customer of ' || empno FROM emp WHERE empno = sales.salesperson)"
done

D2=`date`
echo "Start time: ${D1}"
echo "End time: ${D2}"
