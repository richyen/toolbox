#!/bin/bash

if [[ "x${1}" == "x" ]]
then
  echo "Usage: ${0} <postgres_major_version> [<do_build>]"
  exit 1
fi

ELVER=9
PGMAJOR=${1}
RPM_URL="https://download.postgresql.org/pub/repos/yum/reporpms/EL-${ELVER}-x86_64/pgdg-redhat-repo-latest.noarch.rpm"


# For some reason, sometimes this is needed, but sometimes not (maybe depending on the mirror, the paths might be different)
# if [[ ${PGMAJOR/./} -lt 93 ]]
# then
#   sed -e "s/postgresql-\${PGMAJOR}/postgresql/" \
#       -e "s!PGDATA=/var/lib/pgsql/\${PGMAJOR}/data!PGDATA=/var/lib/pgsql/data!" \
#       -e "s!PGLOG=/var/lib/pgsql/\${PGMAJOR}/pgstartup.log!PGLOG=/var/lib/pgsql/pgstartup.log!" -i Dockerfile
# fi

sed -e "s/^FROM rockylinux:.*/FROM rockylinux:${ELVER}/" \
    -e "s/^#RUN su/RUN su/" \
    -e "s/^RUN service/#RUN service/" \
    -e "s/^CMD.*/CMD tail -F \/var\/log\/yum.log/" Dockerfile.template > Dockerfile
sed -e "s/y install yum-plugin-ovl/qy module disable postgresql/" Dockerfile

if [[ "${2}" == "do_build" ]]
then
  # Assume this is the latest version
  docker build --build-arg PGMAJOR=${PGMAJOR} --build-arg RPM_URL=${RPM_URL} -t rockylinux${ELVER}/postgres:latest .

  # Give the image an actual version tag
  VN=`docker run -it --rm rockylinux${ELVER}/postgres:latest psql --version | awk '{ print \$3 }'| tr -d '\r'`
  docker tag rockylinux${ELVER}/postgres:latest rockylinux${ELVER}/postgres:${VN}

  if [[ "${3}x" != "x" ]]
  then
    # Update registry too
    docker tag rockylinux${ELVER}/postgres:${VN} ${3}/rockylinux${ELVER}/postgres:${VN}
    docker push ${3}/rockylinux${ELVER}/postgres:${VN}
  fi

  rm -f Dockerfile
fi
