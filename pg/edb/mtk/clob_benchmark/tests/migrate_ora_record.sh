#!/bin/bash

query="CREATE TABLE IF NOT EXISTS hr.foolob_new ( n numeric, c clob)"
psql -Atc "${query}"
query="TRUNCATE TABLE hr.foolob_new"
psql -Atc "${query}"
for start in `seq 0 1000000 24000000`
do
  query="select dblink_ora_connect('my_testlink','ora_host','ORCLCDB.localdomain','HR','HR',1521,false); SELECT dblink_ora_copy('my_testlink','select n,c from (select a.*, rownum rnum from (select n,c FROM foolob order by n) a where rownum <= $(( start + 999999 ))) where rnum >= ${start}', 'hr', 'foolob_new', false, 100000)"
  psql -Atc "${query}" &
done
