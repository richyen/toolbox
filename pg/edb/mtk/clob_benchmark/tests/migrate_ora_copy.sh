#!/bin/bash

query="CREATE TABLE IF NOT EXISTS hr.foolob ( n numeric, c clob)"
psql -Atc "${query}"
query="TRUNCATE TABLE hr.foolob"
psql -Atc "${query}"
for start in `seq 0 1000000 24000000`
do
  query="select dblink_ora_connect('my_testlink','ora_host','ORCLCDB.localdomain','HR','HR',1521,false); INSERT INTO hr.foolob(n,c) SELECT n,c FROM dblink_ora_record('my_testlink','select n,c from (select a.*, rownum rnum from (select n,c FROM foolob order by n) a where rownum <= $(( start + 999999 ))) where rnum >= ${start}') as t1(n number, c clob)"
  psql -Atc "${query}" &
done
