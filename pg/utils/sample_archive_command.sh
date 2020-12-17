#!/bin/bash

# Set archive_command = '/path/to/this_script.sh %p %f /path/to/archivedir'

p=${1}
f=${2}
dir=${3}
logfile=/tmp/archiver_log.txt
echo "starting archiver at $( date )" >> ${logfile}

if [[ -f ${dir}/${f} ]]; then
  echo "file ${f} already exists at ${dir}" >> ${lofile}
  exit 1
else
  echo "file ${f} not yet created, so proceeding" >> ${logfile}
  if [[ -f ${p} ]]; then
    echo "Found ${f} in pg_wal so proceeding" >> {logfile}
    cp ${p} ${dir}/${f} 2>&1 >> ${logfile}
    rv=${?}
    if [[ ${rv} -ne 0 ]]; then
      echo "could not copy file ${f} to ${dir}: ${rv}" >> ${logfile}
      exit 1
    fi
  else
    echo "Could not find file ${f} in pg_wal.  Here is the full directory listing:" >> ${logfile}
    ls -al ${PGDATA}/pg_wal >> ${logfile}
    exit 1
  fi
fi
echo "successfully copied ${f} to ${dir} at $( date )" >> ${logfile}
exit 0
