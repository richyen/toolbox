#!/bin/bash

os_list="rockylinux:8 rockylinux:9 almalinux:8 almalinux:9"
log="output.log"

for os in ${os_list}; do
  echo ${os}
  packages_list=`psql -h ${PGHOST} -U strapi prdata -Atc "SELECT distinct(name) FROM edb_repo.distributables WHERE operating_system_id = (SELECT id from edb_repo.operating_systems WHERE version in ('8','9') and command_line ilike '%yum%' or command_line ilike '%dnf%' ORDER BY id DESC LIMIT 1)"`
  for pkg in ${packages_list}; do
  echo ${pkg}
  echo "ATTEMPT - ${pkg} on ${os}" >> ${log}
  docker run -it --rm -v ./:/downloads_test -e TOKEN_URL=${TOKEN_URL} ${os} /downloads_test/rpm_entrypoint.sh ${pkg}
  if [[ ${?} -eq 0 ]]; then
    echo "SUCCESS - ${pkg} on ${os}" >> ${log}
  else
    echo "FAILURE - ${pkg} on ${os}" >> ${log}
  fi
  done
done
