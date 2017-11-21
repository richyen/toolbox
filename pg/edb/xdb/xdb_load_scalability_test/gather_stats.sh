#!/bin/bash
#check previous count

W1="0/54358F60"
while :
do
# Get sample time
  D=`date +%s`

# Get WAL count, MC style
  dat=`date --date='1 minute ago'|awk {'print$4'}|cut -d ':' -f 1,2`
  C=`ls -ltrh /var/lib/ppas/9.5/data/pg_xlog|grep $dat|wc -l`
  echo "mc.master.walcount $C $D"

# Get WAL count, EDB style
  W2=`psql -Atc "set timezone to 'utc'; SELECT pg_current_xlog_location()" | grep -v SET`
  R=`psql -Atc "SELECT pg_xlog_location_diff('$W2', '$W1')/(16*1024*1024)"`
  W1=${W2}
  echo "edb.master.walcount $R $D"

# Get lag statistics
  L=`psql -At < lag_query.sql | grep -v SET | cut -f4 -d'|' | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }' | xargs echo -n`
  echo "replication.lag $L $D"

sleep 30
done
