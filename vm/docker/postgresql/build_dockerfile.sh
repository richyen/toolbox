#!/bin/bash

if [[ "x${1}" == "x" ]]
then
  echo "Usage: ${0} <postgres_major_version> [<do_build>]"
  exit 1
fi

CENTOSVER=7
PGMAJOR=${1}
RPM_URL="https://download.postgresql.org/pub/repos/yum/reporpms/EL-${CENTOSVER}-x86_64/pgdg-redhat-repo-latest.noarch.rpm"


# For some reason, sometimes this is needed, but sometimes not (maybe depending on the mirror, the paths might be different)
# if [[ ${PGMAJOR/./} -lt 93 ]]
# then
#   sed -e "s/postgresql-\${PGMAJOR}/postgresql/" \
#       -e "s!PGDATA=/var/lib/pgsql/\${PGMAJOR}/data!PGDATA=/var/lib/pgsql/data!" \
#       -e "s!PGLOG=/var/lib/pgsql/\${PGMAJOR}/pgstartup.log!PGLOG=/var/lib/pgsql/pgstartup.log!" -i Dockerfile
# fi

if [[ ${CENTOSVER} -gt 6 ]]; then
  sed -e "s/^FROM centos:.*/FROM centos:${CENTOSVER}/" \
      -e "s/^#RUN su/RUN su/" \
      -e "s/^RUN service/#RUN service/" \
      -e "s/^CMD.*/CMD tail -F \/var\/log\/yum.log/" Dockerfile.template > Dockerfile
  if [[ ${CENTOSVER} -eq 8 ]]; then
    sed -i "" -e "s/yum /dnf /" \
           -e "s/y install yum-plugin-ovl/qy module disable postgresql/" Dockerfile
  fi
else
  cp Dockerfile.template Dockerfile
fi

if [[ "${2}" == "do_build" ]]
then
  # Assume this is the latest version
  docker build --build-arg PGMAJOR=${PGMAJOR} --build-arg RPM_URL=${RPM_URL} -t centos${CENTOSVER}/postgres:latest .

  # Give the image an actual version tag
  VN=`docker run -it --rm centos${CENTOSVER}/postgres:latest psql --version | awk '{ print \$3 }'| tr -d '\r'`
  docker tag centos${CENTOSVER}/postgres:latest centos${CENTOSVER}/postgres:${VN}

  if [[ "${3}x" != "x" ]]
  then
    # Update registry too
    docker tag centos${CENTOSVER}/postgres:${VN} ${3}/centos${CENTOSVER}/postgres:${VN}
    docker push ${3}/centos${CENTOSVER}/postgres:${VN}
  fi

  rm -f Dockerfile
fi
