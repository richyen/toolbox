#!/bin/bash

dir=${1%/}
for_real=${2}
prefix=`echo ${dir} | rev | cut -d/ -f1 | rev`
index=0

if [ "x${for_real}" == 'x' ]
    then
        for_real=0
        fi
if [ "x${dir}" == 'x' ]
    then
        #there was nothing passed in
        echo "usage: $0 <path/to/files> [ <for_real_flag> ]"
        exit
        fi

for i in `ls ${dir}`
    do
        index=$(( index + 1 ))
        fname=`printf '%s_%03d' $prefix $index`
        ext=${i##*.}
        if [ ${for_real} -eq 1 ]
            then
            mv ${dir}/${i} ${dir}/${fname}.${ext}
        else
            echo "going to perform mv ${dir}/${i} ${dir}/${fname}.${ext}"
        fi
        done
