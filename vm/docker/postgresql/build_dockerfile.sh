#!/bin/bash

if [[ "x${1}" == "x" ]]
then
  echo "Usage: ${0} <postgres_major_version> [<do_build>]"
  exit 1
fi

CENTOSVER=7
PGMAJOR=${1}
RPM_URL="https://download.postgresql.org/pub/repos/yum/reporpms/EL-${CENTOSVER}-x86_64/pgdg-redhat-repo-latest.noarch.rpm"

cp Dockerfile.template Dockerfile

# For some reason, sometimes this is needed, but sometimes not (maybe depending on the mirror, the paths might be different)
# if [[ ${PGMAJOR/./} -lt 93 ]]
# then
#   sed -i -e "s/postgresql-\${PGMAJOR}/postgresql/" \
#          -e "s!PGDATA=/var/lib/pgsql/\${PGMAJOR}/data!PGDATA=/var/lib/pgsql/data!" \
#          -e "s!PGLOG=/var/lib/pgsql/\${PGMAJOR}/pgstartup.log!PGLOG=/var/lib/pgsql/pgstartup.log!" Dockerfile
# fi

if [[ ${CENTOSVER} -eq 7 ]]
then
  sed -i -e "s/^FROM.*/FROM gisjedi\/gosu-centos/" \
         -e "s/^#RUN gosu/RUN gosu/" \
         -e "s/^CMD.*/CMD tail -F \/var\/log\/yum.log/" Dockerfile
fi

if [[ "${2}" == "do_build" ]]
then
  docker build --build-arg PGMAJOR=${PGMAJOR} --build-arg RPM_URL=${RPM_URL} -t postgres-${PGMAJOR}:latest .
  rm -f Dockerfile
fi
