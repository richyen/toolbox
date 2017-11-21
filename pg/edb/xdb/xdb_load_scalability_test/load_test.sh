#!/bin/bash

# TODO:
# Run gather_stats.sh in background
# Run iostat in background
# Run vmstat in background
# Run replication_keepalive.sh in background

for ((R=1;R<20;R++))
 do
 psql < insert.sql
 echo "GOING TO RUN TEST FOR ${R}00 RATE"
 date
 /usr/ppas-9.5/bin/pgbench -c10 -j2 -P 30 -R ${R}00 -T 900 -f /home/ec2-user/bench.sql -p5432 -U enterprisedb edb 2>&1
 sleep 1800
 done 2>&1 | tee /tmp/tps.txt   
