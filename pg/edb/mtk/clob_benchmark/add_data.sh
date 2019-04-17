#!/bin/bash

numrows=$1
rowsize=$2

cat <<_EOF_ > /tmp/query.sql
begin
 for lc in 1..${numrows} loop
 insert into HR.FOOLOB (n, c)
 values (lc, rpad('*',${rowsize},'*'));
 end loop;
 commit;
end;
/
_EOF_

sqlplus -S system/oracle < /tmp/query.sql
rm -f /tmp/query.sql
