#!/bin/bash

for i in `seq 1 3000`
do
  S="insert into ps_job values ( ${i}, 'foo', 'foo', 'foo', 'foo', ${i}, ${i}, ${i}, ${i}, ${i}"
  T=", 'string_${i}'"
  for j in `seq 1 160`
  do
    S="${S}${T}"
  done
  S="${S});"
  echo ${S}
  s="insert into ps_job_small values ( ${i}, 'foo', 'foo', 'foo', 'foo', ${i}, ${i}, ${i}, ${i}, ${i});"
  echo ${s}
done
