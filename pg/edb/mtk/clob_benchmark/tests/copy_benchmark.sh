#!/bin/bash

# Benchmark migration time against chunk size

query="CREATE TABLE IF NOT EXISTS public.foolob_new ( n numeric, c clob )"
psql -Atc "${query}"
for num_threads in `seq 1 24`
do
  query="TRUNCATE TABLE public.foolob_new"
  psql -Atc "${query}"
  segment_size=$(( 24000000 / num_threads ))
  echo "starting $num_threads at `date`" >> /tmp/times.log
  for thread_num in `seq 0 $(( num_threads - 1 ))`
  do
    query="select dblink_ora_connect('my_testlink','ora_host','ORCLCDB.localdomain','HR','HR',1521,false); SELECT dblink_ora_copy('my_testlink','select n,c from (select a.*, rownum rnum from (select n,c FROM foolob order by n) a where rownum <= $(( thread_num * segment_size + (segment_size - 1)))) where rnum >= $(( thread * segment_size ))', 'public', 'foolob_new')"
    psql -Atc "${query}" &
    pids[${thread_num}]=$!
  done
  for pid in ${pids[*]}; do
    wait $pid
  done
  psql -c "select count(*) from public.foolob_new" >> /tmp/times.log
  echo "done with $thread_size at `date`" >> /tmp/times.log
done
