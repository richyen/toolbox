#!/bin/bash

### Simple script to date-prefix files (usually photos or videos) based on ExifTool (https://en.wikipedia.org/wiki/ExifTool)

dir=${1:-.}
prefix=${2}
do_it=${3:-0}
outfile="${HOME}/Desktop/date_prefix_out.txt"
counter=1
for i in `ls ${dir}`
do
  C=`exiftool ${dir}/${i} | grep "Create Date" | head -n1 | awk '{ print $4 }' | sed -e "s/:/-/g"`
  ext=`echo ${i} | cut -f2 -d'.'`
  mv_cmd="mv ${dir}/${i} ${dir}/${C}_${prefix}_${counter}.${ext}"
  counter=$(( counter+1 ))
  if [[ $do_it -eq 1 ]]
  then
    `$mv_cmd`
  else
    echo $mv_cmd >> $outfile
  fi
done
