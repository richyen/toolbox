#!/bin/bash

EMAIL_ADDRESS=''
LOGFILE=''
COUNTER=0
while [ 1 ]
do
    C=`cat ${LOGFILE} | grep -ci "copy_set.*done"`
    echo "${C} -> ${COUNTER} at `date`"
    if [ ${C} -gt ${COUNTER} ]
    then
        SL_DONE=`cat ${LOGFILE} | grep -i "copy_set.*done"`
        echo "DONE\n${SL_DONE}" | mail -s "DONE: A Slony copy_set finished on `hostname`" ${EMAIL_ADDRESS}
    fi
    COUNTER=${C}
    sleep 30
done
