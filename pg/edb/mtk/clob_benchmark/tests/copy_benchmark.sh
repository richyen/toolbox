#!/bin/bash

# Benchmark migration time against chunk size

query="CREATE TABLE IF NOT EXISTS public.foolob_new ( n numeric, c clob )"
psql -Atc "${query}"
for incsize in `seq 5 25`
do
  echo "starting $incsize at `date`" >> /tmp/times.log
  query="TRUNCATE TABLE public.foolob_new"
  psql -Atc "${query}"
  for start in `seq 0 ${incsize}00000 24000000`
  do
    query="select dblink_ora_connect('my_testlink','ora_host','ORCLCDB.localdomain','HR','HR',1521,false); SELECT dblink_ora_copy('my_testlink','select n,c from (select a.*, rownum rnum from (select n,c FROM foolob order by n) a where rownum <= $(( start + 999999 ))) where rnum >= ${start}', 'public', 'foolob_new')"
    psql -Atc "${query}" &
    pids[${start}]=$!
  done
  for pid in ${pids[*]}; do
    wait $pid
  done
  psql -c "select count(*) from public.foolob_new" >> /tmp/times.log
  echo "done with $incsize at `date`" >> /tmp/times.log
done
