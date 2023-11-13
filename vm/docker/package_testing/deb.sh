#!/bin/bash

os_list="ubuntu:20.04 debian:10 ubuntu:18.04 debian:11 ubuntu:22.04"
log="output.log"

for os in ${os_list}; do
  echo ${os}
  packages_list=`psql -h ${PGHOST} -U strapi prdata -Atc "SELECT distinct(name) FROM edb_repo.distributables WHERE operating_system_id = (SELECT id from edb_repo.operating_systems WHERE lower(name) || ':' || version = '${os}' ORDER BY id DESC LIMIT 100)"`
  for pkg in ${packages_list}; do
  echo ${pkg}
  echo "ATTEMPT - ${pkg} on ${os}" >> ${log}
  docker run -it --rm -v ./:/downloads_test -e TOKEN_URL=${TOKEN_URL} ${os} /downloads_test/deb_entrypoint.sh ${pkg}
  if [[ ${?} -eq 0 ]]; then
    echo "SUCCESS - ${pkg} on ${os}" >> ${log}
  else
    echo "FAILURE - ${pkg} on ${os}" >> ${log}
  fi
  done
done
