#!/bin/bash

if [[ "x${1}" == "x" ]]
then
  echo "Usage: ${0} <postgres_major_version> <do_build>"
fi

PGMAJOR=${1}
PGVERNUM=`echo ${PGMAJOR} | sed "s/\.//g"`
# RPM_URL=`curl -s https://yum.postgresql.org/repopackages.php | grep ${PGMAJOR} | grep https | grep "CentOS 6" | grep x86_64 | sed "s/.*https/https/" | sed "s/rpm.*/rpm/"`
RPM_URL="https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"

mkdir -p ${PGMAJOR}
cp Dockerfile.template ${PGMAJOR}/Dockerfile

sed -i "s!^ENV PGMAJOR.*!ENV PGMAJOR=${PGMAJOR}!" ${PGMAJOR}/Dockerfile
sed -i "s!^ENV PGVERNUM.*!ENV PGVERNUM=${PGVERNUM}!" ${PGMAJOR}/Dockerfile
sed -i "s!^ENV RPM_URL.*!ENV RPM_URL=${RPM_URL}!" ${PGMAJOR}/Dockerfile

# For some reason, sometimes this is needed, but sometimes not (maybe depending on the mirror, the paths might be different)
# if [[ ${PGVERNUM} -lt 93 ]]
# then
#   sed -i "s/postgresql-\${PGMAJOR}/postgresql/" ${PGMAJOR}/Dockerfile
#   sed -i "s!PGDATA=/var/lib/pgsql/\${PGMAJOR}/data!PGDATA=/var/lib/pgsql/data!" ${PGMAJOR}/Dockerfile
#   sed -i "s!PGLOG=/var/lib/pgsql/\${PGMAJOR}/pgstartup.log!PGLOG=/var/lib/pgsql/pgstartup.log!" ${PGMAJOR}/Dockerfile
# fi

cd ${PGMAJOR}

if [[ "${2}" == "do_build" ]]
then
#  docker build --build-arg PGMAJOR=${PGMAJOR} --build-arg PGVERNUM=${PGVERNUM} --build-arg RPM_URL=${RPM_URL} -t postgres-${PGMAJOR}:latest .
  docker build -t postgres-${PGMAJOR}:latest .
fi
