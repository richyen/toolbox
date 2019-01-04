#!/bin/bash

### Simple script to date-prefix files (usually photos or videos) based on ExifTool (https://en.wikipedia.org/wiki/ExifTool)

dir=${1:-.}
do_it=${2:-0}
outfile="~/Desktop/date_prefix_out.txt"
counter=1
for i in `ls ${dir}`
do
  C=`exiftool $i | grep "Creation Date" | awk '{ print $4 }' | sed -e "s/:/-/g"`
  mv_cmd="mv $i ${C}_$counter.MOV"
  counter=$(( counter+1 ))
  if [[ $do_it -eq 1 ]]
  then
    `$mv_cmd`
  else
    echo $mv_cmd >> $outfile
  fi
done
